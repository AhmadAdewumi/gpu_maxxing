
// #include <cuda_fp16.h>
#include <atomic>
#define N 32
#define SEG_SIZE 8
#define WARP_SIZE 32
#define NUM_WARPS (BLOCK_DIM / WARP_SIZE)
#define BLOCK_DIM 256
#define COARSE_FACTOR 4
#include <cuda/atomic>

/*
 * so, instead of making each thread perform iits own prefix sum, which may lead
 * to O(N^2) work efficiency which is much worse than the sequential approach,
 * so in kogge stone, each thread  calculatesits own partial sum, at every
 * iteration, we.. don't know how to put it , we get back to this later
 */

__global__ void kogge_stone_inclusive(float *input, float *output) {
  __shared__ float buffer_s[SEG_SIZE];
  unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  // load into shared mem
  if (i < N) {
    buffer_s[threadIdx.x] = input[i];
  } else {
    buffer_s[threadIdx.x] = 0.0f;
  }

  // execute the concurrent reduction trees
  for (unsigned int stride = 1; stride < blockDim.x; stride *= 2) {
    /*
     * ensures that all threads have finished writing the values they calculated
     *to buffer_s in the previous iteration before other threads read them in
     *the current iteration */
    __syncthreads();

    float temp;
    if (threadIdx.x >= stride) {
      temp = buffer_s[threadIdx.x] + buffer_s[threadIdx.x - stride];
    }

    /*
     * second sync to avoid race condition and  ensures atomic read and write
     *
     * ensures that all threads have
     finished reading their input values from buffer_s before other threads
     overwrite them
     */
    __syncthreads();

    if (threadIdx.x >= stride) {
      buffer_s[threadIdx.x] = temp;
    }
  }

  if (i < N) {
    output[i] = buffer_s[threadIdx.x];
  }
}

/*
 * in the above implementation, there is synchronization overhead twice, and the
 * reason for the second sy, is because forward values need the old values to
 * calculate their partial sum, meanwhile, the values we read beforehand and
 * already calc thier sum may wanna writeto those locations that still contains
 * the old values,so the sync ensures we read all the values needed for
 * calculation frst beforemoving on to writing the sums. so this approach
 * introduces the DOUBLE BUFFERING optimization, where we have one buffer for
 * reading and another for writing and we can swap them in each iter, uing the
 * values in buffer2 by copying to buffer1 and so on.. So, we can eliminate the
 * second barrier
 */

__global__ void kogge_stone_double_buffering(float *input, float *output) {
  unsigned int i = blockDim.x * blockIdx.x + threadIdx.x;

  __shared__ float buffer1_s[SEG_SIZE];
  __shared__ float buffer2_s[SEG_SIZE];

  float *inBuffer_s = buffer1_s;
  float *outBuffer_s = buffer2_s;

  // load the values from global memory
  inBuffer_s[threadIdx.x] = (i < N) ? input[i] : 0.0f;

  // the thing is as the prefic sum progresses there are some positions where
  // the final output is calculated already and no need for modififcation, so
  // two options, either write the sum or preserve the existing value
  for (unsigned int stride = 1; stride < blockDim.x; stride *= 2) {
    if (threadIdx.x >= stride) {
      outBuffer_s[threadIdx.x] =
          inBuffer_s[threadIdx.x] + inBuffer_s[threadIdx.x - stride];
    } else {
      outBuffer_s[threadIdx.x] = inBuffer_s[threadIdx.x];
    }

    // swap the buffers
    float *temp = inBuffer_s;
    inBuffer_s = outBuffer_s;
    outBuffer_s = temp;
  }
  if (i < N) {
    // inBuffer_s contains the latest scan value
    output[i] = inBuffer_s[threadIdx.x];
  }
}

/*
 * performance of the loop above is dominated by the shared memory accesses and
 * barrier synchronizations. and a way to mitigate the overhead of both is by
 * using warp level primitves
 *
 * the whole method is:
 * - scan scan add decomposition, each warp has their own local prefix sums also
 * - extract each segment totals (last element in the segment) and scan them
 * also
 * - add the scanned sum in the prev step to all elements in each correspoding
 * segment
 * First stage: Each warp scans its own values
 * Second stage: Scan the warp sums
 * Third stage: Add the preceding warp totals.
 *
 * Takeaway:
 * Do as much communication as possible within a warp using shuffle
 * instructions. Use shared memory and block-wide synchronization only when
 * communication must cross warp boundaries
 */
__device__ unsigned int lane_idx() { return threadIdx.x % WARP_SIZE; }
__device__ unsigned int warp_idx() { return threadIdx.x / WARP_SIZE; }

// performs warp level scan
__device__ inline float warpScan(float val) {
  // doubling iterations
  for (unsigned int stride = 1; stride < WARP_SIZE; stride *= 2) {
    // obtain a copy of the value to the left stride pos away to the left
    float leftValStridePosAway = __shfl_up_sync(0xffffffff, val, stride);
    // only valid lanes with a valid left value add theshuff;ed value
    if (lane_idx() > stride) {
      val += leftValStridePosAway;
    }
  }
  return val;
}

// block level scan, take local warp scan result and add them to all the
// sgements
__device__ inline float blockScan(float val) {
  // warp lvl scan
  val = warpScan(val);

  // collect the warp sums
  __shared__ float warp_sums_s[NUM_WARPS];
  // collect the sum from each warp
  if (lane_idx() == WARP_SIZE - 1) {
    warp_sums_s[warp_idx()] = val;
  }
  // all warps must finish writing sum before we read from it
  __syncthreads();

  // scan warps sums.. only warp 0 participates
  if (warp_idx() == 0) {
    float warp_sum =
        (threadIdx.x < NUM_WARPS) ? warp_sums_s[threadIdx.x] : 0.0f;
    warp_sum = warpScan(warp_sum);
    if (threadIdx.x < NUM_WARPS) {
      warp_sums_s[threadIdx.x] = warp_sum;
    }
  }
  __syncthreads();

  // add the sum of pervious warps scanned sum
  if (warp_idx() > 0) {
    val += warp_sums_s[warp_idx() - 1];
  }

  return val;
}

__global__ void scan_kernel(float *input, float *output) {
  unsigned int i = blockDim.x * blockIdx.x + threadIdx.x;
  float val = (i < N) ? input[i] : 0.0f;
  val = blockScan(val);
  if (i < N) {
    output[i] = val;
  }
}

/*
 * Applying thread coarsening, giving more inputs to each thread
 */
__device__ inline float warp_scan(float val) {
  for (unsigned int stride = 1; stride < WARP_SIZE; stride *= 2) {
    float left_val = __shfl_up_sync(0xffffffff, val, stride);
    if (lane_idx() >= stride) {
      val += left_val;
    }
  }
  return val;
}

__device__ inline float block_scan(float val) {
  // warp level scan, stores result in the last part
  // each lane contains its own local prefix sum, as we know
  val = warp_scan(val);

  // collect the sums into shared mem
  __shared__ float warp_sums_s[NUM_WARPS];
  if (lane_idx() == WARP_SIZE - 1) {
    warp_sums_s[warp_idx()] = val;
  }
  __syncthreads();

  // using first warp to scan the warp sums
  if (warp_idx() == 0) {
    float warp_sum =
        (threadIdx.x < NUM_WARPS) ? warp_sums_s[threadIdx.x] : 0.0f;

    warp_sum = warp_scan(warp_sum);
    if (threadIdx.x < NUM_WARPS) {
      warp_sums_s[threadIdx.x] = warp_sum;
    }
  }
  __syncthreads();

  // we add previous warps scanned sum
  if (warp_idx() > 0) {
    val += warp_sums_s[warp_idx() - 1];
  }
  return val;
}

__global__ void thread_coarsening_scan_kernel(float *input, float *output) {
  unsigned int blockSegment = blockIdx.x * COARSE_FACTOR * blockDim.x;

  // load data into shared memory
  __shared__ float buffer_s[COARSE_FACTOR * BLOCK_DIM];
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    unsigned int localIdx = c * BLOCK_DIM + threadIdx.x;
    unsigned int globalIdx = blockSegment + localIdx;

    buffer_s[localIdx] = (globalIdx < N) ? input[globalIdx] : 0.0f;
  }
  __syncthreads();

  // thread process their own 4 consecutive elements
  unsigned int threadSegment = threadIdx.x * COARSE_FACTOR;
  for (unsigned int c = 1; c < COARSE_FACTOR; ++c) {
    buffer_s[threadSegment + c] += buffer_s[threadSegment + c - 1];
  }

  // / block wide scan of thread sums
  float thread_sum = buffer_s[threadSegment + COARSE_FACTOR - 1];
  thread_sum = block_scan(thread_sum);

  // collect thread partial sums
  __shared__ float thread_sums_s[BLOCK_DIM];
  thread_sums_s[threadIdx.x] = thread_sum;
  __syncthreads();

  // add prev thread partial sums
  if (threadIdx.x > 0) {
    float prevPartialSum = thread_sums_s[threadIdx.x - 1];
    for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
      buffer_s[threadSegment + c] = prevPartialSum;
    }
  }
  __syncthreads();

  // write output
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    unsigned int localIdx = c * BLOCK_DIM * threadIdx.x;
    unsigned int globalIdx = blockSegment + localIdx;

    if (globalIdx < N) {
      output[globalIdx] = buffer_s[localIdx];
    }
  }
}

// ----------------register tiling -----------
__global__ void register_tiling_scan_kernel(float *input, float *output) {
  unsigned int blockSegment = blockIdx.x * COARSE_FACTOR * blockDim.x;

  __shared__ float buffer_s[COARSE_FACTOR * BLOCK_DIM];
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    unsigned int localIdx = c * BLOCK_DIM + threadIdx.x;
    unsigned int globalIdx = blockSegment + localIdx;

    buffer_s[localIdx] = (globalIdx < N) ? input[globalIdx] : 0.0f;
  }
  __syncthreads();

  // copy values into registers and scan them
  unsigned int threadSegment = threadIdx.x * COARSE_FACTOR;
  float buffer_r[COARSE_FACTOR];
  // load first element
  buffer_r[0] = buffer_s[threadSegment];

#pragma unroll
  for (unsigned int c = 1; c < COARSE_FACTOR; ++c) {
    // e.g buffer_r[1] = buffer_s[1] + buffer_r[0];
    // intermediate results now live in buffer_r, rather than being repeatedly
    // written back into buffer_s
    buffer_r[c] = buffer_s[threadSegment + c] + buffer_r[c - 1];
  }

  // calc each thread's total
  float threadSum = buffer_r[COARSE_FACTOR - 1];
  threadSum = block_scan(threadSum);

  // coollect thread totals
  __shared__ float threadSums_s[BLOCK_DIM];
  threadSums_s[threadIdx.x] = threadSum;
  __syncthreads();

  // add prev thread partial sums, calculate the offsets
  float prevPartialSum =
      (threadIdx.x > 0) ? threadSums_s[threadIdx.x - 1] : 0.0f;

#pragma unroll
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    buffer_s[threadSegment + c] = buffer_r[c] + prevPartialSum;
  }
  __syncthreads();

  // write output
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    output[blockSegment + c * BLOCK_DIM * threadIdx.x] =
        buffer_s[c * BLOCK_DIM * threadIdx.x];
  }
}

//--- Consolidating block segments for a global scan ---
/*the scan scan add approach use much global memroy, 16 bytes comapred to 8
 bytes(read)
 *
 * REDUCE -SCAN - SCAN
 * - reduce each block
 * scan the block sums
 * for each block, add each scanned block prefix sum to first element of
 * corresponding block, and then scan the block locally.
 *
 * the reduce-scan-scan decomposi­
 tion also requires an inter-block scan step. Again, a simple approach for
 performing the inter-block scan is to use a three-kernel approach: the first
 kernel to reduce the block segments, the second kernel to scan the block sums
 using a single thread block, and the third kernel to perform the local scans

 Both strategies
 have two scan operations. They key difference is that one has an add operation
 while the other has a reduce operation. The advantage of the reduce operation
 over the add operation is that it writes to fewer outputs. On the other hand,
 the advantage of the add operation over the reduce operation is that it does
 not need to perform multiple steps with intermediate synchronization to execute
 a reduction tree
 */
// single lookback function
/*
 * val -> is the sum contributed by this block
 * blockId -> this block's index
 * partialSums = global array holding each block's cummulative sum
 * flags => global array indicating whethter each block's summulative sum is
 * ready
 *
 * -- the two memory order operations ---
 Release: publish the data first, then announce that it is ready.
 Acquire: observe that it is ready, then read the published data.creates a long
 list of dependencies

 the thing with this approach is that it
 */
__device__ inline float inter_block_scan(float val, int blockId,
                                         float *partialSums,
                                         unsigned int *flags) {
  // leader thread will calculate the previous block's sum, but every thread in
  // the block eventually needs that value and can acesss it from shared mem
  __shared__ float prevBlockPartialSum_s;

  // only last(leader) thread enters
  // The last thread in the block which has the
  // block’s sum, acts on behalf of the whole block as the leader thread
  if (threadIdx.x == blockIdx.x - 1) {
    // is this the firsr block?, is yes its prev block sum will be 0, no
    // predecessor for any other block, we must wait for the previous block.
    if (blockId > 0) {
      // using atomic re because one block is reading a flag while another block
      // is updating it An ordinary unsynchronized read could race with the
      // other block's write. The atomic reference provides an atomic way to
      // inspect the flag.
      cuda::atomic_ref<unsigned int, cuda::thread_scope_device>
          prevBlockFlag_ref(flags[blockId - 1]);
      // this loop repeatedly checks whether the previous block has changed its
      // flag from zero and is called polling or spinning
      while (prevBlockFlag_ref.fetch_add(0, cuda::memory_order_acquire) == 0) {
      }
      prevBlockPartialSum_s = partialSums[blockId - 1];
    } else {
      prevBlockPartialSum_s = 0.0f;
    }

    // calc and publish this block's cumulative sum
    //  curr block's own sum + preceeding one sum(contains its ancestor's own
    //  also)
    partialSums[blockId] = prevBlockPartialSum_s + val;

    // we tell the next block that the sum is ready
    cuda::atomic_ref<unsigned int, cuda::thread_scope_device> myBlockFlag_ref(
        flags[blockId]);
    myBlockFlag_ref.fetch_add(1, cuda::memory_order_release);
  }
  __syncthreads();
  return prevBlockPartialSum_s;
}

//-- multiple(there is fixed and decoupled) lookback method --

// scan kernel that includes an inter-block scan to consolidate block segments
/*
 * the algo is:
 * Each thread scans its own elements
 * The block scans its thread totals
 * Blocks consolidate their totals
 */
__global__ void scan_kernel(float *input, float *output,
                            unsigned int *blockCounter, float *partialSums,
                            unsigned int *flags) {
  // we dynamically assign the block id, not using the cuda conventional
  // blockIdx.x, because of the req of unidirectional synchronization: the
  // requirement of unidirectional synchronization:
  // Earlier block IDs must correspond to blocks that have already started
  // executing before later block IDs
  __shared__ unsigned int block_id_s;

  if (threadIdx.x == 0) {
    cuda::atomic_ref<unsigned int, cuda::thread_scope_device> block_counter_ref(
        *blockCounter);
    block_counter_ref.fetch_add(1, cuda::memory_order_relaxed);
  }
  __syncthreads();

  unsigned int block_id = block_id_s;
  unsigned int blockSegment = COARSE_FACTOR * blockDim.x;

  // Load data to shared memory
  __shared__ float buffer_s[COARSE_FACTOR * BLOCK_DIM];
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    buffer_s[c * BLOCK_DIM + threadIdx.x] =
        input[blockSegment + c * BLOCK_DIM + threadIdx.x];
  }
  __syncthreads();

  // Scan thread subsegment
  unsigned int threadSegment = threadIdx.x * COARSE_FACTOR;
  float buffer_r[COARSE_FACTOR];
  buffer_r[0] = buffer_s[threadSegment];
#pragma unroll
  for (unsigned int c = 1; c < COARSE_FACTOR; ++c) {
    buffer_r[c] = buffer_s[threadSegment + c] + buffer_r[c - 1];
  }
  // Block-wide scan of thread sums
  float threadSum = buffer_r[COARSE_FACTOR - 1];
  threadSum = blockScan(threadSum);
  // Collect thread partial sums
  __shared__ float threadSums[BLOCK_DIM];
  threadSums[threadIdx.x] = threadSum;
  __syncthreads();
  // Add previous thread's partial sums
  float prevPartialSum = (threadIdx.x > 0) ? threadSums[threadIdx.x - 1] : 0.0f;
#pragma unroll
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    buffer_r[c] += prevPartialSum;
  }
  // Scan block partial sums
  float prevBlockPartialSum = inter_block_scan(buffer_r[COARSE_FACTOR - 1],
                                               block_id, partialSums, flags);
// Add previous block's partial sum
#pragma unroll
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    buffer_s[threadSegment + c] = buffer_r[c] + prevBlockPartialSum;
  }
  __syncthreads();
  // Write output
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    output[blockSegment + c * BLOCK_DIM + threadIdx.x] =
        buffer_s[c * BLOCK_DIM + threadIdx.x];
  }
}

// BRENT KUNG ALGORITHM
/*
 * FIRST PART->reduction phase
 * SECOND PART -> reverse the tree phase
 *
 * Step 1: Combine pairs: Each odd position receives the sum of itself and the
 * position immediately before it
 * Step 2: Combine groups of four like sum of pos 1 and 3, 5 and 7 and store in
 * 3 first then for the second example-> 7

 the reduction tree reduces the computation step to log(n) base 2, in the first
 phase, we only get the total sumand some intermediate result

 2nd phase
 *The reduction phase has already calculated useful sums. The reverse phase
 combines those sums with the values at positions that still need them
 */
__global__ void brent_kung_scan(float *input, float *output) {
  extern __shared__ float data[];

  unsigned int tid = threadIdx.x;

  // load nput into shared memory
  data[tid] = input[tid];
  __syncthreads();

  // phase 1: reduction tree (upsweep)
  for (unsigned int stride = 1; stride < N; stride *= 2) {
    // determines which positions are updated at each stage
    unsigned int idx = (tid + 1) * 2 * stride - 1;
    if (idx < N) {
      data[idx] += data[idx - stride];
    }
    __syncthreads();
  }

  // phase 2 : reverse tree (downsweep)
  for (unsigned int stride = N / 4; stride > 0; stride /= 2) {

    // this determines which positions receive the previously calculated
    // prefixes
    unsigned int idx = (tid + 1) * 2 * stride + stride - 1;

    if (idx < N) {
      data[idx] += data[idx - stride];
    }

    __syncthreads();
  }

  // Write inclusive scan results.
  output[tid] = data[tid];
}
