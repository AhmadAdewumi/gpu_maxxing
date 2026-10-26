
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>

constexpr int N = 256;
constexpr int BLOCK_X = 16;
constexpr int BLOCK_Y = 16;

#define CHECK_CUDA_ERROR(operation)                                            \
  do {                                                                         \
    cudaError_t err = (operation);                                             \
    if (err != cudaSuccess) {                                                  \
      std::fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,    \
                   cudaGetErrorString(err));                                   \
      std::exit(EXIT_FAILURE);                                                 \
    }                                                                          \
  } while (0)

__global__ void matmulKernel(float *a, float *b, float *c, int noOfColumns) {
  const int col = blockIdx.x * blockDim.x + threadIdx.x;
  const int row = blockIdx.y * blockDim.y + threadIdx.y;

  if (row >= noOfColumns || col >= noOfColumns) {
    return;
  }

  float sum = 0.0;

  for (int k = 0; k < noOfColumns; ++k) {
    const std::size_t a_index = static_cast<std::size_t>(row) * noOfColumns + k;
    const std::size_t b_index = static_cast<std::size_t>(k) * noOfColumns + col;

    sum += a[a_index] * b[b_index];
  }

  const std::size_t c_index = static_cast<std::size_t>(row) * noOfColumns + col;
  c[c_index] = sum;
}

// cpu reference implementation
void matmulCPU(const float *A, const float *B, float *C, int noOfColumns) {
  for (int row = 0; row < noOfColumns; ++row) {
    for (int col = 0; col < noOfColumns; ++col) {
      float sum = 0.0;

      for (int k = 0; k < noOfColumns; ++k) {
        sum += A[static_cast<std::size_t>(row) * noOfColumns + k] *
               B[static_cast<std::size_t>(k) * noOfColumns + col];
      }

      C[static_cast<std::size_t>(row) * noOfColumns + col] = sum;
    }
  }
}

void initializeMatrix(std::vector<float> &matrix, std::mt19937 &rng) {
  std::uniform_real_distribution<float> distribution(0.0f, 10.0f);

  for (float &value : matrix) {
    value = distribution(rng);
  }
}

struct ValidationResult {
  bool matches;
  float maxAbsoluteError;
  std::size_t mismatchCount;
};

ValidationResult compareMatrices(const std::vector<float> &expected,
                                 const std::vector<float> &actual,
                                 float tolerance = 1e-4f) {
  ValidationResult result{true, 0.0f, 0};
  for (std::size_t i = 0; i < expected.size(); ++i) {
    const float error = std::abs(expected[i] - actual[i]);

    result.maxAbsoluteError = std::max(result.maxAbsoluteError, error);

    if (error > tolerance) {
      result.matches = false;
      ++result.mismatchCount;
    }
  }
  return result;
}

int main() {
  constexpr std::size_t elementCount = static_cast<std::size_t>(N) * N;

  constexpr std::size_t matrixBytes = elementCount * sizeof(float);

  std::cout << "Matrix size: " << N << " x " << N << '\n';
  std::cout << "Elements per matrix: " << elementCount << '\n';
  std::cout << "Bytes per matrix: " << matrixBytes << "\n\n";

  // Host-side matrices.
  std::vector<float> h_A(elementCount);
  std::vector<float> h_B(elementCount);
  std::vector<float> h_C_CPU(elementCount, 0.0);

  // store gpu result here after device to host copy for comparison
  std::vector<float> h_C_GPU(elementCount, 0.0);

  // Fixed seed makes runs use the same input data.
  std::mt19937 rng(12345);
  initializeMatrix(h_A, rng);
  initializeMatrix(h_B, rng);

  // Calculate the CPU reference and time it.
  const auto cpuStart = std::chrono::steady_clock::now();

  matmulCPU(h_A.data(), h_B.data(), h_C_CPU.data(), N);

  const auto cpuStop = std::chrono::steady_clock::now();

  const float cpuDurationMs =
      std::chrono::duration<float, std::milli>(cpuStop - cpuStart).count();

  // Allocate device memory.
  float *d_A = nullptr;
  float *d_B = nullptr;
  float *d_C = nullptr;

  CHECK_CUDA_ERROR(cudaMalloc(reinterpret_cast<void **>(&d_A), matrixBytes));

  CHECK_CUDA_ERROR(cudaMalloc(reinterpret_cast<void **>(&d_B), matrixBytes));

  CHECK_CUDA_ERROR(cudaMalloc(reinterpret_cast<void **>(&d_C), matrixBytes));


  CHECK_CUDA_ERROR(cudaFree(nullptr));
  
  // CUDA events for kernel timing.
  cudaEvent_t startEvent{};
  cudaEvent_t stopEvent{};

  CHECK_CUDA_ERROR(cudaEventCreate(&startEvent));
  CHECK_CUDA_ERROR(cudaEventCreate(&stopEvent));

  // input transfer to the GPU.
  const auto copyInStart = std::chrono::steady_clock::now();

  CHECK_CUDA_ERROR(
      cudaMemcpy(d_A, h_A.data(), matrixBytes, cudaMemcpyHostToDevice));

  CHECK_CUDA_ERROR(
      cudaMemcpy(d_B, h_B.data(), matrixBytes, cudaMemcpyHostToDevice));

  const auto copyInStop = std::chrono::steady_clock::now();

  const float copyInMs =
      std::chrono::duration<float, std::milli>(copyInStop - copyInStart)
          .count();

  // grid dimensions calculation
  const dim3 block(BLOCK_X, BLOCK_Y);

  const dim3 grid((N + BLOCK_X - 1) / BLOCK_X, (N + BLOCK_Y - 1) / BLOCK_Y);

  // GPU kernel execution measurement using CUDA events.
  CHECK_CUDA_ERROR(cudaEventRecord(startEvent));

  matmulKernel<<<grid, block>>>(d_A, d_B, d_C, N);

  // Detect immediate launch/configuration errors.
  CHECK_CUDA_ERROR(cudaGetLastError());

  CHECK_CUDA_ERROR(cudaEventRecord(stopEvent));

  // Wait for the kernel and stop event to complete.
  CHECK_CUDA_ERROR(cudaEventSynchronize(stopEvent));

  // Detect errors reported during asynchronous GPU execution.
  CHECK_CUDA_ERROR(cudaGetLastError());

  float kernelMs = 0.0f;

  CHECK_CUDA_ERROR(cudaEventElapsedTime(&kernelMs, startEvent, stopEvent));

  // Copying the result back to host memory.
  const auto copyOutStart = std::chrono::steady_clock::now();

  CHECK_CUDA_ERROR(
      cudaMemcpy(h_C_GPU.data(), d_C, matrixBytes, cudaMemcpyDeviceToHost));

  const auto copyOutStop = std::chrono::steady_clock::now();

  const float copyOutMs =
      std::chrono::duration<double, std::milli>(copyOutStop - copyOutStart)
          .count();

  // Approximate total for the measured phases.
  const double phaseTotalMs =
      copyInMs + static_cast<double>(kernelMs) + copyOutMs;

  // Verify the GPU output against the CPU reference.
  const ValidationResult validation = compareMatrices(h_C_CPU, h_C_GPU);

  // Print measurements and correctness results.
  std::cout << std::fixed << std::setprecision(4);

  std::cout << "CPU reference time:       " << cpuDurationMs << " ms\n";

  std::cout << "Input copy wall time:     " << copyInMs << " ms\n";

  std::cout << "GPU kernel event time:    " << kernelMs << " ms\n";

  std::cout << "Output copy wall time:    " << copyOutMs << " ms\n";

  std::cout << "Sum of measured phases:   " << phaseTotalMs << " ms\n";

  std::cout << std::scientific;

  std::cout << "Maximum absolute error:   " << validation.maxAbsoluteError
            << '\n';

  std::cout << "Mismatched elements:      " << validation.mismatchCount << '\n';

  std::cout << "Correctness: " << (validation.matches ? "PASS" : "FAIL")
            << '\n';

  if (phaseTotalMs > 0.0) {
    std::cout << std::fixed << std::setprecision(3);

    std::cout << "CPU time / measured GPU phases: " << cpuDurationMs / phaseTotalMs
              << "x\n";
  }

  // free resources
  CHECK_CUDA_ERROR(cudaEventDestroy(startEvent));
  CHECK_CUDA_ERROR(cudaEventDestroy(stopEvent));

  CHECK_CUDA_ERROR(cudaFree(d_A));
  CHECK_CUDA_ERROR(cudaFree(d_B));
  CHECK_CUDA_ERROR(cudaFree(d_C));

  return validation.matches ? EXIT_SUCCESS : EXIT_FAILURE;
}
