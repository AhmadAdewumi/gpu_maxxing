
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <ostream>
__global__ void vector_operations(float *arr1, float *arr2, float *result,
                                  int numOfElements, int operation) {
  /*
   blockIdx.x * blockDim.x calculates the starting global ID for the block.
   threadIdx.x adds the thread's position inside that block.
   */
  int tid = blockIdx.x * blockDim.x + threadIdx.x;

  if (tid < numOfElements) {
    if (operation == 1) {
      result[tid] = arr1[tid] * arr2[tid];
    } else if (operation == 2) {
      result[tid] = arr2[tid] != 0 ? arr1[tid] / arr2[tid] : 0.0f;
    } else if (operation == 3) { // abs difd
      result[tid] = fabsf(arr1[tid] - arr2[tid]);
    } else if (operation == 4) {
      result[tid] = fmaxf(arr1[tid], arr2[tid]);
    } else if (operation == 5) {
      result[tid] = fminf(arr1[tid], arr2[tid]);
    } else if (operation == 6) {
      result[tid] = arr2[tid] != 0 ? fmodf(arr1[tid], arr2[tid]) : 0.0f;
    }
  }
}

int main() {
  const int numOfElements = 1000;
  const int arrSize = numOfElements * sizeof(float);

  float *h_arr1 = (float *)malloc(arrSize);
  float *h_arr2 = (float *)malloc(arrSize);
  float *h_result = (float *)malloc(arrSize);

  for (int i = 0; i < numOfElements; ++i) {
    h_arr1[i] = (i + 1) * 10.0f;
    h_arr2[i] = (i + 1) * 2.0f;
  }

  float *d_arr1, *d_arr2, *d_result;
  cudaMalloc((void **)&d_arr1, arrSize);
  cudaMalloc((void **)&d_arr2, arrSize);
  cudaMalloc((void **)&d_result, arrSize);

  cudaMemcpy(d_arr1, h_arr1, arrSize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_arr2, h_arr2, arrSize, cudaMemcpyHostToDevice);

  int block_size = 512;
  int gridSize = (numOfElements + block_size - 1) / block_size;

  // float number = 2.0f;

  for (int operation = 1; operation <= 6; ++operation) {
    vector_operations<<<gridSize, block_size>>>(d_arr1, d_arr2, d_result,
                                                numOfElements, operation);

    cudaMemcpy(h_result, d_result, arrSize, cudaMemcpyDeviceToHost);

    if (operation == 1)
      std::cout << "\nMultiplication: ";
    if (operation == 2)
      std::cout << "\nDivision: ";
    if (operation == 3)
      std::cout << "\nAbsolute difference: ";
    if (operation == 4)
      std::cout << "\nMaximum: ";
    if (operation == 5)
      std::cout << "\nMinimum: ";
    if (operation == 6)
      std::cout << "\nModulus: ";

    for (int i{0}; i < numOfElements; ++i) {
      std::cout << h_result[i] << " ";
    }
    std::cout << " ]" << std::endl;
  }

  // cudaMemcpy(h_arr, d_arr, arrSize, cudaMemcpyDeviceToHost);

  cudaFree(d_arr1);
  cudaFree(d_arr2);
  cudaFree(d_result);

  // std::cout << "The results are: [ ";
  // for (int i{0}; i < numOfElements; ++i) {
  //   std::cout << h_arr[i] << " ";
  // }
  // std::cout << " ]" << std::endl;

  free(h_arr1);
  free(h_arr2);
  free(h_result);

  return 0;
}
