#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdint>
#include "cuda_utils.h"
#include "bit_utils.h"
#include "c_utils.h"
#include "des.h"

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

__global__ void cudaHackPassword(const char *passwordsList, int *foundFlag, char *result) {
    unsigned int currentIndex = blockIdx.x * blockDim.x + threadIdx.x;
    bool reachedLimit = false;

    while (*foundFlag == 0 && !reachedLimit) {
        uint64_t encodedCrackedKey = 0;
        char crackedPassword[8];
        for (int i = 0; i < 8; i++)
            crackedPassword[i] = passwordsList[8 * currentIndex + i];

        uint64_t crackedKey = *(uint64_t *) crackedPassword;
        cudaDesEncodeBlock(crackedKey, crackedKey, &encodedCrackedKey);

        if (encodedCrackedKey == devEncodedPassword) {
            atomicCAS(foundFlag, 0, 1);
            for (int currChar = 0; currChar < 8; currChar++)
                result[currChar] = crackedPassword[currChar];
            printf("Found %s!\n", result);
        }
        __threadfence();

        (currentIndex + gridDim.x * blockDim.x) > passwordsListSize ? reachedLimit = true : currentIndex += gridDim.x *
                                                                                                            blockDim.x;

    }

}