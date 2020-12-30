#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdlib>
#include <cstdio>
#include <string>
#include <random>

#include "des.h"
#include "utils.h"
#include "cuda_utils.h"
#include "des_kernel.h"

using namespace std;

void parse_args(int argc, char **argv, int *key_length);

void usage(char *name);

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

    int numberOfPasswords = 1 << 20;

    string *passwordsList = new string[numberOfPasswords];
    generatePasswords(numberOfPasswords, passwordsList);

    int key_length;
    parse_args(argc, argv, &key_length);
    printf("Key length: %d \n", key_length);

    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> distrib(0, (numberOfPasswords) - 1);

    string selectedPassword = passwordsList[distrib(gen)];

    char _selectedPassword[9];
    for (int i = 0; i < selectedPassword.size(); i++)
        _selectedPassword[i] = selectedPassword[i];
    _selectedPassword[8] = '\0';

    printf("Password to be hacked: %s\n", _selectedPassword);

    uint64_t passwordKey = *(uint64_t *) _selectedPassword;
    uint64_t encodedPassword = full_des_encode_block(passwordKey, passwordKey);

    /* START CRACKING */
    _cudaSetDevice(0);
    cudaMemcpyToSymbol(devEncodedPassword, &encodedPassword, sizeof(uint64_t));
    cudaMemcpyToSymbol(passwordsListSize, &numberOfPasswords, sizeof(int));

    char *devPasswordsList;
    _cudaMalloc((void **) &devPasswordsList, (numberOfPasswords) * 8 * sizeof(char));
    for (int i = 0; i < numberOfPasswords; i++)
        _cudaMemcpy(&devPasswordsList[i * 8], passwordsList[i].c_str(), 8 * sizeof(char), cudaMemcpyHostToDevice);

    int *devFoundFlag;
    _cudaMalloc((void **) &devFoundFlag, sizeof(int));
    _cudaMemset(devFoundFlag, 0, sizeof(int));

    char *devResult;
    _cudaMalloc((void **) &devResult, 9 * sizeof(char));

    dim3 dimGrid = 1 << 7; //2^7
    dim3 dimBlock = 1 << 9; //2^9

    clock_t start = clock();

    cudaHackPassword<<<dimGrid, dimBlock>>>(devPasswordsList, devFoundFlag, devResult);
    _cudaDeviceSynchronize("cudaHackPassword");

    clock_t end = clock();

    char foundPassword[9];
    foundPassword[8] = '\0';

    _cudaMemcpy(&foundPassword, devResult, 8 * sizeof(char), cudaMemcpyDeviceToHost);
    cudaFree(devFoundFlag);
    cudaFree(devResult);
    cudaFree(devPasswordsList);

    float seconds = (float) (end - start) / CLOCKS_PER_SEC;
    printf("Found password: %s, seconds: %f\n", foundPassword, seconds);

    return EXIT_SUCCESS;
}