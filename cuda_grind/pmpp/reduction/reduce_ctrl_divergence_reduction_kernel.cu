
/*
 * The former simple implementation has pooor warp usage utilization, as there
 * are active and inactive lanes, which leasds to resource wastage. so the
 * things is here, we try to utilize warp usage to the max in the early stage,
 * we will have to reorder our sum sequnence then,  so commutativity must also
 * be guaranteed, as our strifde is going to be the block dim, so say first
 * iter, stride = 8, sum goes like: t1+t9, t2+t10 .... All what we are doing
 * here is just better thread assignment in warps, this stillhas another
 * advantage, coalesced memory access, with a stride of 8 Thread:  T0 T1 T2 T3
 * T4 T5 T6 T7 accesses Index:    8  9 10 11 12 13 14 15, the threads a re
 * packed at the beginning of the block, and also the global memory request
 * reduce greatly
 */

__global__ void sum_red_ctrl_div_reduced(float *input, float *output) {
  unsigned int i = threadIdx.x;

  for (unsigned int stride = blockDim.x; stride >= 1; stride /= 2) {
    if (threadIdx.x < stride) {
      input[i] = input[i + stride];
    }

    __syncthreads();
  }

  if (threadIdx.x == 0) {
    *output = input[0];
  }
}
