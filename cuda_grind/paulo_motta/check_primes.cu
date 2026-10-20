

#include <chrono>
#include <ios>
#include <iostream>
#include <ratio>
__global__ void checkPrimeKernel(long long start, long long end) {
  // identifies the current gpu thread
  int tid = threadIdx.x + blockIdx.x * blockDim.x;

  //-- assuming the start will be odd number, so increment by 2 always gives the
  // next odd number
  long long num = start + (tid * 2); // to skip even numbers

  // these branches has no real impact oin performance coz they just sett value
  // and return
  // -- using branches makss the code run sequentially

  if (num > end) {
    return;
  }

  bool isPrime = true;
  if (num <= 1) {
    isPrime = false;
    return;
  }

  if (num == 2) {
    isPrime = true;
    return;
  }

  if (num % 2 == 0) {
    isPrime = false;
    return;
  }

  for (long long i{3}; i * i <= num; i += 2) {
    if (num % i == 0) {
      isPrime = false;
      return;
    }
  }
}

bool checkPrimeCPU(long long num) {
  if (num <= 1)
    return false;
  if (num == 2)
    return true;
  if (num % 2 == 0)
    return false;

  for (long long i{3}; i * i < num; i+=2) {
    if (num % i == 0) {
      return false;
    }
  }
  return false;
}

int main() {
  long long start = 100'101L;
  long long end = 109'100L;

  int threadsPerBlock = 256;
  int totalOddNumbers = (end - start) / 2 + 1;

  // this approach rounds the number up, coz 4500/256 only gives 17 with a
  // reminder withthis, we can get 18 which  gives extra 108 threads condition,
  // if(num > end) takes care of that
  int blocksPerGrid = (totalOddNumbers + threadsPerBlock - 1) / threadsPerBlock;

  cudaEvent_t startEvent, stopEvent;
  cudaEventCreate(&startEvent);
  cudaEventCreate(&stopEvent);

  cudaEventRecord(startEvent, 0);

  checkPrimeKernel<<<blocksPerGrid, threadsPerBlock>>>(start, end);

  cudaEventRecord(stopEvent, 0);
  cudaEventSynchronize(stopEvent);

  float gpuDuration = 0;
  cudaEventElapsedTime(&gpuDuration, startEvent, stopEvent);
  std::cout << "Time taken on GPU: " << gpuDuration << " ms" << "\n";
  cudaEventDestroy(startEvent);
  cudaEventDestroy(stopEvent);

  //-- for the cpu part
  auto startTime = std::chrono::high_resolution_clock::now();

  for (long long num = start; num < end; num += 2) {
    checkPrimeCPU(num);
  }

  auto endTime = std::chrono::high_resolution_clock::now();

  std::chrono::duration<double, std::milli> cpuDuration = endTime - startTime;

  std::cout << "Time taken on CPU: " << std::fixed << cpuDuration.count()
            << " ms" << "\n";
  std::cout << "Speed up: " << cpuDuration.count() / gpuDuration << "\n";

  return 0;
}

/*
 * OUTPUT
 * Time taken on GPU: 1.0874 ms
 Time taken on CPU: 2.617053 ms
 Speed up: 2.406705
 Exit status: 0
 */
