#define _GNU_SOURCE
#include <sched.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

struct SandboxConfig {
  bool allow_net;
  // const uint8_t id[];
  const uint8_t root_path[];
};

static void die(const char *msg) {
  perror(msg);
  _exit(1);
}

int main(int argc, char **argv) {
  if (argc < 4) {
    fprintf(stderr, "usage: %s --root <path> -- <cmd> [args...]\n", argv[0]);
    return 1;
  }

  const char *root = NULL;
  int cmd_index = -1;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--root") == 0) {
      root = argv[++i];
    } else if (strcmp(argv[i], "--") == 0) {
      cmd_index = i + 1;
      break;
    }
  }

  if (!root || cmd_index < 0) {
    fprintf(stderr, "invalid arguments\n");
    return 1;
  }

  char **cmd = &argv[cmd_index];
}
