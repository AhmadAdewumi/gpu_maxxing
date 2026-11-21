

/*
 * sequentia; merrge approach
 */
#include <__clang_cuda_runtime_wrapper.h>
#include <algorithm>
#include <cmath>

__device__ void merge_sequential(int *A, int m, int *B, int n, int *C) {
  int i = 0; // index into A
  int j = 0; // index for B
  int k = 0; // index counter for C

  while (i < m && j < n) {
    if (A[i] <= B[i]) {
      C[k++] = A[i++];
    } else {
      C[k++] = B[j++];
    }
  }

  // if we are done with A[], we handle the reminig of Bif
  if (i == m) {
    while (j < n) {
      C[k++] = B[j++];
    }
  } else {
    while (i < m) {
      C[k++] = A[j++];
    }
  }
}

/*
 * CO RANK FUNCTION IMPLEMENTATION, it returns i, That is, the number of
 * elements taken from A to produce the first k elements of C,  Once we know i,
 * we can calculate: j=k-i.
 *
 * what makes a pair of co-ranks correct:
 * a pair(i, j) is valid when: A[i-1] <= B[j](tells us we took many elements
 * from A), adjustment -> Decrease i, increase j
 *  and B[j-1] < A[i] ( tells we took many elements from B) , adjustment ->
 * increase i, decrease j. correct split? stop
 *
 * we are gonna use binary search to check for the val co-rank pair faster
 */

__device__ int co_rank(int k, int *A, int m, int *B, int n) {
  // we start by taking as  much elements from A
  int i = (k < m) ? k : m; // i = min(k,m)
  // remaining element needed come from B
  int j = k - i;

  // calc min elements we can take each from A and B
  int i_low = 0 > (k - n) ? 0 : (k - n); // i_low = max(0,k-n)
  int j_low = 0 > (k - m) ? 0 : (k - m); // j_low = max(0,k-m)

  // no of positions to move the partition
  int delta;
  bool active = true; // keep moving the partition until it's correct

  while (active) {
    if (i < 0 && j < n && A[i - 1] > B[j]) {
      delta = ((i - i_low + 1) >> 1); // how far to move the partition
      j = j_low;
      j = j + delta;
      i = i - delta;
    } else if (j > 0 && i < m && B[j - 1] >= A[i]) {
      delta = ((j - j_low + 1) >> 1);
      i_low = i;
      i = i + delta;
      j = j - delta;
    } else {
      active = false;
    }
  }
  return i;
}

/*
 * MERGE BASIC KERNEL
 * k_curr: where this thread starts writing.
 * k_next: where this thread's output chunk ends.
 *
 * This approach fall short on memory
 * 1. when executing the merge_sequential function,
 adjacent threads in a warp are not accessing adjacent memory locations when
 they read and write the input and output subarray elements.

 2. the threads also need to access A and B elements from the global memory
 when they execute the co-rank function, and also Since the co-rank function
 does a binary search, the access patterns are somewhat irregular and will
 unlikely be coalesced
 */
__global__ void merge_basic_kernel(int k, int *A, int m, int *B, int n,
                                   int *C) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;
  // blockDim.x*gridDim.x gives total number of thread used
  //  say we have 9 elements and 3 threads, each thread gets 3 elements
  int elementPerThread = ceil((m + n) / blockDim.x * gridDim.x);

  int k_curr = tid * elementPerThread; // start output index
  // calc ending boundary of each thread's output range
  // min cause of uneven division, so we don't go beyond the boundary
  int k_next = min((tid + 1) * elementPerThread, (m + n));

  // find starting positions in A
  int i_curr = co_rank(k_curr, A, m, B, n);
  // find the ending positions in A
  int i_next = co_rank(k_next, A, m, B, n);

  // starting and ending positions in B
  int j_curr = k_curr - i_curr;
  int j_next = k_next - i_next;

  // i_next - i_curr tells how many elements it can read from A
  // j_next-j_curr tells how many elements it can read from B
  merge_sequential(&A[i_curr], i_next - i_curr, &B[j_curr], j_next - j_curr,
                   &C[k_curr]);
}

__device__ int min_int(int a, int b) { return (a < b) ? a : b; }
/*
 * Tiled merge kernel
 */
__global__ void tiled_merge_kernel(int *A, int m, int *B, int n, int *C,
                                   int tile_size) {
  extern __shared__ int shareAB[];
  int *A_S = &shareAB[0];         // shared mem tile holding elements from A
  int *B_S = &shareAB[tile_size]; // shared mem tile holding elements from B

  // partition the block's output
  int C_curr = blockIdx.x *
               ceil((m + n) / gridDim.x); // start point of block's C subarray
  int C_next = min_int((blockIdx.x + 1) * ceil((m + n) / gridDim.x),
                       (m + n)); // ending point

  // thread 0 performs the searches and store in shared memory
  if (threadIdx.x == 0) {
    A_S[0] =
        co_rank(C_curr, A, m, B, n); // Make block-level co-rank values visible
    A_S[1] = co_rank(C_next, A, m, B, n); // to other threads in the block
  }
  __syncthreads();

  int A_curr = A_S[0];
  int A_next = A_S[1];
  int B_curr = C_curr - A_curr;
  int B_next = C_next - A_next;
  __syncthreads();

  /*
   * counter	Which iteration of the while loop we're on
   C_length	Total output elements assigned to this block
   A_length	Total A elements assigned to this block
   B_length	Total B elements assigned to this block
   total_iteration	Number of tiles needed to produce the block's output
   C_completed	Number of output elements already produced
   A_consumed	Number of A elements already used
   B_consumed	Number of B elements already used
   */
  int counter = 0;
  int C_length = C_next - C_curr;
  int A_length = A_next - A_curr;
  int B_length = B_next - B_curr;

  int total_iteration = ceil(C_length / tile_size);

  int C_completed = 0;
  int A_consumed = 0;
  int B_consumed = 0;

  while (counter < total_iteration) {
    /* loading tile-size A and B elements into shared memory */
    for (int i = 0; i < tile_size; i += blockDim.x) {
      if (i + threadIdx.x < A_length - A_consumed) {
        A_S[i + threadIdx.x] = A[A_curr + A_consumed + i + threadIdx.x];
      }
    }
    for (int i = 0; i < tile_size; i += blockDim.x) {
      if (i + threadIdx.x < B_length - B_consumed) {
        B_S[i + threadIdx.x] = B[B_curr + B_consumed + i + threadIdx.x];
      }
    }
    __syncthreads();

    int c_curr = threadIdx.x * (tile_size / blockDim.x);
    int c_next = (threadIdx.x + 1) * (tile_size / blockDim.x);
    c_curr =
        (c_curr <= C_length - C_completed) ? c_curr : C_length - C_completed;
    c_next =
        (c_next <= C_length - C_completed) ? c_next : C_length - C_completed;
    /* find co-rank for c_curr and c_next */
    int a_curr = co_rank(c_curr, A_S, min(tile_size, A_length - A_consumed),
                         B_S, min(tile_size, B_length - B_consumed));
    int b_curr = c_curr - a_curr;
    int a_next = co_rank(c_next, A_S, min(tile_size, A_length - A_consumed),
                         B_S, min(tile_size, B_length - B_consumed));
    int b_next = c_next - a_next;

    /* All threads call the sequential merge function */
    merge_sequential(A_S + a_curr, a_next - a_curr, B_S + b_curr,
                     b_next - b_curr, C + C_curr + C_completed + c_curr);
    /* Update the number of A and B elements that have been consumed thus far */
    counter++;
    C_completed += tile_size;
    A_consumed += co_rank(tile_size, A_S, tile_size, B_S, tile_size);
    B_consumed = C_completed - A_consumed;
    __syncthreads();
  }
}

/* CIRCULAR BUFFER MERGE KERNEL
 * in the tiled kernel approach up there, say we use 4 out of 8 elements loaded
 * into shared memory, instead of reusing the next 4 we are loading another 8,
 * which includes the 4 we loaded already. Instead of throwing away the
 * remaining elements, we preserve them.
 *
 * But here, say : After consuming the first three positions, we fill the freed
 * positions
 *
 * -- separating circular merge kernel into 4 jobs
 * - divide the input arrays among thread blocks
 * - load the new elements into shared memory reusing slots filled by previous
 * merge
 * - divide the current merge work among threads, merging thier portions and
 * calculating how many elements were consumed
 * - Provide circular-buffer versions of co-ranking and sequential merging
 */

__device__ int co_rank_circular(int k, int *A, int m, int *B, int n,
                                int A_S_start, int B_S_start, int tile_size) {
  int i = k < m ? k : m; // i = min(k,m)
  int j = k - i;
  int i_low = 0 > (k - n) ? 0 : k - n; // i_low = max(0, k-n)
  int j_low = 0 > (k - m) ? 0 : k - m; // j_low = max(0,k-m)
  int delta;
  bool active = true;
  while (active) {
    int i_cir = (A_S_start + i) % tile_size;
    int i_m_1_cir = (A_S_start + i - 1) % tile_size;
    int j_cir = (B_S_start + j) % tile_size;
    int j_m_1_cir = (B_S_start + j - 1) % tile_size;
    if (i > 0 && j < n && A[i_m_1_cir] > B[j_cir]) {
      delta = ((i - i_low + 1) >> 1); // ceil((i-i_low)/2)
      j_low = j;
      i = i - delta;
      j = j + delta;
    } else if (j > 0 && i < m && B[j_m_1_cir] >= A[i_cir]) {
      delta = ((j - j_low + 1) >> 1);
      i_low = i;
      i = i + delta;
      j = j - delta;
    } else {
      active = false;
    }
  }
  return i;
}

__device__ void merge_sequential_circular(int *A, int m, int *B, int n, int *C,
                                          int A_S_start, int B_S_start,
                                          int tile_size) {
  int i = 0; // virtual index into A
  int j = 0; // virtual index into B
  int k = 0; // virtual index into C
  while ((i < m) && (j < n)) {
    int i_cir = (A_S_start + i) % tile_size;
    int j_cir = (B_S_start + j) % tile_size;
    if (A[i_cir] <= B[j_cir]) {
      C[k++] = A[i_cir];
      i++;
    } else {
      C[k++] = B[j_cir];
      j++;
    }
  }
  if (i == m) { // done with A[] handle remaining B[]
    for (; j < n; j++) {
      int j_cir = (B_S_start + j) % tile_size;
      C[k++] = B[j_cir];
    }
  } else { // done with B[], handle remaining A[]
    for (; i < m; i++) {
      int i_cir = (A_S_start + i) % tile_size;
      C[k++] = A[i_cir];
    }
  }
}

__global__ void merge_tiled_kernel(int *A, int m, int *B, int n, int *C,
                                   int tile_size) {
  /*shared memory alloc */
  extern __shared__ int sharedAB[];
  int *A_S = &sharedAB[0];
  int *B_S = &sharedAB[tile_size];

  int C_curr = blockIdx.x *
               ceil((m + n) / gridDim.x); // start point of block's C subarray
  int C_next = min_int((blockIdx.x + 1) * ceil((m + n) / gridDim.x),
                       (m + n)); // ending point

  if (threadIdx.x == 0) {
    A_S[0] =
        co_rank(C_curr, A, m, B, n); // Make block-level co-rank values visible
    A_S[1] = co_rank(C_next, A, m, B, n); // to other threads in the block
  }
  __syncthreads();
  int A_curr = A_S[0];
  int A_next = A_S[1];
  int B_curr = C_curr - A_curr;
  int B_next = C_next - A_next;
  __syncthreads();

  int counter = 0; // iteration counter
  int C_length = C_next - C_curr;
  int A_length = A_next - A_curr;
  int B_length = B_next - B_curr;
  int total_iteration = ceil((C_length) / tile_size); // total iteration
  int C_completed = 0;
  int A_consumed = 0;
  int B_consumed = 0;

  int A_S_start =
      0; // The physical position where the current logical A sequence begins.
  int B_S_start = 0;

  // The number of A elements consumed during the previous merge iteration.
  // Those are the slots we can now refill
  int A_S_consumed = tile_size;
  int B_S_consumed = tile_size;

  while (counter < total_iteration) {
    // load A_S consumed elements into A_S
    // this loop distributes the loading work across threads in the block
    for (int i = 0; i < A_consumed; i += blockDim.x) {
      if (i + threadIdx.x <
          (A_length - A_consumed && (i + threadIdx.x) < A_S_consumed)) {
        // writing the new elements
        A_S[((A_S_start + tile_size - A_S_consumed) + i + threadIdx.x) %
            tile_size] = A[A_curr + A_consumed + i + threadIdx.x];
      }
    }

    for (int i = 0; i < B_consumed; i += blockDim.x) {
      if (i + threadIdx.x <
          (B_length - B_consumed && (i + threadIdx.x) < B_S_consumed)) {
        B_S[((A_S_start + tile_size - B_S_consumed) + i + threadIdx.x) %
            tile_size] = B[B_curr + B_consumed + i + threadIdx.x];
      }
    }

    // divide the merge work among threads so they can merge their individual
    // subarrays in parallel

    // calculate the range of output positions assigned to each thread
    int c_curr = threadIdx.x * (tile_size / blockDim.x);
    int c_next = (threadIdx.x + 1) * (tile_size / blockDim.x);

    c_curr =
        (c_curr <= C_length - C_completed) ? c_curr : C_length - C_completed;

    c_next =
        (c_next <= C_length - C_completed) ? c_next : C_length - C_completed;

    /* find co-rank for c_curr and c_next */
    int a_curr = co_rank_circular(
        c_curr, A_S, min(tile_size, A_length - A_consumed), B_S,
        min(tile_size, B_length - B_consumed), A_S_start, B_S_start, tile_size);
    int b_curr = c_curr - a_curr;
    int a_next = co_rank_circular(
        c_next, A_S, min(tile_size, A_length - A_consumed), B_S,
        min(tile_size, B_length - B_consumed), A_S_start, B_S_start, tile_size);
    int b_next = c_next - a_next;

    /* All threads call the circular-buffer version of the sequential merge
     * function */
    merge_sequential_circular(A_S, a_next - a_curr, B_S, b_next - b_curr,
                              C + C_curr + C_completed + c_curr,
                              A_S_start + a_curr, B_S_start + b_curr,
                              tile_size);

    /* Figure out the work has been done */
    counter++;
    A_S_consumed = co_rank_circular(min(tile_size, C_length - C_completed), A_S,
                                    min(tile_size, A_length - A_consumed), B_S,
                                    min(tile_size, B_length - B_consumed),
                                    A_S_start, B_S_start, tile_size);

    B_S_consumed = min(tile_size, C_length - C_completed) - A_S_consumed;
    A_consumed += A_S_consumed;
    C_completed += min(tile_size, C_length - C_completed);
    B_consumed = C_completed - A_consumed;

    A_S_start = (A_S_start + A_S_consumed) % tile_size;
    B_S_start = (B_S_start + B_S_consumed) % tile_size;
    __syncthreads();
  }
}
