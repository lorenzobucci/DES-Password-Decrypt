#include <ctime>
#include <cstdlib>
#include <cstdio>

void generatePasswords(int numPasswords) {
    char symbols[64] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
                        't', 'u', 'v', 'w', 'x', 'y', 'z',
                        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
                        'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '/'};

    FILE *fPtr;
    fPtr = fopen("plaintextPasswords.txt", "w");
    if (fPtr == NULL) {
        printf("Unable to create file!");
        exit(EXIT_FAILURE);
    }

    srand(time(0));

    for (int i = 0; i < numPasswords; i++) {
        char password[10];
        for (int currChar = 0; currChar < 8; currChar++) {
            password[currChar] = symbols[rand() % 64];
        }
        password[8] = '\n';
        password[9] = '\0';

        fputs(password, fPtr);
    }

    fclose(fPtr);
}