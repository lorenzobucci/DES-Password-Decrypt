#include <ctime>
#include <cstdlib>
#include <cstdio>
#include <random>

using namespace std;

void generatePasswords(unsigned int numPasswords, char *passwordsArray) {
    char symbols[64] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
                        't', 'u', 'v', 'w', 'x', 'y', 'z',
                        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
                        'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '/'};


    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> distrib(0, 63);

    for (unsigned int i = 0; i < numPasswords; i++) {
        for (int currChar = 0; currChar < 8; currChar++)
            passwordsArray[i * 8 + currChar] = symbols[distrib(gen)];
    }
}