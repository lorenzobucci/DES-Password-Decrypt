#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdint>
#include "cuda_utils.h"
#include "bit_utils.h"
#include "c_utils.h"
#include "des.h"

__device__ void cudaDesEncodeBlock(uint64_t block, uint64_t key, uint64_t *encoded);

void runDesEncodeBlock(uint64_t key, uint64_t block, uint64_t *result);

__global__ void cudaHackPassword(int *foundFlag, uint64_t *result);


__device__ void cudaDesEncodeBlock(uint64_t block, uint64_t key, uint64_t *encoded) {
    uint64_t keys[16];
    des_create_subkeys(key, keys);
    uint64_t result = des_encode_block(block, keys);
    *encoded = result;
}

void runDesEncodeBlock(uint64_t key, uint64_t block, uint64_t *result) {
    uint64_t *dev_result;
    _cudaMalloc((void **) &dev_result, sizeof(uint64_t));

    //cudaDesEncodeBlock<<<1, 1>>>(block, key, dev_result);
    _cudaDeviceSynchronize("cudaDesEncodeBlock");

    _cudaMemcpy(result, dev_result, sizeof(uint64_t), cudaMemcpyDeviceToHost);
    cudaFree(dev_result);
}

__global__ void cudaHackPassword(int *foundFlag, uint64_t *result) {
    uint64_t crackedKey = blockIdx.x * blockDim.x + threadIdx.x;
    uint64_t encodedCrackedKey = 0;
    bool overflow = false;

    while (*foundFlag == 0 && !overflow) {
        cudaDesEncodeBlock(crackedKey, crackedKey, &encodedCrackedKey);

        /*if(blockIdx.x * blockDim.x + threadIdx.x != crackedKey)
            printf("Thread %d is on key %llu\n", blockIdx.x * blockDim.x + threadIdx.x, crackedKey);*/

        if (encodedCrackedKey == devEncodedPassword) {
            atomicCAS(foundFlag, 0, 1);
            *result = crackedKey;
            printf("Found!\n");
        }
        __threadfence();

        (crackedKey + gridDim.x * blockDim.x) > crackedKey ? crackedKey += gridDim.x * blockDim.x : overflow = true;
    }

}