const std = @import("std");
const builtin = @import("builtin");

const SandboxConfig = struct {
    id: []const u8,
    root_path: []const u8,
    allow_net: bool,
    ro_paths: []const []const u8,
    hidden_paths: []const []const u8,
};

const SandboxError = error {
    UnsupportedOS,
    ForkFailed,
    ExecFailed,
};


pub const SandBox = struct {
    pub fn run(cfg: SandboxConfig, argv: []const []const u8) !void {

        if (builtin.os.tag != .linux) { return SandboxError.UnsupportedOS; }

        const pid = std.os.linux.fork();
        if (pid < 0) { return SandboxError.ForkFailed; }

        if (pid == 0) {
            try std.os.linux.unshare(std.os.linux.CLONE.NEWNS);

            try std.os.linux.mount(null, "/", null, std.os.linux.MS.REC | std.os.linux.MS.PRIVATE, null);


            try std.os.linux.chroot(cfg.root_path);
            try std.os.chdir("/");

            var env = [_:null]?[*:0]const u8 {
                "PATH=/usr/bin",
                null,
            };
            defer env.deinit();

            std.os.linux.execve(argv[0], argv, &env)
                catch {
                    std.os.linux.execve(127);
            };


        }
        _ = try std.os.linux.waitpid(pid, 0);
    }
};
