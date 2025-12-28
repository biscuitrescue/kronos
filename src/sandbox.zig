const std = @import("std");

const SandboxConfig = struct {
    id: []const u8,
    root_path: []const u8,
    allow_netw: bool,
    read_only_paths: [][]const u8,
    hidden_paths: [][]const u8,
};

