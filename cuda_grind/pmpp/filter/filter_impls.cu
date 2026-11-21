
#include <cooperative_groups.h>
#include <cuda/atomic>

#define WARP_SIZE 32
#define BLOCK_DIM 256
#define NUM_WARPS (BLOCK_DIM / WARP_SIZE)

__device__ inline bool cond(unsigned int val) { return (val % 2) == 0; }

__global__ void filter_kernel(unsigned int *input, unsigned int *output,
                              unsigned int N, unsigned int *outputSize) {
  unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < N) {
    unsigned int val = input[i];
    if (cond(val)) {
      cuda::atomic_ref<unsigned int, cuda::thread_scope_device> outputSize_ref(
          *outputSize);
      unsigned int j = outputSize_ref.fetch_add(1, cuda::memory_order_relaxed);
      output[j] = val;
    }
  }
}

__device__ inline int lane_idx() { return threadIdx.x % WARP_SIZE; }
/*
 * __ffs() (Find First Set) intrinsic on the active mask finds
 the least significant bit that is set to 1 in the mask, We subtract one from
 the value returned by __ffs() because the intrinsic adds a one to the index it
 returns because the return value of zero is reserved for when none of the bits
 in the mask are set.

 * unstable filter kernel with coalesced atomic operations, instead of each
 * qualifying thread performing the atomic operation which may lead to
 * conteention thus serialization, we allow only one thread(leader) perform the
 * atomic operation.
 *
 * __active_mask() is an example of warp voting function
 */
__global__ void filter_kernel_coalesced_atomic_op(unsigned int *input,
                                                  unsigned int *output,
                                                  unsigned int N,
                                                  unsigned int *outputSize) {
  unsigned int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < N) {
    unsigned int val = input[i];
    if (cond(val)) {
      // we get the active threads
      // __activemask() retrieves the 32 bit mask representing the currently
      // active lanes in a warp e.g 00000000000000000000000001010101, bit set to
      // 1 represent active lanes.if the threads that are active in­
      // side the if-statement are threads 1, 2, 4, and 5, then __activemask()
      // will return 00000000000000000000000000110110
      unsigned int activeThreads = __activemask();
      unsigned int j;
      // we elect a leader, read from right, 1 indexed, we have to subtracr 1
      unsigned int leader = __ffs(activeThreads) - 1;
      if (lane_idx() == leader) {
        // we find how many threads are active
        unsigned int num_of_active_threads = __popc(activeThreads);
        // we make the leader perform the atomic operation
        cuda::atomic_ref<unsigned int, cuda::thread_scope_device> output_ref(
            *outputSize);
        j = output_ref.fetch_add(num_of_active_threads,
                                 cuda::memory_order_relaxed);
      }

      // we broadcast the result to other threads, coz only the leader performed
      // the operation
      j = __shfl_sync(activeThreads, j, leader);
      // finding the position of each active thread in the ouput
      //
      // creates a bitmask containing all lane pos before the current lane
      unsigned int previousThreads = (1 << lane_idx()) - 1;
      // we only want the previously active threads
      unsigned int previousActiveThreads = previousThreads & activeThreads;
      unsigned int offset = __popc(previousActiveThreads);

      // we store the result, each active thread writes its own element into its
      // assigned position
      output[j + offset] = val;
    }
  }
}

/*
 * UNSTABLE FILTER KERNEL WITH COALESCED ATOMIC ACCESS USING COOPERATIVE GROUPS
 *
 * this approach is much easier than the manual approach right up here
 */
namespace cg = cooperative_groups;
__global__ void filter_kernel_atomiic_coalesce_cg(unsigned int *input,
                                                  unsigned int *output,
                                                  unsigned int N,
                                                  unsigned int *outputSize) {
  unsigned int i = blockDim.x * blockIdx.x + threadIdx.x;
  if (i < N) {
    unsigned int val = input[i];
    if (cond(val)) {
      cg::coalesced_group active_threads = cg::coalesced_threads();
      unsigned int j;
      // assign leader thread
      if (active_threads.thread_rank() == 0) {
        // finds how many threads are active
        unsigned int num_of_active_threads = active_threads.size();
        cuda::atomic_ref<unsigned int, cuda::thread_scope_device> output_ref(
            *outputSize);
        j = output_ref.fetch_add(num_of_active_threads,
                                 cuda::memory_order_relaxed);
      }

      // broadcast result to other threads
      j = active_threads.shfl(j, 0);
      // find the position of each active thread in the output
      unsigned int offset = active_threads.thread_rank();
      // store the result
      output[j + offset] = val;
    }
  }
}

/*
 * PRIVATIZATION -> unstable filter kernel
 * -- give each block its own counter and output array
 */
__global__ void privatization_filter(unsigned int *input, unsigned int *output,
                                     unsigned int N, unsigned int *outputSize) {
  // declareation and init of the private output arr and  size
  __shared__ unsigned int output_s[BLOCK_DIM];
  __shared__ unsigned int outputeSize_s;

  // only ythread 0 init the counter
  if (threadIdx.x == 0) {
    outputeSize_s = 0;
  }
  __syncthreads();

  unsigned int i = blockDim.x * blockIdx.x + threadIdx.x;
  // we filter into the private output list
  if (i < N) {
    unsigned int val = input[i];
    if (cond(val)) {
      cuda::atomic_ref<unsigned int, cuda::thread_scope_device>
          outputSize_s_ref(outputeSize_s);
      unsigned int j =
          outputSize_s_ref.fetch_add(1, cuda::memory_order_relaxed);
      output_s[j] = val;
    }
  }
  __syncthreads();

  // only thread 0 increments the public counter and it increments it by the
  // total number of values this block collected
  // updating the public counter
  /*
   * faster because:
   * 32 atomic operations on block-local shared-memory counters
   *  Only 4 atomic operations on the global counter
   * Also, the final global writes are consecutive within each block, helping
   * memory coalescing
   */
  __shared__ unsigned int j;
  if (threadIdx.x == 0) {
    cuda::atomic_ref<unsigned int, cuda::thread_scope_device> outputSize_ref(
        *outputSize);
    /*
     * for examples --> This operation does two things atomically:
    1. Returns the old counter value: 10.
    2. Changes the counter to 14.
    */
    j = outputSize_ref.fetch_add(outputeSize_s, cuda::memory_order_relaxed);
  }
  __syncthreads();

  // write to public output
  if (threadIdx.x < outputeSize_s) {
    output[j + threadIdx.x] = output_s[threadIdx.x];
  }
}

// ---------------------- STABLE FILTERING ----------------------
/*
 * This section brings together two ideas:
 - Filtering: decide which input elements should survive.
 - Exclusive scan: calculate where each surviving element belongs in the output.
 filtering doesn't guarantee stability
 
 The key stuff: count the preceding elements that survive
 */

// / parts from exclusive parallel scan
__device__ inline unsigned int laneIdx() {
    return threadIdx.x % WARP_SIZE;
}

__device__ inline unsigned int warpIdx() {
    return threadIdx.x / WARP_SIZE;
}

// Warp-level inclusive scan
__device__ inline unsigned int warpScan(unsigned int val) {
    for (unsigned int stride = 1; stride < WARP_SIZE; stride *= 2) {
        unsigned int leftVal = __shfl_up_sync(0xffffffff, val, stride);
        if (laneIdx() >= stride) {
            val += leftVal;
        }
    }
    return val;
}

// Block-level inclusive scan
__device__ inline unsigned int blockScan(unsigned int val) {
    val = warpScan(val);
    __shared__ unsigned int warpSums_s[NUM_WARPS];
    if (laneIdx() == WARP_SIZE - 1) {
        warpSums_s[warpIdx()] = val;
    }
    __syncthreads();

    if (warpIdx() == 0) {
        unsigned int warpSum = (threadIdx.x < NUM_WARPS) ? warpSums_s[threadIdx.x] : 0;
        warpSum = warpScan(warpSum);
        if (threadIdx.x < NUM_WARPS) {
            warpSums_s[threadIdx.x] = warpSum;
        }
    }
    __syncthreads();

    if (warpIdx() > 0) {
        val += warpSums_s[warpIdx() - 1];
    }
    return val;
}

// Inter-block single look-back scan
__device__ inline unsigned int interBlockScan(unsigned int val, unsigned int bid,
    unsigned int* partialSums, unsigned int* flags) {
    __shared__ unsigned int prevBlockPartialSum_s;
    if (threadIdx.x == blockDim.x - 1) {
        if (bid > 0) {
            cuda::atomic_ref<unsigned int, cuda::thread_scope_device>
                prevBlockFlag_ref(flags[bid - 1]);
            while (prevBlockFlag_ref.fetch_add(0, cuda::memory_order_acquire) == 0) {}
            prevBlockPartialSum_s = partialSums[bid - 1];
        } else {
            prevBlockPartialSum_s = 0;
        }
        partialSums[bid] = prevBlockPartialSum_s + val;
        cuda::atomic_ref<unsigned int, cuda::thread_scope_device>
            myBlockFlag_ref(flags[bid]);
        myBlockFlag_ref.fetch_add(1, cuda::memory_order_release);
    }
    __syncthreads();
    return prevBlockPartialSum_s;
}

// Grid-wide exclusive scan combining blockScan + interBlockScan
__device__ inline unsigned int gridExclusiveScan(unsigned int val, unsigned int bid,
    unsigned int* partialSums, unsigned int* flags) {
    // Inclusive scan within the block
    unsigned int inclusiveBlockVal = blockScan(val);

    // Fetch sum of all preceding blocks (thread blockDim.x - 1 holds total block sum)
    unsigned int prevBlockSum = interBlockScan(inclusiveBlockVal, bid, partialSums, flags);

    // Convert grid-wide inclusive scan to exclusive scan by subtracting original val
    return (prevBlockSum + inclusiveBlockVal) - val;
}

__global__ void filter_kernel(unsigned int* input, unsigned int* output,
    unsigned int* blockCounter, unsigned int* partialSums, unsigned int* flags,
    unsigned int N, unsigned int* outputSize) {
    // Assign dynamic block ID to prevent scheduling deadlocks
    __shared__ unsigned int bid_s;
    if (threadIdx.x == 0) {
        cuda::atomic_ref<unsigned int, cuda::thread_scope_device>
            blockCounter_ref(*blockCounter);
        bid_s = blockCounter_ref.fetch_add(1, cuda::memory_order_relaxed);
    }
    __syncthreads();
    unsigned int bid = bid_s;

    unsigned int i = bid * blockDim.x + threadIdx.x;
    unsigned int val = (i < N) ? input[i] : 0;
    unsigned int keep = (i < N && cond(val)) ? 1 : 0;

    // All threads participate in the grid-wide exclusive scan
    unsigned int offset = gridExclusiveScan(keep, bid, partialSums, flags);

    if (keep) {
        output[offset] = val;
    }
    if (i == N - 1) {
        *outputSize = offset + keep;
    }
}
