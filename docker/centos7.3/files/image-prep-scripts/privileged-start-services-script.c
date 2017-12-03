#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>

#ifndef COMMAND
#error "Command is not defined!"
#endif

#define SETUP_TASK_UNSET "<unset>"

#ifndef SETUP_TASK
#define SETUP_TASK SETUP_TASK_UNSET
#endif

int main() {
  printf("Pre setuid. UID=%d, EUID=%d, SETUP_TASK=%s, COMMAND=%s\n", getuid(), geteuid(), SETUP_TASK, COMMAND);
  setuid(0);
  printf("Post setuid. UID=%d , EUID=%d, SETUP_TASK=%s, COMMAND=%s\n", getuid(), geteuid(), SETUP_TASK, COMMAND);

  if (strcmp(SETUP_TASK, SETUP_TASK_UNSET) != 0) {
    printf("Executing setup task: %s\n", SETUP_TASK);
    int exit_code = system(SETUP_TASK);

    if (exit_code !=0) {
      printf("Setup task failed! Exiting...\n");
      exit(-1);
    }
  }

  /** We should exec here so that our process can indeed be PID 1 */
  execl(COMMAND, COMMAND, (char*) NULL);
}
