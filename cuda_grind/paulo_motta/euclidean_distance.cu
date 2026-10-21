
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <iostream>

/*
 * Practicing memory transfer
 */
struct Point {
  float x;
  float y;
  float z;
};

__global__ void calculateEuclideanDistance(Point *lineA, Point *lineB,
                                           float *distances, int numOfPoints) {
  int idx = threadIdx.x + blockIdx.x * blockDim.x;

  if (idx < numOfPoints) {
    float dx = lineA[idx].x - lineB[idx].x;
    float dy = lineA[idx].y - lineB[idx].y;
    float dz = lineA[idx].z - lineB[idx].z;

    distances[idx] = std::sqrt(dx * dx + dy * dy + dz * dz);
  }
}

int main() {
  int numOfPoints = 10'000'000;
  std::size_t sizeOfPoints = numOfPoints * sizeof(Point);
  std::size_t sizeOfDistances = numOfPoints * sizeof(float);

  // allocate and populate the host
  Point *h_lineA = (Point *)malloc(sizeOfPoints);
  Point *h_lineB = (Point *)malloc(sizeOfPoints);
  float *h_distances = (float *)malloc(sizeOfDistances);

  // fill up the array
  for (int i{0}; i < numOfPoints; ++i) {
    h_lineA[i].x = i * 1.0f;
    h_lineA[i].y = i * 2.0f;
    h_lineA[i].z = i * 3.0f;

    h_lineB[i].x = i * 0.5f;
    h_lineB[i].y = i * 1.5f;
    h_lineB[i].z = i * 2.5f;
  }

  // allocate memory and poulated device memory by copying fromthe host

  Point *d_lineA;
  Point *d_lineB;
  float *d_distances;

  cudaMalloc((void **)&d_lineA, sizeOfPoints);
  cudaMalloc((void **)&d_lineB, sizeOfPoints);
  cudaMalloc((void **)&d_distances, sizeOfDistances);

  // copy from host to device
  cudaMemcpy(d_lineA, h_lineA, sizeOfPoints, cudaMemcpyHostToDevice);
  cudaMemcpy(d_lineB, h_lineB, sizeOfPoints, cudaMemcpyHostToDevice);

  int blockSize = 1024;
  int gridSize = (numOfPoints + blockSize - 1) / blockSize;

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  cudaEventRecord(start);

  calculateEuclideanDistance<<<gridSize, blockSize>>>(d_lineA, d_lineB,
                                                      d_distances, numOfPoints);

  cudaEventRecord(stop);

  float gpuDuration = 0;
  cudaEventElapsedTime(&gpuDuration, start, stop);

  std::cout << "Time taken fro GPU:: " << gpuDuration << " ms" << std::endl;

  // copy result (distances) from device to host
  cudaMemcpy(h_distances, d_distances, sizeOfDistances, cudaMemcpyDeviceToHost);

  cudaFree(d_lineA);
  cudaFree(d_lineB);
  cudaFree(d_distances);

  free(h_lineA);
  free(h_lineB);
  free(h_distances);

  cudaEventDestroy(start);
  cudaEventDestroy(stop);

  return 0;
}
