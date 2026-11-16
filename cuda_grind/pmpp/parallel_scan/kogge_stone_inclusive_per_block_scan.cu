
#define N 32
#define SEG_SIZE 32
/*
 * so, instead of making each thread perform iits own prefix sum, which may lead
 * to O(N^2) work efficiency which is much worse than the sequential approach,
 * so in kogge stone, each thread  calculatesits own partial sum, at every
 * iteration, we.. don't know how to put it , we get back to this later
 */

__global__ void kogge_stone_inclusive(float *input, float *output) {
  __shared__ float buffer_s[SEG_SIZE];
  unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  // load into shared mem
  if (i < N) {
    buffer_s[threadIdx.x] = input[i];
  } else {
    buffer_s[threadIdx.x] = 0.0f;
  }

  // execute the concurrent reduction trees
  for (unsigned int stride = 1; stride < blockDim.x; stride *= 2) {
    /*
     * ensures that all threads have finished writing the values they calculated
     *to buffer_s in the previous iteration before other threads read them in
     *the current iteration */
    __syncthreads();

    float temp;
    if (threadIdx.x >= stride) {
      temp = buffer_s[threadIdx.x] + buffer_s[threadIdx.x - stride];
    }

    /*
     * second sync to avoid race condition and  ensures atomic read and write
     *
     * ensures that all threads have
     finished reading their input values from buffer_s before other threads
     overwrite them
     */
    __syncthreads();

    if (threadIdx.x >= stride) {
      buffer_s[threadIdx.x] = temp;
    }
  }

  if (i < N) {
    output[i] = buffer_s[threadIdx.x];
  }
}

/*
 * in the above implementation, there is synchronization overhead twice, and the
 * reason for the second sy, is because forward values need the old values to
 * calculate their partial sum, meanwhile, the values we read beforehand and
 * already calc thier sum may wanna writeto those locations that still contains
 * the old values,so the sync ensures we read all the values needed for
 * calculation frst beforemoving on to writing the sums. so this approach
 * introduces the DOUBLE BUFFERING optimization, where we have one buffer for
 * reading and another for writing and we can swap them in each iter, uing the
 * values in buffer2 by copying to buffer1 and so on.. So, we can eliminate the
 * second barrier
 */

__global__ void kogge_stone_double_buffering(float *input, float *output) {
  unsigned int i = blockDim.x * blockIdx.x + threadIdx.x;

  __shared__ float buffer1_s[SEG_SIZE];
  __shared__ float buffer2_s[SEG_SIZE];

  float *inBuffer_s = buffer1_s;
  float *outBuffer_s = buffer2_s;

  // load the values from global memory
  inBuffer_s[threadIdx.x] = (i < N) ? input[i] : 0.0f;

  // the thing is as the prefic sum progresses there are some positions where
  // the final output is calculated already and no need for modififcation, so
  // two options, either write the sum or preserve the existing value
  for (unsigned int stride = 1; stride < blockDim.x; stride *= 2) {
    if (threadIdx.x >= stride) {
      outBuffer_s[threadIdx.x] =
          inBuffer_s[threadIdx.x] + inBuffer_s[threadIdx.x - stride];
    } else {
      outBuffer_s[threadIdx.x] = inBuffer_s[threadIdx.x];
    }

    // swap the buffers
    float *temp = inBuffer_s;
    inBuffer_s = outBuffer_s;
    outBuffer_s = temp;
  }
  if (i < N) {
    output[i] = inBuffer_s[threadIdx.x];
  }
}
