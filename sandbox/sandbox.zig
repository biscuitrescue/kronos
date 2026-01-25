const std = @import("std");
const builtin = @import("builtin");

const SandboxConfig = struct {
    id: []const u8,
    root_path: []const u8,
    allow_net: bool,
    ro_paths: [][]const u8,
    hidden_paths: [][]const u8,
};

pub const SandBox = struct {
    pub fn run(alloc: std.mem.Allocator, cfg: SandboxConfig, argv: []const []const u8) !void {
        // unnecessary exec on non linux / win machines

        try std.os.linux.unshare(std.os.linux.CLONE.NEWNS);
        try std.os.chdir(cfg.root_path);
        try std.os.linux.chroot(cfg.root_path);

        var child = std.process.Child.init(argv, alloc);
        child.cwd = cfg.root_path;

        var env = std.process.EnvMap.init(alloc);
        child.env_map = &env;

        switch (builtin.os.tag) {
            .linux => try child.env_map.put("PATH", "/usr/bin"),
            .windows => try child.env_map.put("PATH", "C:\\Windows\\System32"),
            else => return error.UnsupportedOS,
        }

        try child.spawn();
        const term = try child.wait();

        if (term != .Exited or term.Exited != 0) {
            std.log.err("Child process exited with code {}", .{term.Exited.code});
        }
    }
};
