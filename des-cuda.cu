#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdlib>
#include <cstdio>

#include "des.h"
#include "utils.h"
#include "cuda_utils.h"
#include "des_kernel.h"

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
    //generatePasswords(100, "plaintextPasswords.txt");
    int key_length;
    parse_args(argc, argv, &key_length);
    printf("Key length: %d \n", key_length);

    FILE *fPtr;
    fPtr = fopen("plaintextPasswords.txt", "r");
    if (fPtr == nullptr) {
        printf("Unable to read file!");
        exit(EXIT_FAILURE);
    }

    char plaintextPassword[8];
    fscanf(fPtr, "%s", plaintextPassword);
    fclose(fPtr);

    uint64_t passwordKey = *(uint64_t *) plaintextPassword;;
    uint64_t encodedPassword = full_des_encode_block(passwordKey, passwordKey);

    /* START CRACKING */
    _cudaSetDevice(0);

    clock_t start = clock();

    uint64_t crackedKey = 0;
    uint64_t encodedCrackedKey = 0;
    run_des_encode_block(crackedKey, crackedKey, &encodedCrackedKey);
    while (encodedCrackedKey != encodedPassword) {
        crackedKey++;
        encodedCrackedKey = full_des_encode_block(crackedKey, crackedKey);
        run_des_encode_block(crackedKey, crackedKey, &encodedCrackedKey);
    }

    clock_t end = clock();
    float seconds = (float) (end - start) / CLOCKS_PER_SEC;
    printf("key length: %d, seconds: %f\n", key_length, seconds);

    //bits_print_grouped(encoded,8,64);
    //bits_print_grouped(full_des_encode_block(cracked_key,block),8,64);
    return EXIT_SUCCESS;
}