#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include <stdio.h>

#include "c_utils.h"
#include "des.h"
#include "des_utils.h"
#include "bit_utils.h"
#include "des_consts.h"
#include "des_kernel.h"
#include "cuda_utils.h"

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
    int key_length;
    parse_args(argc, argv, &key_length);
    printf("Key length: %d \n", key_length);
    uint64_t key = des_generate_key();
    uint64_t block = key; //0x0123456789ABCDEF;
    uint64_t encoded = full_des_encode_block(key, block);

    //_cudaSetDevice(0);

    printf("Real key:\n");
    bits_print_grouped(key, 8, 64);
    printf("Encoded block:\n");
    bits_print_grouped(encoded, 8, 64);
    printf("Cracking...\n");
    uint64_t cracked_key = key - 5;

    clock_t start = clock();
    for (int i = 0; i < 10; i++) {
        uint64_t decrypted_block = 0;
        //run_des_encode_block(cracked_key, block, &decrypted_block);
        decrypted_block = full_des_encode_block(cracked_key, cracked_key);
        if (decrypted_block == encoded) {
            printf("Found !! iteration: %d\n", i);
            printf("Cracked key:\n");
            bits_print_grouped(cracked_key, 8, 64);
            printf("Cracked block:\n");
            bits_print_grouped(decrypted_block, 8, 64);
        }
        cracked_key++;
    }

    clock_t end = clock();
    float seconds = (float) (end - start) / CLOCKS_PER_SEC;
    printf("key length: %d, seconds: %f\n", key_length, seconds);

    //bits_print_grouped(encoded,8,64);
    //bits_print_grouped(full_des_encode_block(cracked_key,block),8,64);
    return EXIT_SUCCESS;
}
