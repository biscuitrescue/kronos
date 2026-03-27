#define _GNU_SOURCE
#include <unistd.h>
#include <sched.h>
#include <seccomp.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/prctl.h>


/*
Sandbox
 ---- SandboxProcess       - what to run
 ---- SandboxLimits        - how many resource it can use
 ---- SandboxFilesystem    - what files it can see
 ---- SandboxSyscallPolicy - what syscalls it is allowed
 ---- SandboxNetworkPolicy - what network it can reach
 ---- SandboxNamespaces    - what os namespace to isolate
 ---- SandboxIPC           - process talking
 ---- SandboxResult        - what happened after it ran
*/


typedef struct {
    pid_t pid;
    uid_t uid;
    gid_t gid;
    char *executable;
    char **argv;
    char **envp;
} SandboxProcess;

typedef struct {
    struct rlimit cpu;
    struct rlimit memory;
    struct rlimit fsize;
    struct rlimit nofile;
    struct rlimit nproc;
} SandboxLimits;

typedef struct {
    int use_pid_ns;
    int use_net_ns;
    int use_mnt_ns;
    int use_ipc_ns;
    int use_uts_ns;
} SandboxNamespaces;

typedef struct {
    char *root_dir;
    int use_tmpfs;
} SandboxFilesystem;

typedef enum { SYSCALL_ALLOW, SYSCALL_DENY, SYSCALL_LOG } SyscallAction;

typedef struct {
    int syscall_nr;
    SyscallAction action;
} SyscallRule;

typedef struct {
    SyscallRule *rules;
    int rule_count;
    SyscallAction default_action;
} SandboxSyscallPolicy;

typedef struct {
    int stdin_fd;
    int stdout_fd;
    int stderr_fd;
} SandboxIPC;

typedef struct {
    int exit_code;
    int killed_by_signal;
    int signal_num;
    long wall_time_ms;
    long cpu_time_ms;
    long memory_used_kb;
    int oom_killed;
    int tle;
} SandboxResult;

typedef struct {
    SandboxProcess process;
    SandboxLimits limits;
    SandboxNamespaces namespaces;
    SandboxFilesystem filesystem;
    SandboxSyscallPolicy syscall_policy;
    SandboxIPC ipc;
    SandboxResult result;
    int debug;
} Sandbox;
