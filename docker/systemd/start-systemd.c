#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <string.h>
#define COMMAND "/bootstrap/centos7-systemd.sh"

int main(int argc, char **argv) {
  printf("Pre setuid. UID=%d, EUID=%d, COMMAND=%s\n", getuid(), geteuid(), COMMAND);
  setuid(0);
  printf("Post setuid. UID=%d , EUID=%d, COMMAND=%s\n", getuid(), geteuid(), COMMAND);

  return execv(COMMAND, argv);
}
