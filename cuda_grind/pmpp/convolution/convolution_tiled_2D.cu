
#include "cuda_runtime.h"
#include <__clang_cuda_runtime_wrapper.h>

#define FILTER_RADIUS 1

#define INPUT_TILE_DIMENSION 32
#define OUTPUT_TILE_DIMENSION (INPUT_TILE_DIMENSION - 2 * FILTER_RADIUS)

/*
 * N -> input image
 * F -> convolution filter
 * P -> output image
 * r -> filter radius, if radius=2, filter size = 2r+1 = 5x5, spans 5 pixels
 * round
 * width, height -> dimensions of the input image
 */

__constant__ float F_c[2 * FILTER_RADIUS + 1][2 * FILTER_RADIUS + 1];
__global__ void
convolution_2D_mem_kernel_using_constant_mem_for_F(float *N, float *F, float *P,
                                                   int width, int height) {

  // loading data from the original image, tells us where to find the data
  // each thread calculates the col and row index of the input
  int col = blockIdx.x * OUTPUT_TILE_DIMENSION + threadIdx.x - FILTER_RADIUS;
  int row = blockIdx.y * OUTPUT_TILE_DIMENSION + threadIdx.y - FILTER_RADIUS;

  // the shared memory input tile
  __shared__ float N_s[INPUT_TILE_DIMENSION][INPUT_TILE_DIMENSION];

  // load the input tiles
  if (row >= 0 && row <= height && col >= 0 && col <= width) {
    N_s[threadIdx.y][threadIdx.x] = N[row * width + col];
  } else {
    N_s[threadIdx.y][threadIdx.x] = 0.0f;
  }

  // then we are going to wait until every thread has loaded its elements
  __syncthreads();

  // calcaulting coordinate of the output tiles
  // while deactviating halo loaders
  int tileCol = threadIdx.x - FILTER_RADIUS;
  int tileRow = threadIdx.y - FILTER_RADIUS;

  // cutting off halo threads/elements
  // is this a valid position in the original image
  if (tileCol >= 0 && tileCol < OUTPUT_TILE_DIMENSION && tileRow >= 0 &&
      tileRow < OUTPUT_TILE_DIMENSION) {
    if (row >= 0 && row <= height && col >= 0 && col <= width) {
      float pValue = 0.0f;
      for (int fRow = 0; fRow < 2 * FILTER_RADIUS + 1; ++fRow) {
        for (int fCol = 0; fCol < 2 * FILTER_RADIUS + 1; ++fCol) {
          pValue += F_c[fRow][fCol] * N_s[tileRow + fRow][tileCol + fCol];
        }
      }

      P[row * width + col] = pValue;
    }
  }
}
