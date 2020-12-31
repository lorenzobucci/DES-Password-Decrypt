#include <cstdlib>
#include <cstdio>
#include <string>
#include <random>

#include "des.h"
#include "utils.h"

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

void hackPassword(uint64_t encodedPassword, const char *passwordsList, unsigned int numOfPasswords, char *result) {

    uint64_t encodedCrackedKey = 0;
    char crackedPassword[8];

    for (unsigned int index = 0; index < numOfPasswords && encodedCrackedKey != encodedPassword; index++) {
        for (int i = 0; i < 8; i++)
            crackedPassword[i] = passwordsList[8 * index + i];

        uint64_t crackedKey = *(uint64_t *) crackedPassword;
        encodedCrackedKey = full_des_encode_block(crackedKey, crackedKey);
    }

    for (int currChar = 0; currChar < 8; currChar++)
        result[currChar] = crackedPassword[currChar];
    printf("Found %s!\n", result);

}


int main(int argc, char **argv) {

    unsigned int numberOfPasswords = 1 << 10;

    char *passwordsList = new char[8 * numberOfPasswords];
    generatePasswords(numberOfPasswords, passwordsList);

    int key_length;
    parse_args(argc, argv, &key_length);

    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> distrib(0, (numberOfPasswords) - 1);
    unsigned int randomIndex = distrib(gen) * 8;

    char *selectedPassword = &passwordsList[randomIndex];

    char _selectedPassword[9];
    for (int i = 0; i < 8; i++)
        _selectedPassword[i] = selectedPassword[i];
    _selectedPassword[8] = '\0';

    printf("Password to be hacked: %s\n", _selectedPassword);

    uint64_t passwordKey = *(uint64_t *) _selectedPassword;
    uint64_t encodedPassword = full_des_encode_block(passwordKey, passwordKey);

    /* START CRACKING */

    char foundPassword[9];
    foundPassword[8] = '\0';

    clock_t start = clock();

    hackPassword(encodedPassword, passwordsList, numberOfPasswords, foundPassword);

    clock_t end = clock();

    delete[] passwordsList;

    float seconds = (float) (end - start) / CLOCKS_PER_SEC;
    printf("Found password: %s in %f seconds\n"
           "Total number of passwords were: %d\n"
           "Cracked password had index: %d", foundPassword, seconds, numberOfPasswords, randomIndex / 8);

    return EXIT_SUCCESS;
}