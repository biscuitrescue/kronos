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
    pub fn run(alloc: std.mem.Allocator, cfg: SandBox) !void {
        switch (builtin.os.tag) {
            .linux => try linuxRun(alloc, cfg),
            .windows => try windowsRun(alloc, cfg),
        }
    }
};

fn linuxRun(alloc: std.mem.Allocator, cfg: SandboxConfig) !void {
    _ = alloc;
    _ = cfg;
}

fn windowsRun(alloc: std.mem.Allocator, cfg: SandboxConfig) !void {
    _ = alloc;
    _ = cfg;
}
