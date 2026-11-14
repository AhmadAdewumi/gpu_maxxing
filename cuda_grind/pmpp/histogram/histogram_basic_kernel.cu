#include <atomic>
#include <cuda/atomic>

__global__ void histogram_kernel(unsigned char *image, unsigned int *bins,
                                 unsigned int width, unsigned int height) {
  unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < width * height) {
    unsigned char b = image[i];
    cuda::atomic_ref<unsigned int, cuda::thread_scope_block> bins_ref(bins[b]);
    bins_ref.fetch_add(1,
                       cuda::memory_order_relaxed); // fetch_add() returns the
                                                    // old value of the object
  }
}
