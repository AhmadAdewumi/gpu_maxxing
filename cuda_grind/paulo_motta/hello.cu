#include <cstddef>
#include <cuda_runtime.h>
#include <iostream>

__global__ void add(const float *a, const float *b, float *c, int numElements) {
  int i = threadIdx.x + blockDim.x * blockIdx.x;
  if (i < numElements) {
    c[i] = a[i] + b[i];
  }
}

int main() {
  int numOfElements = 50000;
  std::size_t size = numOfElements * sizeof(float);
  std::cout << "Vector addition file created successfully!" << std::endl;
  std::cout << "The size is: " << size << " bytes" << std::endl;
  return 0;
}
