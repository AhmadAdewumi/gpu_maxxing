
/*
 * N -> input image
 * F -> convolution filter
 * P -> output image
 * r -> filter radius, if radius=2, filter size = 2r+1 = 5x5, spans 5 pixels
 * round
 * width, height -> dimensions of the input image
 */
__global__ void convolution_2D_basic_kernel(float *N, float *F, float *P, int r,
                                            int width, int height) {
  // to get the output pixel a thread is responsible for
  int outCol = blockIdx.x * blockDim.x + threadIdx.x;
  int outRow = blockIdx.y * blockDim.y + threadIdx.y;

  // accumulator held in register, to avoid DRAM trips
  float pixel_value = 0.0f;

  int filter_size = 2 * r + 1;
  // iterating thru every element in the filter
  // for a 5x5, that is 25 iterations
  for (int fRow = 0; fRow < ((2 * r) + 1); ++fRow) {
    for (int fCol = 0; fCol < ((2 * r) + 1); ++fCol) {

      // getting the corresponding input col
      int input_row = outRow - r + fRow;
      int input_col = outCol - r + fCol;

      /*
       * check whether the input coordinate actually exists
       * if the coordinate is invalid, that filter contrib is skipped
       * control flow divergence can  occur
       */

      if (input_row >= 0 && input_row < height && input_col >= 0 &&
          input_col < width) {
        // cpp stores our N as contiguoous values, so a 1D pointer, even though
        // it represents a 2D image, and also 
        pixel_value +=
            F[fRow * filter_size + fCol] * N[input_row * width + input_col];
      }
    }
  }

  // write new pixel value to the output position
  P[outRow * width + outCol] = pixel_value;
}
