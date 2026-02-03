const std = @import("std");
const Print = std.debug.print;

pub fn run(
    alloc: std.mem.Allocator,
    root_path: []const u8,
    argv: []const []const u8,
) !void {
    var full_argv = std.ArrayList([]const u8).init(alloc);
    defer full_argv.deinit();

    try full_argv.append("kr_sb");
    try full_argv.append("--root_path");
    try full_argv.append(root_path);
    try full_argv.append("--");

    for (argv) |arg| {
        try full_argv.append(arg);
    }

    try std.process.execv(alloc, full_argv.items);
}
