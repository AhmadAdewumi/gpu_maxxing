
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

constexpr int N = 256;
constexpr int BLOCK_X = 16;
constexpr int BLOCK_Y = 16;

#define CHECK_CUDA_ERROR(operation)                                            \
  do {                                                                         \
    cudaError_t err = operation;                                               \
    if (err != cudaSuccess) {                                                  \
      std::fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,    \
                   cudaGetErrorString(err));                                   \
      std::exit(EXIT_FAILURE);                                                 \
    }                                                                          \
    while (0)
