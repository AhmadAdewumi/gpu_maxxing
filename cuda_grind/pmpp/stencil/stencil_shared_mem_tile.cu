
#include <cuda_runtime_api.h>
#include <curand_mtgp32_kernel.h>
#include <thread>
#include <vector_types.h>
#define IN_TILE_DIM 8
#define OUT_TILE_DIM (IN_TILE_DIM - 2)

// stencil coefficients in constant memory
__constant__ float c0;
__constant__ float c1;
__constant__ float c2;
__constant__ float c3;
__constant__ float c4;
__constant__ float c5;
__constant__ float c6;

// 3D 7 point stencil
__global__ void stencil_shared_mem_kernel(float *in, float *out,
                                          unsigned int N) {
  // global coordinates
  int i = blockIdx.z * OUT_TILE_DIM + threadIdx.z - 1;
  int j = blockIdx.y * OUT_TILE_DIM + threadIdx.y - 1;
  int k = blockIdx.x * OUT_TILE_DIM + threadIdx.x - 1;

  __shared__ float in_s[IN_TILE_DIM][IN_TILE_DIM][IN_TILE_DIM];

  // we load input tiles including halo cells into shared mem
  if (i >= 0 && i < N && j >= 0 && j < N && k >= 0 && k < N) {
    in_s[threadIdx.z][threadIdx.y][threadIdx.x] = in[i * N * N + j * N + k];
  }

  // wait till they are all loaded
  __syncthreads();

  // we don't calculate output for the boundary cells,  we reject them
  //  we only compute interior points of the global grid
  if (i >= 1 && i < N - 1 && j >= 1 && j < N - 1 && k >= 1 && k <= N - 1) {
    // reject halo loading threads
    if (threadIdx.z >= 1 && threadIdx.z <= IN_TILE_DIM - 1 &&
        threadIdx.y >= 1 && threadIdx.y <= IN_TILE_DIM - 1 &&
        threadIdx.x >= 1 && threadIdx.x <= IN_TILE_DIM - 1) {
      out[i * N * N + j * N + k] =
          c0 * in_s[threadIdx.z][threadIdx.y][threadIdx.x] +
          c1 * in_s[threadIdx.z][threadIdx.y][threadIdx.x - 1] +
          c2 * in_s[threadIdx.z][threadIdx.y][threadIdx.x + 1] +
          c3 * in_s[threadIdx.z][threadIdx.y - 1][threadIdx.x] +
          c4 * in_s[threadIdx.z][threadIdx.y + 1][threadIdx.x] +
          c5 * in_s[threadIdx.z - 1][threadIdx.y][threadIdx.x] +
          c6 * in_s[threadIdx.z + 1][threadIdx.y][threadIdx.x];
    }
  }
}

void launchStencil(float *d_in, float *d_out, unsigned int N) {
  // copy stencil weight to device
  float h_c0 = 0.5f;
  float h_c1 = 0.0833f, h_c2 = 0.0833f;
  float h_c3 = 0.0833f, h_c4 = 0.0833f;
  float h_c5 = 0.0833f, h_c6 = 0.0833f;

  cudaMemcpyToSymbol(c0, &h_c0, sizeof(float));
  cudaMemcpyToSymbol(c1, &h_c1, sizeof(float));
  cudaMemcpyToSymbol(c2, &h_c2, sizeof(float));
  cudaMemcpyToSymbol(c3, &h_c3, sizeof(float));
  cudaMemcpyToSymbol(c4, &h_c4, sizeof(float));
  cudaMemcpyToSymbol(c5, &h_c5, sizeof(float));
  cudaMemcpyToSymbol(c6, &h_c6, sizeof(float));

  // block def, include halo also
  dim3 blockDim(IN_TILE_DIM, IN_TILE_DIM, IN_TILE_DIM);

  // divide volume by the output tile
  unsigned int numBlocks = (N + OUT_TILE_DIM - 1) / OUT_TILE_DIM;
  dim3 gridDim(numBlocks, numBlocks, numBlocks);
  stencil_shared_mem_kernel<<<gridDim, blockDim>>>(d_in, d_out, N);
  cudaDeviceSynchronize();
}

int main() {}
