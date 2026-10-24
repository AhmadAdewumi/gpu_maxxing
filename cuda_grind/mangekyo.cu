
#include <algorithm>
#include <cerrno>
#include <chrono>
#include <climits>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <fstream>
#include <iostream>
#include <ratio>
#include <vector>

#define CHECK_CUDA_ERROR(operation)                                            \
  do {                                                                         \
    cudaError_t err = (operation);                                             \
    if (err != cudaSuccess) {                                                  \
      std::fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,    \
                   cudaGetErrorString(err));                                   \
      std::exit(EXIT_FAILURE);                                                 \
    }                                                                          \
  } while (0)

__global__ void brightnessKernel(const unsigned char *input,
                                 unsigned char *output, std::size_t noOfPixels,
                                 int brightness) {
  // casting the blockIdx coz we may have a large dataset that may overflow
  // uint32
  const std::size_t tid =
      static_cast<std::size_t>(blockIdx.x) * blockDim.x + threadIdx.x;

  if (tid < noOfPixels) {
    const int value = input[tid] + brightness;
    const int clamped = (value < 0) ? 0 : (value > 255) ? 255 : value;

    output[tid] = clamped;
  }
}

void cpuBrightness(const unsigned char *input, unsigned char *output,
                   std::size_t noOfPixels, int brightness) {
  for (std::size_t i{0}; i < noOfPixels; ++i) {
    int value = input[i] + brightness;
    output[i] = std::max(0, std::min(value, 255));
  }
}

// launch brightness kernel for a particular chunk of the pixels
void launchBrightness(const unsigned char *d_input, unsigned char *d_output,
                      std::size_t noOfPixels, int brightness,
                      cudaStream_t stream) {
  int blockSize = 256;
  int gridSize = (noOfPixels + blockSize - 1) / blockSize;
  brightnessKernel<<<gridSize, blockSize, 0, stream>>>(d_input, d_output,
                                                       noOfPixels, brightness);

  CHECK_CUDA_ERROR(cudaGetLastError());
}

bool verify(const unsigned char *actual,
            const std::vector<unsigned char> &expected, std::size_t noOfPixels,
            const char *testName) {
  std::size_t errors = 0;

  for (std::size_t i{0}; i < noOfPixels; ++i) {
    if (actual[i] != expected[i]) {
      if (errors < 5) {
        std::printf("[%s] mismatch at %zu: expected %u, got %u\n", testName, i,
                    static_cast<unsigned>(expected[i]),
                    static_cast<unsigned>(actual[i]));
      }

      ++errors;
    }
  }

  if (errors == 0) {
    std::printf("[%s] PASS: all %zu pixels match\n", testName, noOfPixels);
    return true;
  }

  std::printf("[%s] FAIL: %zu mismatches\n", testName, errors);
  return false;
}

double runSynchronous(const unsigned char *h_input, unsigned char *h_output,
                      unsigned char *d_input, unsigned char *d_output,
                      std::size_t noOfPixels, int brightness, int repetitions) {
  CHECK_CUDA_ERROR(cudaDeviceSynchronize());
  const std::size_t bytes = noOfPixels * sizeof(unsigned char);

  const auto start = std::chrono::steady_clock::now();

  for (int r = 0; r < repetitions; ++r) {
    CHECK_CUDA_ERROR(
        cudaMemcpy(d_input, h_input, bytes, cudaMemcpyHostToDevice));

    // we are gonna use the kernel's default stream
    launchBrightness(d_input, d_output, noOfPixels, brightness, nullptr);

    CHECK_CUDA_ERROR(cudaDeviceSynchronize());
    CHECK_CUDA_ERROR(
        cudaMemcpy(h_output, d_output, bytes, cudaMemcpyDeviceToHost));
  }

  const auto stop = std::chrono::steady_clock::now();

  // .. calc  and return average time per repitition
  return std::chrono::duration<double, std::milli>(stop - start).count() /
         repetitions;
}

double runInterleaved(const unsigned char *h_input, unsigned char *h_output,
                      unsigned char *d_input, unsigned char *d_output,
                      std::size_t noOfPixels, int brightness,
                      cudaStream_t *streams, int numStreams, int repetitions) {
  CHECK_CUDA_ERROR(cudaDeviceSynchronize());

  auto start = std::chrono::steady_clock::now();

  for (int r = 0; r < repetitions; ++r) {
    for (int stream = 0; stream < numStreams; ++stream) {
      // to get the range of each chunk
      const std::size_t begin = noOfPixels * stream / numStreams;
      const std::size_t end = noOfPixels * (stream + 1) / numStreams;

      std::size_t count = end - begin;
      std::size_t bytes = count * sizeof(unsigned char);

      CHECK_CUDA_ERROR(cudaMemcpyAsync(d_input + begin, h_input + begin, bytes,
                                       cudaMemcpyHostToDevice,
                                       streams[stream]));

      launchBrightness(d_input + begin, d_output + begin, count, brightness,
                       streams[stream]);

      CHECK_CUDA_ERROR(cudaMemcpyAsync(h_output + begin, d_output + begin,
                                       bytes, cudaMemcpyDeviceToHost,
                                       streams[stream]));
    }
  }

  // synchronizing the streams
  for (int stream = 0; stream < numStreams; ++stream) {
    CHECK_CUDA_ERROR(cudaStreamSynchronize(streams[stream]));
  }

  const auto stop = std::chrono::steady_clock::now();

  return std::chrono::duration<double, std::milli>(stop - start).count() /
         repetitions;
}

// BATCHED SUBMISSION
double runBatched(const unsigned char *h_input, unsigned char *h_output,
                  unsigned char *d_input, unsigned char *d_output,
                  std::size_t noOfPixels, int brightness, cudaStream_t *streams,
                  int numStreams, int repetitions) {
  CHECK_CUDA_ERROR(cudaDeviceSynchronize());

  auto start = std::chrono::steady_clock::now();

  for (int r = 0; r < repetitions; ++r) {

    // submit all input transfer
    for (int stream = 0; stream < numStreams; ++stream) {
      std::size_t begin = noOfPixels * stream / numStreams;
      std::size_t end = noOfPixels * (stream + 1) / numStreams;
      std::size_t count = end - begin;

      CHECK_CUDA_ERROR(cudaMemcpyAsync(
          d_input + begin, h_input + begin, count * sizeof(unsigned char),
          cudaMemcpyHostToDevice, streams[stream]));
    }

    // submit every kernel
    for (int stream = 0; stream < numStreams; ++stream) {
      std::size_t begin = noOfPixels * stream / numStreams;
      std::size_t end = noOfPixels * (stream + 1) / numStreams;
      std::size_t count = end - begin;

      launchBrightness(d_input + begin, d_output + begin, count, brightness,
                       streams[stream]);
    }

    // submit every output transfer
    for (int stream = 0; stream < numStreams; ++stream) {
      std::size_t begin = noOfPixels * stream / numStreams;
      std::size_t end = noOfPixels * (stream + 1) / numStreams;
      std::size_t count = end - begin;

      CHECK_CUDA_ERROR(cudaMemcpyAsync(
          h_output + begin, d_output + begin, count * sizeof(unsigned char),
          cudaMemcpyDeviceToHost, streams[stream]));
    }

    for (int stream = 0; stream < numStreams; ++stream) {
      CHECK_CUDA_ERROR(cudaStreamSynchronize(streams[stream]));
    }
  }

  auto stop = std::chrono::steady_clock::now();
  return std::chrono::duration<double, std::milli>(stop - start).count() /
         repetitions;
}

int main(int argc, char **argv) {
  const std::size_t noOfPixels =
      (argc > 1) ? static_cast<std::size_t>(std::strtoull(argv[1], nullptr, 10))
                 : (64ULL * 1024 * 1024);

  const int brightness = 20;
  const int numStreams = 5; // 5chunks
  const int repetitions = 5;

  if (noOfPixels == 0 ||
      noOfPixels > static_cast<std::size_t>(INT_MAX) * 256ULL) {
    std::fprintf(stderr, "Invalid Image size\n");
    return EXIT_FAILURE;
  }

  int deviceId = 0;
  CHECK_CUDA_ERROR(cudaGetDevice(&deviceId));

  cudaDeviceProp deviceProp{};
  CHECK_CUDA_ERROR(cudaGetDeviceProperties(&deviceProp, deviceId));

  std::printf("GPU: %s\n", deviceProp.name);
  std::printf("Async copy engines: %d\n", deviceProp.asyncEngineCount);
  std::printf("Concurrent kernels: %d\n", deviceProp.concurrentKernels);
  std::printf("Image Size: %zu pixels (%zu bytes)\n", noOfPixels,
              noOfPixels * sizeof(unsigned char));
  std::printf("Streams: %d\n", numStreams);

  // pinning host inputs for async transfer so the os can't move or swap it out
  unsigned char *h_input = nullptr;
  unsigned char *h_output = nullptr;

  CHECK_CUDA_ERROR(
      cudaMallocHost(&h_input, noOfPixels * sizeof(unsigned char)));
  CHECK_CUDA_ERROR(
      cudaMallocHost(&h_output, noOfPixels * sizeof(unsigned char)));

  std::vector<unsigned char> correctAnswer(noOfPixels);

  // to store correct answer calculted by CPU to crosscheck against that of the
  // GPU
  for (std::size_t i = 0; i < noOfPixels; ++i) {
    h_input[i] = static_cast<unsigned char>((i * 37ULL + 13) % 256);
  }

  cpuBrightness(h_input, correctAnswer.data(), noOfPixels, brightness);

  unsigned char *d_input = nullptr;
  unsigned char *d_output = nullptr;

  CHECK_CUDA_ERROR(cudaMalloc(&d_input, noOfPixels * sizeof(unsigned char)));
  CHECK_CUDA_ERROR(cudaMalloc(&d_output, noOfPixels * sizeof(unsigned char)));

  // stream creation
  cudaStream_t streams[numStreams];
  for (int stream = 0; stream < numStreams; ++stream) {
    CHECK_CUDA_ERROR(
        cudaStreamCreateWithFlags(&streams[stream], cudaStreamNonBlocking));
  }

  // CUDA WARMING UP. CUDA CONTEXT INITIALIZATION before taking measurements,
  // don't know if the former cuda api calls won;t have init the contexr
  // already, gatz read up more on this
  CHECK_CUDA_ERROR(cudaFree(nullptr));

  std::printf("running for the synchronous approach");
  const double synchronousTimeMs =
      runSynchronous(h_input, h_output, d_input, d_output, noOfPixels,
                     brightness, repetitions);

  bool syncApproachOk =
      verify(h_output, correctAnswer, noOfPixels, "Sync Approach");
  std::printf("Average synchronous approach time: %.3f ms\n\n",
              synchronousTimeMs);

  printf("Running the interleaved streams........\n");
  const double interleavedMs =
      runInterleaved(h_input, h_output, d_input, d_output, noOfPixels,
                     brightness, streams, numStreams, repetitions);

  const bool interleavedOK =
      verify(h_output, correctAnswer, noOfPixels, "interleaved approach");

  std::printf("Interleaved average: %.3f ms\n\n", interleavedMs);

  std::printf("Running batched streams...\n");

  const double batchedMs =
      runBatched(h_input, h_output, d_input, d_output, noOfPixels, brightness,
                 streams, numStreams, repetitions);

  const bool batchedOK =
      verify(h_output, correctAnswer, noOfPixels, "batched approach");
  
  std::printf("Interleaved average: %.3f ms\n\n", batchedMs);

  std::printf("Speedups of stream approchs vs synchronous approach:\n");
  std::printf("  Interleaved: %.3fx\n", synchronousTimeMs / interleavedMs);
  std::printf("  Batched:     %.3fx\n", synchronousTimeMs / batchedMs);

  for (int stream = 0; stream < numStreams; ++stream) {
    CHECK_CUDA_ERROR(cudaStreamDestroy(streams[stream]));
  }

  CHECK_CUDA_ERROR(cudaFree(d_input));
  CHECK_CUDA_ERROR(cudaFree(d_output));
  CHECK_CUDA_ERROR(cudaFreeHost(h_input));
  CHECK_CUDA_ERROR(cudaFreeHost(h_output));

  return (syncApproachOk && interleavedOK && batchedOK) ? EXIT_SUCCESS
                                                        : EXIT_FAILURE;
}


/*' SAMPLE RESULT
 * 
 * 
 * GPU: Tesla T4
 Async copy engines: 3
 Concurrent kernels: 1
 Image Size: 67108864 pixels (67108864 bytes)
 Streams: 5
 running for the synchronous approach[Sync Approach] PASS: all 67108864 pixels match
 Average synchronous approach time: 12.163 ms
 
 Running the interleaved streams........
 [interleaved approach] PASS: all 67108864 pixels match
 Interleaved average: 7.311 ms
 
 Running batched streams...
 [batched approach] PASS: all 67108864 pixels match
 Interleaved average: 7.828 ms
 
 Speedups of stream approchs vs synchronous approach:
   Interleaved: 1.664x
   Batched:     1.554x
 */