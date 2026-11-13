#include <cerrno>
#include <cstddef>
#include <cuda_device_runtime_api.h>
#include <cuda_runtime_api.h>
#include <driver_types.h>
#include <iostream>
#include <ostream>
#include <vector>
#include <vector_types.h>

#define CUDA_CHECK(call)                                                       \
  do {                                                                         \
    cudaError_t err = call;                                                    \
    if (err != cudaSuccess) {                                                  \
      std::cerr << "CUDA Error: " << cudaGetErrorString(err) << std::endl;     \
      return 1;                                                                \
    }                                                                          \
  } while (0)

__global__ void convolution_3D_basic(const float *N, const float *F, float *P,
                                     int width, int height, int depth,
                                     int filterDim) {

  // identify output voxel for this thread
  int outCol = blockIdx.x * blockDim.x + threadIdx.x;
  int outRow = blockIdx.y * blockDim.y + threadIdx.y;
  int outDepth = blockIdx.z * blockDim.z + threadIdx.z;
  
  // ignoring thread outside the output volume
  if (outRow >= height || outCol >= width || outDepth >= depth) {
    return;
  }

  int radius = filterDim / 2;
  float sum = 0.0f;

  for (int fRow = 0; fRow < filterDim; ++fRow) {
    for (int fCol = 0; fCol < filterDim; ++fCol) {
      for (int fDepth = 0; fDepth < filterDim; ++fDepth) {

        // corresponding input voxel
        int inRow = outRow + fRow - radius;
        int inCol = outCol + fCol - radius;
        int inDepth = outDepth + fDepth - radius;

        // skipping pos outside the input volume
        if (inRow >= 0 && inRow < height && inCol >= 0 && inCol < width &&
            inDepth >= 0 && inDepth < depth) {
          // since our tensor is flattenes into 1D, we have to access it
          // linearly, convert 3d coords to 1D arr indices
          // index = (row * width * col) + (col * depth) + inDepth
          // factorixing --> (row * width + col) * depth + inDepth

          int inputIdx = (inRow * width + inCol) * depth + inDepth;
          int filterIdx = (fRow * filterDim + fCol) * filterDim + fDepth;
          sum += F[filterIdx] * N[inputIdx];
        }
      }
    }
  }

  int outputIdx = (outRow * width + outCol) * depth + outDepth;
  P[outputIdx] = sum;
}

int main() {
  // dimensions
  const int width = 3;
  const int height = 3;
  const int depth = 3;
  const int filterDim = 3;

  int volumeSize = width * height * depth;
  int filterSize = filterDim * filterDim * filterDim;

  std::size_t volumeBytes = volumeSize * sizeof(float);
  std::size_t filterBytes = filterSize * sizeof(float);

  // cpu alloc
  std::vector<float> h_N(volumeSize);
  std::vector<float> h_F(filterSize, 1.0F);
  std::vector<float> h_P(volumeSize, 0.0F);

  // init input vol with 1 to 27
  for (int i = 0; i < volumeSize; ++i) {
    h_N[i] = static_cast<float>(i);
  }

  // GPU alloc mem
  float *d_N, *d_F, *d_P;
  CUDA_CHECK(cudaMalloc(&d_N, volumeBytes));
  CUDA_CHECK(cudaMalloc(&d_F, filterBytes));
  CUDA_CHECK(cudaMalloc(&d_P, volumeBytes));

  // copy input and filter from CPU to GPU
  CUDA_CHECK(cudaMemcpy(d_N, h_N.data(), volumeBytes, cudaMemcpyHostToDevice));

  CUDA_CHECK(cudaMemcpy(d_F, h_F.data(), filterBytes, cudaMemcpyHostToDevice));

  dim3 blockSize(8, 8, 4);
  dim3 gridSize((width + blockSize.x - 1) / blockSize.x,
                (height + blockSize.y - 1) / blockSize.y,
                (depth + blockSize.z - 1) / blockSize.z);

  convolution_3D_basic<<<gridSize, blockSize>>>(d_N, d_F, d_P, width, height,
                                                depth, filterDim);

  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());

  // cpy output from gpu to cpu
  CUDA_CHECK(cudaMemcpy(h_P.data(), d_P, volumeBytes, cudaMemcpyDeviceToHost));

  std::cout << "Output Volume: ";
  for (int r = 0; r < height; ++r) {
    for (int c = 0; c < width; ++c) {
      for (int d = 0; d < depth; ++d) {
        int idx = (r * width + c) * depth + d;
        std::cout << h_P[idx] << "\n";
      }
      std::cout << "\n";
    }

    std::cout << "\n";
  }

  std::cout << "The center voxel is: " << h_P[(1 * width + 1) * depth + 1];

  cudaFree(d_N);
  cudaFree(d_F);
  cudaFree(d_P);

  return 0;
}
