#include <cuda_runtime.h>
#include <iostream>

__global__ void hello(){
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    printf("How y'all doing, just a random guy from thread with ID: %d\n", tid);
}

int main(){
    hello<<<2,2>>>();
    // wait for the previous gpu work to complete before the CPU continues
    cudaDeviceSynchronize();
    return 0;
}