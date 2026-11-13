
// 2D thread block dimensions (32x32 = 1024 threads)
#define IN_TILE_DIM 32
#define OUT_TILE_DIM (IN_TILE_DIM - 2) // 30x30 output slice per z-step

// Stencil coefficients in constant memory
__constant__ float c0, c1, c2, c3, c4, c5, c6;

// Kernel with thread coarsening and register tiling in the z direction
__global__ void stencil_kernel(float *in, float *out, unsigned int N) {
  int iStart = blockIdx.z * OUT_TILE_DIM;
  int j = blockIdx.y * OUT_TILE_DIM + threadIdx.y - 1;
  int k = blockIdx.x * OUT_TILE_DIM + threadIdx.x - 1;

  // Register tiling: inPrev, inCurr, and inNext are stored in private thread
  // registers
  float inPrev;
  // Only the current XY plane/slice needs shared memory so neighbors (j±1, k±1)
  // can access it
  __shared__ float inCurr_s[IN_TILE_DIM][IN_TILE_DIM];
  float inCurr;
  float inNext;

  if (iStart - 1 >= 0 && iStart - 1 < N && j >= 0 && j < N && k >= 0 && k < N) {
    inPrev = in[(iStart - 1) * N * N + j * N + k];
  }
  if (iStart >= 0 && iStart < N && j >= 0 && j < N && k >= 0 && k < N) {
    inCurr = in[iStart * N * N + j * N + k];
    inCurr_s[threadIdx.y][threadIdx.x] = inCurr;
  }

  for (int i = iStart; i < iStart + OUT_TILE_DIM; ++i) {
    if (i + 1 >= 0 && i + 1 < N && j >= 0 && j < N && k >= 0 && k < N) {
      inNext = in[(i + 1) * N * N + j * N + k];
    }
    __syncthreads();

    if (i >= 1 && i < N - 1 && j >= 1 && j < N - 1 && k >= 1 && k < N - 1) {
      if (threadIdx.y >= 1 && threadIdx.y < IN_TILE_DIM - 1 &&
          threadIdx.x >= 1 && threadIdx.x < IN_TILE_DIM - 1) {
        out[i * N * N + j * N + k] =
            c0 * inCurr + c1 * inCurr_s[threadIdx.y][threadIdx.x - 1] +
            c2 * inCurr_s[threadIdx.y][threadIdx.x + 1] +
            c3 * inCurr_s[threadIdx.y + 1][threadIdx.x] +
            c4 * inCurr_s[threadIdx.y - 1][threadIdx.x] + c5 * inPrev +
            c6 * inNext;
      }
    }
    __syncthreads();

    // Shift registers and update the single shared memory slice for the next
    // iteration
    inPrev = inCurr;
    inCurr = inNext;
    inCurr_s[threadIdx.y][threadIdx.x] = inNext;
  }
}

void launch_register_tiled_stencil(float *d_in, float *d_out, unsigned int N) {
  dim3 blockDim(IN_TILE_DIM, IN_TILE_DIM, 1);

  unsigned int numBlocks = (N + OUT_TILE_DIM - 1) / OUT_TILE_DIM;
  dim3 gridDim(numBlocks, numBlocks, numBlocks);

  stencil_kernel<<<gridDim, blockDim>>>(d_in, d_out, N);
  cudaDeviceSynchronize();
}

/*
 * instead of having three shared memory, we only have one, and the shared mem
 * consumption drops to 1/3rd, this can allow more blocks to reside on the SM
 * registers are not also free and limited, if each thread consumes more
 * registers, we can only accomodate fewer blocks on an SM and may cause
 * spilling to global memory, which can destroy the performance benefit we are
 * trying to gain
 */
