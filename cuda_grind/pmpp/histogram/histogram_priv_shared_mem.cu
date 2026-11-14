
#include <__clang_cuda_builtin_vars.h>
#include <atomic>
#include <cuda/atomic>
#define NUM_BINS 256
#define BLOCK_DIM 256

// instead of keeping the private bins in global memory, we put them in shared
// memory and thus reduce latency

__global__ void histogram_priv_shared_mem(unsigned char *image,
                                          unsigned int *bins,
                                          unsigned int width,
                                          unsigned int height) {
  // one array of NUM_BINS  element per block
  __shared__ unsigned int bins_s[NUM_BINS];
  // inut them all to 0
  for (unsigned int b = threadIdx.x; b < NUM_BINS; b += blockDim.x) {
    bins_s[b] = 0;
  }
  __syncthreads();

  unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < width * height) {
    unsigned char b = image[i];
    cuda::atomic_ref<unsigned int, cuda::thread_scope_block> bins_s_ref(
        bins_s[b]);
    bins_s_ref.fetch_add(1, cuda::memory_order_relaxed);
  }
  __syncthreads();

  for (unsigned int b = blockIdx.x; b < NUM_BINS; b += blockDim.x) {
    if (bins_s[b] > 0) {
      cuda::atomic_ref<unsigned int, cuda::thread_scope_device> bins_ref(
          bins[b]);
      bins_ref.fetch_add(1, cuda::memory_order_relaxed);
    }
  }
}
