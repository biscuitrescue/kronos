const std = @import("std");
const Config = @import("ds.zig").Config;

pub const RunArgs = struct {
    config: Config,
    command: []const []const u8,
};

pub fn parse(alloc: std.mem.Allocator) !RunArgs {
    _ = alloc;

    // placeholder
    return RunArgs{
        .config = undefined,
        .command = &.{ "/bin/echo", "hello" },
    };
}
