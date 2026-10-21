
#include <cstddef>
#include <cstdlib>
#include <iostream>
#include <iterator>
#include <vector>
__global__ void primeKernel(long long start, long long end, long long *arrA,
                            bool *arrB) {
  int tid = threadIdx.x + blockIdx.x * blockDim.x;

  // long long num = start + (tid * 2);
  long long num = start + tid;

  long long totalNUmberToCheck = end - start;

  if (tid >= totalNUmberToCheck)
    return;

  arrA[tid] = num;

  bool isPrime = true;
  if (num <= 1) {
    isPrime = false;
    arrB[tid] = isPrime;
    return;
  }

  if (num == 2) {
    isPrime = true;
    arrB[tid] = isPrime;
    return;
  }

  if (num % 2 == 0) {
    isPrime = false;
    arrB[tid] = isPrime;
    return;
  }

  for (int i{3}; i * i <= num; i += 2) {
    if (num % i == 0) {
      isPrime = false;
      arrB[tid] = isPrime;
      return;
    }
  }

  arrB[tid] = isPrime;
}

int main() {
  long long start = 10'000;
  long long end = 10'100;

  long long totalNUmberToCheck = end - start;

  std::size_t sizeOfNumbers = totalNUmberToCheck * sizeof(long long);
  std::size_t sizeOfBool = totalNUmberToCheck * sizeof(bool);

  int threadsPerBlock = 512;
  // int blocksPergrid = ((start+end) + threadsPerBlock)/512;
  int gridSize = (totalNUmberToCheck + threadsPerBlock -1) / 512;

  long long *h_arrA = new long long[totalNUmberToCheck];
  bool *h_isPrimeArrB = new bool[totalNUmberToCheck];

  // populate host arr
  // for (std::size_t i = 0; i < totalNUmberToCheck; ++i) {
  //   h_arrA[i] = start+i;
  // }

  // device array
  long long *d_ArrA;
  bool *d_ArrB;
  cudaMalloc(&d_ArrA, sizeOfNumbers);
  cudaMalloc(&d_ArrB, sizeOfBool);

  // cudaMemcpy(d_ArrA, h_arrA, sizeOfNumbers, cudaMemcpyHostToDevice);
  // cudaMemcpy(d_ArrB, h_isPrimeArrB, sizeOfBool, cudaMemcpyHostToDevice);

  primeKernel<<<gridSize, threadsPerBlock>>>(start, end, d_ArrA, d_ArrB);

  cudaError_t error = cudaGetLastError();

  // copy result back to host
  cudaMemcpy(h_arrA, d_ArrA, sizeOfNumbers, cudaMemcpyDeviceToHost);
  cudaMemcpy(h_isPrimeArrB, d_ArrB, sizeOfBool, cudaMemcpyDeviceToHost);

  cudaFree(d_ArrA);
  cudaFree(d_ArrB);

  // printing the prime numbers
  std::cout << "Prime Numbers are: [ ";
  for (std::size_t i = 0; i < totalNUmberToCheck; ++i) {
    if (h_isPrimeArrB[i]) {
      std::cout << h_arrA[i] << " ";
    }
  }
  std::cout << " ]" << std::endl;

  delete[] h_arrA;
  delete[] h_isPrimeArrB;
}
