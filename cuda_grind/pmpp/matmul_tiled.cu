

constexpr int TILE_WIDTH = 2;
__global__ void matmulTiled(float *M, float *N, float *C, int width) {
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  int col = blockIdx.x * blockDim.x + threadidx.x;

  // shared by memory shared by all threads in a block
  __shared__ float tileM[TILE_WIDTH][TILE_WIDTH];
  __shared__ float tileN[TILE_WIDTH][TILE_WIDTH];

  float pValue = 0.0f;

  int numTiles = (width + TILE_WIDTH - 1) / TILE_WIDTH;
  for (int t = 0; t < numTiles; ++t) {
    // input elements to load
    int mCol = t * width + threadIdx.x;
    int nRow = t * width + threadIdx.y;

    // loads one element of M's tile
    if (row < width && mCol < width) {
      tileM[threadIdx.y][threadIdx.x] = M[row * width + mCol];
    } else {
      tileM[threadIdx.y][threadIdx.x] = 0.0f;
    }

    // loads one element of N's tile
    if (nRow < width && col < width) {
      tileN[threadIdx.y][threadIdx.x] = N[nRow * width + col];
    } else {
      tileM[threadIdx.y][threadIdx.x] = 0.0f;
    }

    // prevents the threads from reading from the shared memory
    //  until every thread has finished loading its values
    __syncthreads();

    // calculating the thread's partial product using values from shared memory
    for(int k =0; k < TILE_WIDTH; ++k){
        pValue+=tileM[threadidx.y][k] * tileN[k][threadIdx.x];
    }

    // prevents threads from overwriting the shared memory while another thread is still readingit
    __syncthreads();
    
  }

  // write answer only if it is av alid output kernel
  if (row <width&&col<width) {
      P[row*width+col]=pValue;
  }
}
