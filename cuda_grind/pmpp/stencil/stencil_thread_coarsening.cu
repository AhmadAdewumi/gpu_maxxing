
/*
 * instead of loading all the 3D tiles into shared memory, which may not fit for
 * large inputs like a tile with dimension 32x32x32, so we are going to use 2D
 * planes coz 3D is just couples of 2d planes stacked together, load the 2D
 * planes (x,y) into shared memory and iterate through the z axis
 * the thing is let's say we wanna calc j(2,2), we are gonna need, out[1,2,2],
 * out[2,2,2], out[3,2,2], out[4,2,2]. for the first output, out[1,2,2], we need
 * plane 0,1,2 representing prev, curr, next respectively. then say we wanna
 * calc out[2,2,2], we need planes 1,2,3, so we reuse plane 1,2 and only need to
 * load plane 3 and that goes on and on and on
 */

#include <cuda_runtime_api.h>
#define IN_TILE_DIM 32
#define OUT_TILE_DIM (IN_TILE_DIM - 2) // 30x30 output slice per step

__constant__ float c0, c1, c2, c3, c4, c5, c6;

// thread coarsening in the z direction for 3D 7 point stencil
__global__ void stencil_coarse_kernel(float *in, float *out, unsigned int N) {
  // for OUT_TILE_DIM of of dim 4, block 0,1,2.. corresponds to plane 0,4,8..
  int iStart = blockIdx.z * OUT_TILE_DIM;              // plane coordinate
  int j = blockIdx.y * OUT_TILE_DIM + threadIdx.y - 1; // row
  int k = blockIdx.x * OUT_TILE_DIM + threadIdx.x - 1; // col

  // alloc the three shared mem planes to store the prev, curr and next input
  // planes for tile dim 6x6x6, this contains 3x6x6 = 108 floats instead of 216
  __shared__ float inPrev_s[IN_TILE_DIM][IN_TILE_DIM];
  __shared__ float inCurr_s[IN_TILE_DIM][IN_TILE_DIM];
  __shared__ float inNext_s[IN_TILE_DIM][IN_TILE_DIM];

  // we load the first 2 input planes
  if (iStart - 1 >= 0 && iStart - 1 < N && j >= 0 && j < N && k >= 0 && k < N) {
    inPrev_s[threadIdx.y][threadIdx.x] = in[(iStart - 1) * N * N + j * N + k];
  }

  if (iStart >= 0 && iStart < N && j >= 0 && j < N && k >= 0 && k < N) {
    inCurr_s[threadIdx.y][threadIdx.x] = in[iStart * N * N + j * N + k];
  }

  /*
   * processes the output planes, for a 6x6, we execute it 4 times, 0,1,2,3
   */
  for (int i = iStart; i < iStart + OUT_TILE_DIM; ++i) {
    // for each output plane, we load the nxt input plane
    if (i + 1 >= 0 && i + 1 < N && j >= 0 && j < N && k >= 0 && k < N) {
      inNext_s[threadIdx.y][threadIdx.x] = in[i * N * N + j * N + k];
    }
    __syncthreads();

    // to take care of the halo
    if (i >= 1 && i < N - 1 && j >= 1 && j < N - 1 && k >= 1 && k < N - 1) {
      // e.g for a 6x6, we use only threads 1 to 4
      if (threadIdx.y >= 1 && threadIdx.y < N - 1 && threadIdx.x >= 1 &&
          threadIdx.x < N - 1) {
        out[i * N * N + j * N + k] =
            c0 * inCurr_s[threadIdx.y][threadIdx.x] +     // center
            c1 * inCurr_s[threadIdx.y][threadIdx.x - 1] + // left
            c2 * inCurr_s[threadIdx.y][threadIdx.x + 1] + // right
            c3 * inCurr_s[threadIdx.y - 1][threadIdx.x] + // above
            c4 * inCurr_s[threadIdx.y + 1][threadIdx.x] + // below
            c5 * inPrev_s[threadIdx.y][threadIdx.x] +     // previous plane
            c6 * inNext_s[threadIdx.y][threadIdx.x];      // next plane
      }
    }
    __syncthreads();

    // then, we slide/advance the windo forward, old curr plane becomes the new
    // previous plane while the old next plane becomes the new current plane
    inPrev_s[threadIdx.y][threadIdx.x] = inCurr_s[threadIdx.y][threadIdx.x];
    inCurr_s[threadIdx.y][threadIdx.x] = inNext_s[threadIdx.y][threadIdx.x];
  }
}

void launch_coarsened_stencil(float *in, float *out, unsigned int N) {
  // 2d block -> x-y axis
  dim3 blockSize(IN_TILE_DIM, IN_TILE_DIM, 1);

  unsigned int numBlocks = (N + OUT_TILE_DIM - 1) / OUT_TILE_DIM;
  dim3 gridSize(numBlocks, numBlocks, numBlocks);

  stencil_coarse_kernel<<<gridSize, blockSize>>>(in, out, N);
  cudaDeviceSynchronize();
}

/*
 * ordinary 3D tiling for 32x32x32
  - Threads: 32^3=32768.
 - Shared memory: 32^3x4=128 KiB.
 -----------
 Coarsened 3D tiling
 - Threads: 32^2=1024
 - Shared memory: 3x32^2x4=12 KiB.
 - Output dimensions: 30^ 3=27000
 - Active output threads: 30^2=900
 - Outputs per active thread: 30

 // TRADE OFF --> each thread now does more sequenctial work as too much
 coarsening can increase register usage, reduce parallelism which in turn hurts
 performance, so it is an optimization not a guarantee of faster execution
 */
