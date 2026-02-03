const std = @import("std");
const Config = @import("ds.zig").Config;

pub const RunArgs = struct {
    config: Config,
    command: []const []const u8,
};

pub fn parse(alloc: std.mem.Allocator) !RunArgs {
    var args = std.process.args();
    _ = args.next(); // skip program name

    // parse flags here
    // --root
    // --cache
    // etc

    const config = try parseConfig(alloc, /* parsed flags */);
    const command = try collectCommand(alloc, &args);

    return .{
        .config = config,
        .command = command,
    };
}

fn parseConfig(alloc: std.mem.Allocator, parsed: ParsedFlags) !Config {
    return Config{
        .abs_path = try alloc.dupe(u8, parsed.abs),
        .mount_path = try alloc.dupe(u8, parsed.mount),
        .wal_path = try std.fs.path.join(alloc, &.{ parsed.abs, ".kronos/wal" }),
        .merkle_path = try std.fs.path.join(alloc, &.{ parsed.abs, ".kronos/merkle.idx" }),
        .snap_path = try std.fs.path.join(alloc, &.{ parsed.abs, ".kronos/snap" }),
        .store_path = try std.fs.path.join(alloc, &.{ parsed.abs, ".kronos/chunks" }),
        .cache_size = parsed.cache orelse 512,
        .chunk_size = 64 * 1024,
    };
}
