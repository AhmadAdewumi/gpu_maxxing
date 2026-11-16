
#define BLOCK_DIM 8
/*
 * say, we perform the first reduction on an array loaded from global memory,
 * when performing the intermdeiate reductions, we are stilll loading from the
 * global memory, but we can just read from the global memory into the shared
 * memory once, perfrom first reduction simulataneously with the loading and
 * then we can perform all the intermediate reduction in the shared memory, and
 * then write the output to the glball memory. This is better than the former as
 * the shared memory even has a lower latency as compared to the last level
 * cache, in case the former was even performing the reduction in L2 cache
 */

__global__ void shared_mem_reduction_kernel(float *input, float *output) {
  __shared__ float input_s[BLOCK_DIM];
  unsigned int t = threadIdx.x;

  // load and perfrom first reduction alongside it
  input_s[t] = input[t] + input[t + BLOCK_DIM];

  // we perform first reduction already, so first stride gone
  for (unsigned int stride = BLOCK_DIM / 2; stride >= 1; stride /= 2) {
    // sync before shared memory accsses, load-add operation
    // must complete for every iteration,a s the execution is thread
    // inindependent
    __syncthreads();
    if (threadIdx.x < stride) {
      input_s[t] = input_s[t] + input_s[t + stride];
    }
  }

  if (threadIdx.x == 0) {
    *output = input[0];
  }
}
