
// #include <atomic>
#define NUM_BINS 256
#define COARSE_FACTOR 4
#define BLOCK_DIM 256
#include <cuda/atomic>

/*
 * we make each thread do more work, which reduces the number of thread uses and
 * does reduce the number of blocks kept/processed, we can have 75 percent fewer
 * blocks with a coarse factor of 4 used compared to the former privatixation
 * implementations, this is the contiguous partitioning approach where each
 * thread is assigned adjacent elements.
 *
 * but this is not ideal access for a warp, cos we want each thread in a warp to
 * access neigboring memory addresses, but here, the thread requests are spread
 * out rather than accessing contiguous elments.
 *
 * say we have coarse factor of 2, t0 -> img[0], t1->img[2], t2->img[4]. what if
 * it is 4, then that is more bad, it accesses it in a stride of 4, and thus
 * separates them by 4 bytes
 */
__global__ void histogram_kernel_contiguous(unsigned char *image,
                                            unsigned int *bins,
                                            unsigned int width,
                                            unsigned int height) {
  __shared__ unsigned int bins_s[NUM_BINS];
  for (unsigned int b = 0; b < NUM_BINS; b += blockDim.x) {
    bins_s[b] = 0;
  }
  __syncthreads();

  // calc the block's starting position, where the input segment starts
  unsigned int segment = COARSE_FACTOR * blockIdx.x * blockDim.x;
  for (unsigned int c = 0; c < COARSE_FACTOR; ++c) {
    // get the index
    unsigned int i = segment + COARSE_FACTOR * threadIdx.x + c;
    if (i < width * height) {
      unsigned char b = image[i];
      cuda::atomic_ref<unsigned int, cuda::thread_scope_block> bins_s_ref(
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
