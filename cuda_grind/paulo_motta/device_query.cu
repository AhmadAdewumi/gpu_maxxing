#include <cuda_runtime.h>
#include <iostream>

int main() {
  cudaDeviceProp deviceProp;
  int device = 0;
  cudaGetDeviceProperties(&deviceProp, device);

  std::cout << "Device " << device << " : " << deviceProp.name << "\n";
  std::cout << "CUDA Capability Major/Minor version number: "
            << deviceProp.major << "." << deviceProp.minor << "\n";
  std::cout << "Total amoutn of shared memry per block: "
      << deviceProp.sharedMemPerBlock << " bytes " << "\n";
  std::cout << "Maximum number of threads per block: " << deviceProp.maxThreadsPerBlock << "\n";

  return 0;
}
