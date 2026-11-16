

__global__ void simple_sum_reduction_kernel(float *input, float *output) {
  unsigned int i = 2 * threadIdx.x;

  for (unsigned int stride = 1; stride <= blockDim.x; stride *= 2) {
    if (threadIdx.x % 2 == 0) {
      input[i] += input[i + stride];
    }
    __syncthreads();
  }

  // store atoutput 0
  if (threadIdx.x == 0) {
    *output = input[0]; // dereference it
  }
}
