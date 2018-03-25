#include <string.h>
#include <unistd.h>


#ifndef COMMAND
#error "Command is not defined!"
#endif


int main(int argc, char **argv) {
    char *slash;

    setuid(0);

    slash = strrchr(COMMAND, '/');
    if (slash) {
        argv[0] = slash + 1;
    } else {
        return 127;
    }

    execv(COMMAND, argv);
}