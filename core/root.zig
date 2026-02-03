const std = @import("std");

const Cli = @import("cli.zig");
const Engine = @import("engine.zig").Engine;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const args = try Cli.parse(alloc);
    var engine = try Engine.init(alloc, args.config);
    defer engine.deinit();

    try engine.run(args);
}
