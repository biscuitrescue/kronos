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
        switch (builtin.os.tag) {
            .linux => try linuxRun(alloc, cfg, argv),
            .windows => try windowsRun(alloc, cfg, argv),
        }
    }
};

fn linuxRun(alloc: std.mem.Allocator, cfg: SandboxConfig, argv: []const []const u8) !void {
    _ = alloc;
    _ = argv;
    _ = cfg;
}

fn windowsRun(alloc: std.mem.Allocator, cfg: SandboxConfig, argv: []const []const u8) !void {
    _ = alloc;
    _ = argv;
    _ = cfg;
}
