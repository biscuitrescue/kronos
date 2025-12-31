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
    ChildFailed,
    ForkFailed,
    ExecFailed,
};


pub const SandBox = struct {
    pub fn run(alloc: std.mem.Allocator, cfg: SandboxConfig, argv: []const []const u8) !void {
        // unnecessary exec on non linux / win machines

        if (builtin.os.tag != .linux) { return SandboxError.UnsupportedOS; }

        const pid = try std.os.linux.fork();

        if (pid == 0) {
            try std.os.linux.unshare(std.os.linux.CLONE.NEWNS);
            try std.os.linux.chroot(cfg.root_path);
            try std.os.chdir("/");

            var child = std.process.Child.init(argv, alloc);
            child.cwd = cfg.root_path;

            var env = std.process.EnvMap.init(alloc);
            defer env.deinit();
            child.env_map = &env;

            try env.put("PATH", "/usr/bin");

            try child.spawn();
            _ = try child.wait();

            std.os.linux.exit(0);
        }
        _ = try std.os.linux.waitpid(pid, 0);
    }
};
