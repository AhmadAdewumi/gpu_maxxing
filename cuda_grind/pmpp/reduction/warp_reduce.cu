
#include <cuda/atomic>
#define WARP_SIZE 32
#define BLOCK_DIM 256
#define COARSE_FACTOR 4

/*
 * SHared memory has its own overhead also:
 * Threads must read from it
 * Threads must write to it
 * Threads must synchronize using __syncthreads() between reduction stages
 * --
 * in the early stage, the block can contain multiple  warps, but as we move
 * downward, the warp reduces such that every thread involved only spans a warp,
 * so we no longer need to coordinate the earlier warps, we can just make the
 * threads in the single warp left coordinate and share info(exchanging values)
 * using warp level primitives.
 * the threads in the warp
 load the values from shared memory to their registers, and execute the
 remaining reduction tree iterations by shuffling values across their registers
 */

//---- warp reduction function ---
__device__ __inline__ float warp_reduce(float val) {
  float partial_sum = 0;
  for (unsigned int stride = WARP_SIZE / 2; stride > 0; stride /= 2) {
    partial_sum += __shfl_down_sync(0Xffffffff, partial_sum, stride);
  }

  return partial_sum;
}

__device__ unsigned int warpIdx() { return threadIdx.x / WARP_SIZE; }

__device__ unsigned int laneIdx() { return threadIdx.x % WARP_SIZE; }

__global__ void warp_level_sum_reduction_kernel(float *input, float *output) {
  __shared__ float input_s[BLOCK_DIM];
  unsigned int t = threadIdx.x;

  input_s[t] += input[t + BLOCK_DIM];

  for (unsigned int stride = blockDim.x / 2; stride >= WARP_SIZE; stride /= 2) {
    __syncthreads();
    if (threadIdx.x < stride) {
      input_s[t] += input_s[t + stride];
    }
  }

  __syncthreads();

  // only threads 0 to 31 are required to continue, so we can perform the warp
  // level reduction
  if (warpIdx() == 0) {
    // / load partial sum into register, each participating thread loads its
    // corresponding value from shared memory, so each lane has its value in
    // regiister
    float partial_sum = input_s[t];
    partial_sum = warp_reduce(partial_sum);
    if (threadIdx.x == 0) {
      *output = partial_sum;
    }
  }
}
/*
 * Global memory -> Initial input load
  ---> Shared memory -> Reduction while multiple warps remain
  ---> Registers + warp shuffle -> Final reduction inside one warp
 ---> Global memory->Final output
 */

// --------------------------
/*  Further reducing synchronization overhead with
two-stage warp-wide reduction , here, we use warp level reduction in the
earleier stages also, we were only performing warp shuffle, when there is only a
single warp remaining
* Stage one: each warp independently reduces its values
*Stage two: the first warp reduces the warp sums
*
* this keeps more warp active at first, but can still be faster, as reduction is
primarily latency bound
*/

__global__ void TwoStageWarpLevelSumReductionKernel(float *input,
                                                    float *output) {
  unsigned int t = threadIdx.x;
  float partial_sum = input[t] + input[t + BLOCK_DIM];

  // warp level reduction for all the thread inputs, and thier results is saved
  // in the fiirst lane of the warp, for 256 threads, we are gonna have 8 warps,
  // and 8 partial sums
  partial_sum = warp_reduce(partial_sum);

  /*
   * only lane 0(which contains the partial sums) of each warp write to shared
   * memory
   */
  __shared__ float partial_sums_s[BLOCK_DIM / WARP_SIZE];
  if (warpIdx() == 0) {
    partial_sums_s[warpIdx()] = partial_sum;
  }
  __syncthreads();

  //-- stage 2
  /*
   * only warp participates here, coz we have 8 partial sums and a warp contains
   * 32 lanes
   */
  if (warpIdx() == 0) {
    // check boudary, only 8 threads are allowed
    if (t < BLOCK_DIM / WARP_SIZE) {
      float partial_sum = partial_sums_s[t];
    }
    partial_sum = warp_reduce(partial_sum);
    if (threadIdx.x == 0) {
      *output = partial_sum;
    }
  }
}

//--- arbitrary block length reduction/
/*
 * all the previous impl focused on a block calc, what if we have millions of
 * elements, a block(1024 threads) won't be  enough to reduce that
 */

__global__ void multi_block_reduce_sum_kernel(float *input, float *output,
                                              unsigned int n) {
  // get the segement satrting positions, e.g 0, 256, 512....
  unsigned int segment = 2 * blockDim.x * blockIdx.x;
  unsigned int i = segment + threadIdx.x;

  float partial_sum = input[i] + input[i + BLOCK_DIM];
  partial_sum = warp_reduce(partial_sum);

  __shared__ float partial_sum_s[BLOCK_DIM / WARP_SIZE];
  if (warpIdx() == 0) {
    partial_sum_s[warpIdx()] = partial_sum;
  }
  __syncthreads();

  // omly the first warp participates, threads 0-31
  if (threadIdx.x < WARP_SIZE) {
    if (threadIdx.x < BLOCK_DIM / WARP_SIZE) {
      float partial_sum = partial_sum_s[threadIdx.x];
    }
    partial_sum = warp_reduce(partial_sum);
  }
  // atomic addition for all the block wide reduction sums, suppose all block
  // finish around the same time and they all wanna write to *ouput[0],that may
  // lead to race condition, so we perform atomic updates.
  // we use device scope atomic here, coz block is device wide, and block scoppe
  // only covers threads/.
  //
  // and also since blocks can be added in arbitrary order, the operation must
  // be both associative and comutative

  if (threadIdx.x == 0) {
    cuda::atomic_ref<float, cuda::thread_scope_device> output_ref(*output);
    output_ref.fetch_add(1, cuda::memory_order_relaxed);
  }
}

/*
 * in the coarsened approach, giving more thread more elements, we can reduce
 * the number of block reduction operation, also, at the earlier stage,
 * syncthreads() overhead is partly eliminated, say t0 handles like 8 elements,
 * no synchronization or shared memory is needed, not all but in the eal=rlier
 * stages.
 *
 * NB: coarsening trades parallelism for less overhead
 */
__global__ void CoarsenedSumReductionKernel(float *input, float *output) {
  __shared__ float partialSums_s[BLOCK_DIM / WARP_SIZE];

  unsigned int segment = COARSE_FACTOR * 2 * blockDim.x * blockIdx.x;

  unsigned int i = segment + threadIdx.x;

  // Stage 1:  Each thread independently sums its assigned elements
  float partialSum = input[i];

  for (unsigned int c = 1; c < COARSE_FACTOR * 2; ++c) {
    partialSum += input[i + c * BLOCK_DIM];
  }

  // each warp reduces its own thread-local sums
  partialSum = warp_reduce(partialSum);

  // One thread per warp stores that warp's result
  if (laneIdx() == 0) {
    partialSums_s[warpIdx()] = partialSum;
  }

  // Ensure all warps have written their results
  __syncthreads();

  // Stage 2: first warp reduces the warp-level results
  if (warpIdx() == 0) {
    float blockSum = 0.0f;

    if (threadIdx.x < BLOCK_DIM / WARP_SIZE) {
      blockSum = partialSums_s[threadIdx.x];
    }

    blockSum = warp_reduce(blockSum);

    // One block contributes one sum to the global result
    if (threadIdx.x == 0) {
      cuda::atomic_ref<float, cuda::thread_scope_device> output_ref(*output);

      output_ref.fetch_add(blockSum, cuda::memory_order_relaxed);
    }
  }
}
