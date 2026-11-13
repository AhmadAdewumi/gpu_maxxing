#define FILTER_RADIUS 1
#define OUT_TILE_DIM 4
#define IN_TILE_DIM (OUT_TILE_DIM + 2 * FILTER_RADIUS)
#define FILTER_DIM (2 * FILTER_RADIUS + 1)

__constant__ float F_c[FILTER_DIM][FILTER_DIM][FILTER_DIM];

__global__ void convolution_3d_tiled(const float *N, float *P, int width,
                                     int height, int depth) {

  // Global coordinates of the input voxel loaded by this thread.
  int col = blockIdx.x * OUT_TILE_DIM + threadIdx.x - FILTER_RADIUS;

  int row = blockIdx.y * OUT_TILE_DIM + threadIdx.y - FILTER_RADIUS;

  int dep = blockIdx.z * OUT_TILE_DIM + threadIdx.z - FILTER_RADIUS;

  __shared__ float N_s[IN_TILE_DIM][IN_TILE_DIM][IN_TILE_DIM];

  // Every thread loads one input voxel.
  if (row >= 0 && row < height && col >= 0 && col < width && dep >= 0 &&
      dep < depth) {

    N_s[threadIdx.z][threadIdx.y][threadIdx.x] =
        N[(row * width + col) * depth + dep];

  } else {
    N_s[threadIdx.z][threadIdx.y][threadIdx.x] = 0.0f;
  }

  // Wait until the entire input tile has been loaded.
  __syncthreads();

  // Identify threads that own output voxels.
  int tileCol = threadIdx.x - FILTER_RADIUS;
  int tileRow = threadIdx.y - FILTER_RADIUS;
  int tileDep = threadIdx.z - FILTER_RADIUS;
  
  
  if (tileCol >= 0 && tileCol < OUT_TILE_DIM &&
          tileRow >= 0 && tileRow < OUT_TILE_DIM &&
          tileDep >= 0 && tileDep < OUT_TILE_DIM) {
  
          // Global output coordinates are non-negative here.
          if (row < height && col < width && dep < depth) {
  
              float sum = 0.0f;
  
              // Compute convolution using shared memory.
              for (int fRow = 0; fRow < FILTER_DIM; ++fRow) {
                  for (int fCol = 0; fCol < FILTER_DIM; ++fCol) {
                      for (int fDep = 0; fDep < FILTER_DIM; ++fDep) {
  
                          sum += F_c[fRow][fCol][fDep] *
                                 N_s[tileDep + fDep]
                                    [tileRow + fRow]
                                    [tileCol + fCol];
                      }
                  }
              }
  
              // Write the output voxel.
              int outputIdx =
                  (row * width + col) * depth + dep;
  
              P[outputIdx] = sum;
          }
      }
  }
