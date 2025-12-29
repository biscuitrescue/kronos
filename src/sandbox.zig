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
    pub fn run(alloc: std.mem.Allocator, cfg: SandBox, argv: []const []const u8) !void {
        // Error on non linux/win (mac)
        var child = std.process.Child.init(argv, alloc);
        child.cwd = cfg.root_path;
        child.env_map = std.process.EnvMap.init(alloc);

        switch (builtin.os.tag) {
            .linux => try child.env_map.put("PATH", "/usr/bin"),
            .windows => try child.env_map.put("PATH", "C:\\Windows\\System32"),
            else => return std.log.err("undefined OS", .{}),
        }

        try child.spawn();
        _ = try child.wait();
    }
};
