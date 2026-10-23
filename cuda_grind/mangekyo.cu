
#include <cerrno>
#include <chrono>
#include <cstddef>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <vector>

#define CHECK_CUDA_ERROR(operation)                                            \
  do {                                                                         \
    cudaError_t err = (operation);                                             \
    if (err != cudaSuccess) {                                                  \
      std::fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,    \
                   cudaGetErrorString(err));                                   \
      std::exit(EXIT_FAILURE);                                                 \
    }                                                                          \
  } while (0)

__global__ void brightnessKernel(const unsigned char *input,
                                 unsigned char *output, std::size_t noOfPixels,
                                 int brightness) {
  // casting the blockIdx coz we may have a large dataset that may overflow
  // uint32
  std::size_t tid = blockIdx.x * blockDim.x + threadIdx.x;

  if (tid < noOfPixels) {
    const int value = input[tid] + brightness;
    const int clamped = std::max(0, std::min(255, value));

    output[tid] = clamped;
  }
}

void cpuBrightness(const unsigned char *input, unsigned char *output,
                   std::size_t noOfPixels, int brightness) {
  for (std::size_t i{0}; i < noOfPixels; ++i) {
    int value = input[i] + brightness;
    output[i] = std::max(0, std::min(value, 255));
  }
}

// launch brightness kernel for a particular chunk of the pixels
void launchBrightness(const unsigned char *d_input, unsigned char *d_output,
                      std::size_t noOfPixels, int brightness,
                      cudaStream_t stream) {
  int blockSize = 256;
  int gridSize = (noOfPixels + blockSize - 1) / blockSize;
  brightnessKernel<<<gridSize, blockSize, 0, stream>>>(d_input, d_output,
                                                       noOfPizels, brightness);

  CHECK_CUDA_ERROR(cudaGetLastError());
}

bool verify(const unsigned char *actual,
            const std::vector<unsigned char> &expected, std::size_t noOfPixels,
            const char *testName) {
  std::size_t errors = 0;

  for (std::size_t i{0}; i < noOfPixels; ++i) {
    if (actual[i] != expected[i]) {
      if (errors < 5) {
        std::printf("[%s] mismatch at %zu: expected %u, got %u\n", testName, i,
                    static_cast<unsigned>(expected[i]),
                    static_cast<unsigned>(actual[i]));
      }

      ++errors;
    }
  }

  if (errors == 0) {
    std::printf("[%s] PASS: all %zu pixels match\n", testName, noOfPixels);
  }

  std::printf("[%s] FAIL: %zu mismatches\n", testName, errors);
  return false;
}

double runSynchronous(const unsigned char *h_input, unsigned char *h_output,
                      unsigned char *d_input, unsigned char *d_output,
                      std::size_t noOfPixels, int brightness, int repetitions) {
  const std::size_t bytes = CHECK_CUDA_ERROR(cudaDeviceSynchronize());

  const auto start = std::chrono::steady_clock::now();

  for (int r = 0; r < repetitions; ++r) {
    CHECK_CUDA_ERROR(
        cudaMemcpy(d_input, h_input, bytes, cudaMemcpyHostToDevice()));

    launchBrightness(d_input, d_output, noOfPixels, brightness, nullptr);

    CHECK_CUDA_ERROR(cudaDeviceSynchronize());
      CHECK_CUDA_ERROR(cudaMemcpy(
                  hOutput, dOutput, bytes, cudaMemcpyDeviceToHost)));
  }

  const auto start = std::chrono::steady_clock::now();
  return std::chrono::duration<double, std::milli>(stop - start).count() /
         repetitions;
}

double runInterleaved(const unsigned char *h_input, unsigned char *h_output,
                      unsigned char *d_input, unsigned char *d_output,
                      std::size_t noOfPixels, int brightness,
                      cudaStream_t *streams, int numStreams, int repetition) {}
