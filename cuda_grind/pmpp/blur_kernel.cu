
#include <cuda_runtime.h>

__global__ blurKernel(unsigned char *input, unsigned char *output, int width,
                      int height) {
  constexpr BLUR_SIZE = 1;

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;

  if (col >= width || row >= height) {
    return;
  }

  float pixelSum = 0.0f;
  int pixelCount = 0;

  for (int blurRow = -BLUR_SIZE; blurRow <= BLUR_SIZE; ++blurRow) {
    for (int blurCol = -BLUR_SIZE; blurCol <= BLUR_SIZE; ++blurCol) {
      int curRow = row + blurRow;
      int curCol = col + blurCol;

      // verify it is a valid image
      if (curRow >= 0 && curRow < height && curCol >= 0 && curCol < width) {
        pixelSum += input[curRow * width + curCol];
        ++pixelCount;
      }
    }

    output[row * width + col] =
        static_cast<unsigned char>(pixelSum / pixelCount);
  }
}
