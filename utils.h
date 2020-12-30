#include <ctime>
#include <cstdlib>
#include <cstdio>

using namespace std;

void generatePasswords(int numPasswords, string *passwordsArray) {
    char symbols[64] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
                        't', 'u', 'v', 'w', 'x', 'y', 'z',
                        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
                        'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '/'};


    srand(time(nullptr));

    for (int i = 0; i < numPasswords; i++) {
        string password;

        for (int currChar = 0; currChar < 8; currChar++)
            password += symbols[rand() % 64];

        passwordsArray[i] = password;

    }

}