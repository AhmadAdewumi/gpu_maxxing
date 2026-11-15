
#include <atomic>
#define NUM_BINS 256
#define COARSE_FACTOR 4
#define BLOCK_DIM 256
#include <cuda/atomic>

/*
 * even though in the former privatization approach which is block wide, further
 * reduces the contention compared to the basic kernel, but still, within a
 * block contention still exists, so what this thread privatization approach
 * does is that we let each thread accumulate some histogram update before
 * touching tthat of the shared block's histogram.
 * instead of a thread performing , say , 4 atomic updates, it can count locally
 * and perform a single atomic update. This technique is called aggregation:
 * combine several updates to the same location into one larger update.
 *  But, each thread foesn't get its own bin, coz if so, say we have 256 bins
 * for 256 threads, that is 65,536 counters x 4 bytes which is about 256KiB,
 * which is too expensive, considering it might be larger, and we may try to
 * load them in registers or shared memory.
 *
 * Alternative introduced, is that, each thread privatizes only the most
 * recently accessed bin.
 *
 * the two important vars
 * unsigned int b; --> The pixel value currently being accumulated
 *unsigned int bin_r; --> How many consecutive occurrences of that value have
 *been seen
 */

__global__ void histogram_thread_privatization_kernel(unsigned char *image,
                                                      unsigned int *bins,
                                                      unsigned int width,
                                                      unsigned int height) {
  __shared__ unsigned int bins_s[NUM_BINS];

  for (unsigned int b = 0; b < NUM_BINS; b += blockDim.x) {
    bins_s[b] = 0;
  }
  __syncthreads();

  unsigned int segment = COARSE_FACTOR * blockIdx.x * blockDim.x;

  // check whethere the first pixel exists
  if (segment + threadIdx.x < width * height) {
    // each thread loads its first pixel
    unsigned int b = image[segment + threadIdx.x];
    unsigned int bin_r = 1; // 1 becausewe have already seen first occurence of
                            // b, the onw we just loaded
    for (unsigned int c = 1; c < COARSE_FACTOR; ++c) {
      // calc next pixel index
      unsigned int i = segment + c * blockDim.x + threadIdx.x;
      if (i < width * height) {
        unsigned char b_next = image[i];

        // if equal , increment, else perform the atomic operation
        if (b_next == b) {
          ++bin_r;
        } else {
          cuda::atomic_ref<unsigned int, cuda::thread_scope_block> bins_s_ref(
              bins_s[b]);
          bins_s_ref.fetch_add(1, cuda::memory_order_relaxed);

          // reset local state
          b = b_next;
          bin_r = 1; // starting at 1, coz we have already seen one occurence of
                     // b_next
        }
      }
    }

    // in case the else branch never execute, say for that input, we only had
    // 5,5,5,5.
    //  the loop finishes, but we still have to flush
    cuda::atomic_ref<unsigned int, cuda::thread_scope_block> bins_s_ref(
        bins_s[b]);
    bins_s_ref.fetch_add(1, cuda::memory_order_relaxed);
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

/*
 * note:: this combines the interleaved thread coarsening approach with thread
 * level privatization aggregation and this approaches largely benefits say
 * images with the same consecutive pixesls, say image if a very blue sky, as
 * most parts may contain consecutive pixels. it is very beneficial in such
 *scenario
 *
 * -- doesn't guarantee a faster kernel execution
 *
 * so there are 3 levels of accumulation here:
 * thread level accumulation
 * blockwide histogram accumulation
 * public global wide bin accumulation
 */
