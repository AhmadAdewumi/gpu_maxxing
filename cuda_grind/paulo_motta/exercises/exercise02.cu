
#include <cstdlib>
#include <iostream>
#include <ostream>
__global__ void scalar_vector_multiplication(float number, float *arr,
                                             int numOfElements) {
  /*
   blockIdx.x * blockDim.x calculates the starting global ID for the block.
   threadIdx.x adds the thread's position inside that block.
   */
  int tid = blockIdx.x * blockDim.x + threadIdx.x;

  if (tid < numOfElements) {
    arr[tid] *= number;
  }
}

int main() {
  const int numOfElements = 1000;
  const int arrSize = numOfElements * sizeof(float);

  float *h_arr = (float *)malloc(arrSize);
  for (int i = 0; i < numOfElements; ++i) {
    h_arr[i] = i + 0.2f;
  }

  float *d_arr;
  cudaMalloc((void **)&d_arr, arrSize);

  cudaMemcpy(d_arr, h_arr, arrSize, cudaMemcpyHostToDevice);

  int block_size = 512;
  int gridSize = (numOfElements + block_size - 1) / block_size;

  float number = 2.0f;
  scalar_vector_multiplication<<<gridSize, block_size>>>(number, d_arr,
                                                         numOfElements);

  cudaMemcpy(h_arr, d_arr, arrSize, cudaMemcpyDeviceToHost);

  cudaFree(d_arr);

  std::cout << "The results are: [ ";
  for (int i{0}; i < numOfElements; ++i) {
    std::cout << h_arr[i] << " ";
  }
  std::cout << " ]" << std::endl;

  free(h_arr);
}
