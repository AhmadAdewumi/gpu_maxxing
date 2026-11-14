
/*
 * Now, we use privatization to reduce contention caused by ouput interference,
 * instead of having a single histogram, we can distribute the work such that
 * each block has its own private histogram, and our pixel is splitted, such
 * that they are handled separately, after different private bins have been
 * updated, then we can merge them all togehther,this approach reduces
 * contention significantly.
 * so, max 1024 threads per block work on the same bin
 * The overhead is that we need to init the private copies of the histogram,
 * synchronize and commit the private copies back to public, it is done once per
 * thread block and the more thread block we use the greater the overhead
 */

#include <atomic>
#include <cstddef>
#include <cuda/atomic>
#define NUM_BINS 256
#define BLOCK_DIM 256
__global__ void histogram_privatization_kernel(unsigned char *image,
                                               unsigned int *bins,
                                               unsigned int *bins_pool,
                                               unsigned int width,
                                               unsigned int height) {
  // pool alloc
  unsigned int *bins_priv = &bins_pool[NUM_BINS * blockDim.x];
  // calc pixel attached to each thread
  unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < width * height) {
    unsigned char b = image[i];
    // we are performing block wide atomic addition for this, so the scope is
    // block
    cuda::atomic_ref<unsigned int, cuda::thread_scope_block> bins_priv_ref(
        bins_priv[b]);
    bins_priv_ref.fetch_add(1, cuda::memory_order_relaxed);
  }
  __syncthreads();

  // we merge all the private histograms
  // we are gonns do something like thread corsening here, each thread handling
  // more than one operation, say we have 20 bins and 8 blocks t0 handles bins
  // 0,8,16, t1 handles 1,9,17... The offset is blockDim.x
  for (unsigned int b = threadIdx.x; b < NUM_BINS; b += blockDim.x) {
    // we can neglect those whose values are 0 as they contribute nothing
    if (bins_priv[b] > 0) {
      cuda::atomic_ref<unsigned int, cuda::thread_scope_device> bins_ref(
          bins[b]);
      bins_ref.fetch_add(1, cuda::memory_order_relaxed);
    }
  }
}

int main() {
  unsigned int width = 1024;
  unsigned int height = 1024;
  unsigned int numPixels = width * height;
  // std::size_t
}
