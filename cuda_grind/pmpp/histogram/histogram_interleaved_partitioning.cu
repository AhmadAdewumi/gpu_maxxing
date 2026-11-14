#include <atomic>
#define NUM_BINS 256
#define COARSE_FACTOR 4
#define BLOCK_DIM 256
#include <cuda/atomic>

/*
 * -- memory coalescing -> how efficiently does the gpu load data from the
 * global memory,
 *  this is for interleaved partitioning here, they process using a stride of
 * the grid(blockDim.x), all threads jointly process the first blockDim.x of the
 * first segment then, in the next iter, all threads add blockDim.x to thier
 * indices and jointly process the net section of blockDim.x elements, e,g
 * Thread 0 processes pixels 0 and 8. Thread 1 processes pixels 1 and 9. Thread
 * 2 processes pixels 2 and 10. And so on. So, in the first iter, they all
 * process like 0 to 7, then move to the next iter and all process 8 to 15 and
 * so on..., so:
 * iteration 0: the warp accesses a consecutive section
 * Iteration 1: the warp accesses another consecutive section
 * Every iteration preserves coalesced access.
 * This is much more better than the contiguous approach on GPU, if it was on
 * CPU, the contiguous approach might perform much better as a result of effect
 * of cache lines.
 * 
 * Thread coarsening has its own cost also:
 * Each thread executes more iterations
 * There may be less parallelism available to the GPU
 * If too few blocks are available, the GPU may not have enough work to keep all its SMs busy
 * More per-thread state can increase register usage
 */
__global__ void histogram_interleaved_kernel(unsigned char *image,
                                             unsigned int *bins,
                                             unsigned int width,
                                             unsigned int height) {
  __shared__ unsigned int bins_s[NUM_BINS];
  for (unsigned int b = 0; b < NUM_BINS; b += blockDim.x) {
    bins_s[b] = 0;
  }
  __syncthreads();

  unsigned int segment = COARSE_FACTOR * blockIdx.x * blockDim.x;
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {

    // this is the distinct dfference, the index calculation
    unsigned int i = segment + c * blockDim.x + threadIdx.x;

    if (i < width * height) {
      unsigned char b = image[i];
      cuda::atomic<unsigned int, cuda::thread_scope_block> bins_s_ref(
          bins_s[b]);
      bins_s_ref.fetch_add(1, cuda::memory_order_relaxed);
    }
  }
  __syncthreads();

  for (unsigned int b = 0; b < NUM_BINS; b += blockDim.x) {
    if (bins_s[b] > 0) {
      cuda::atomic_ref<unsigned int, cuda::thread_scope_device> bins_ref(
          bins[b]);
      bins_ref.fetch_add(1, cuda::memory_order_relaxed);
    }
  }
}
