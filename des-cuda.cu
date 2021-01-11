#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdlib>
#include <cstdio>
#include <string>
#include <array>

#include "des.h"
#include "utils.h"
#include "cuda_utils.h"
#include "des_kernel.h"

using namespace std;

void parse_args(int argc, char **argv, int *key_length);

void usage(char *name);

void cudaCracking(unsigned int numberOfPasswords, const char *passwordsList, uint64_t encodedPassword);

void cpuCracking(unsigned int numberOfPasswords, const char *passwordsList, uint64_t encodedPassword);

void parse_args(int argc, char **argv, int *key_length) {
    if (argc < 2) {
        usage(argv[0]);
    }
    *key_length = atoi(argv[1]);
    if (*key_length <= 0 || *key_length > 64) {
        usage(argv[0]);
    }
}

void usage(char *name) {
    printf("Usage:\n %s key_length(1-64)\n", name);
    exit(EXIT_FAILURE);
}


int main(int argc, char **argv) {

    int key_length;
    parse_args(argc, argv, &key_length);

    /* PASSWORDS GENERATION */

    unsigned int numberOfPasswords = 1 << 20; // 2^20

    printf("Generating %d passwords...\n", numberOfPasswords);

    char *passwordsList = new char[8 * numberOfPasswords];
    generatePasswords(numberOfPasswords, passwordsList);

    /* PASSWORD SELECTION */

    array<unsigned int, 3> passwordIndexes = {0, numberOfPasswords / 2, numberOfPasswords - 1};

    for (unsigned int passwordIndex : passwordIndexes) {

        char *selectedPassword = &passwordsList[passwordIndex * 8];

        char _selectedPassword[9];
        for (int i = 0; i < 8; i++)
            _selectedPassword[i] = selectedPassword[i];
        _selectedPassword[8] = '\0';


        printf("\nPassword to be hacked: %s, with index %d\n\n", _selectedPassword, passwordIndex);

        uint64_t passwordKey = *(uint64_t *) _selectedPassword;
        uint64_t encodedPassword = full_des_encode_block(passwordKey, passwordKey);

        /* START CRACKING */

        printf("Trying to hack using CPU\n\n");
        for (int attempt = 0; attempt < 2; attempt++) {
            printf("Attempt %d of 2\n", attempt + 1);
            cpuCracking(numberOfPasswords, passwordsList, encodedPassword);
        }

        printf("\nTrying to hack using GPU\n\n");
        for (int attempt = 0; attempt < 2; attempt++) {
            printf("Attempt %d of 2\n", attempt + 1);
            cudaCracking(numberOfPasswords, passwordsList, encodedPassword);
        }

    }

    delete[] passwordsList;

    return EXIT_SUCCESS;
}

void cudaCracking(unsigned int numberOfPasswords, const char *passwordsList, uint64_t encodedPassword) {
    _cudaSetDevice(0);
    cudaMemcpyToSymbol(devEncodedPassword, &encodedPassword, sizeof(uint64_t));
    cudaMemcpyToSymbol(passwordsListSize, &numberOfPasswords, sizeof(unsigned int));

    char *devPasswordsList;
    _cudaMalloc((void **) &devPasswordsList, (numberOfPasswords) * 8 * sizeof(char));
    _cudaMemcpy(devPasswordsList, passwordsList, (numberOfPasswords) * 8 * sizeof(char), cudaMemcpyHostToDevice);

    int *devFoundFlag;
    _cudaMalloc((void **) &devFoundFlag, sizeof(int));
    _cudaMemset(devFoundFlag, 0, sizeof(int));

    char *devResult;
    _cudaMalloc((void **) &devResult, 9 * sizeof(char));

    dim3 dimGrid = 1 << 7; // 2^7
    dim3 dimBlock = 1 << 9; // 2^9

    clock_t start = clock();

    cudaHackPassword<<<dimGrid, dimBlock>>>(devPasswordsList, devFoundFlag, devResult);
    _cudaDeviceSynchronize("cudaHackPassword");

    clock_t end = clock();

    char foundPassword[9];
    foundPassword[8] = '\0';

    _cudaMemcpy(foundPassword, devResult, 8 * sizeof(char), cudaMemcpyDeviceToHost);
    cudaFree(devFoundFlag);
    cudaFree(devResult);
    cudaFree(devPasswordsList);

    float seconds = (float) (end - start) / CLOCKS_PER_SEC;
    printf("Found password: %s in %f seconds\n", foundPassword, seconds);
}

void cpuCracking(unsigned int numberOfPasswords, const char *passwordsList, uint64_t encodedPassword) {
    uint64_t encodedCrackedKey = 0;
    char crackedPassword[8];

    clock_t start = clock();

    for (unsigned int index = 0; index < numberOfPasswords && encodedCrackedKey != encodedPassword; index++) {
        for (int i = 0; i < 8; i++)
            crackedPassword[i] = passwordsList[8 * index + i];

        uint64_t crackedKey = *(uint64_t *) crackedPassword;
        encodedCrackedKey = full_des_encode_block(crackedKey, crackedKey);
    }

    clock_t end = clock();

    char foundPassword[9];
    for (int i = 0; i < 8; i++)
        foundPassword[i] = crackedPassword[i];
    foundPassword[8] = '\0';

    float seconds = (float) (end - start) / CLOCKS_PER_SEC;
    printf("Found password: %s in %f seconds\n", foundPassword, seconds);

}
