const std = @import("std");
const Config = @import("ds.zig").Config;

pub const RunArgs = struct {
    config: Config,
    command: []const []const u8,
};

const ParsedFlags = struct {
    root: []const u8,
    cache_mb: ?usize = null,
};

const CliError = error{
    MissingRoot,
    MissingCacheValue,
    MissingCommand,
    UnknownFlag,
};

pub fn parse(alloc: std.mem.Allocator) !RunArgs {
    var args = std.process.args();
    _ = args.next(); // program name

    var parsed_flags = ParsedFlags{ .root = try args.next() orelse return error.MissingRoot };

    if (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--cache=")) {
            parsed_flags.cache_mb = try std.fmt.parseInt(usize, arg[8..], 10);
        } else {
            return error.UnknownFlag;
        }
    }

    const config = try parse_config(alloc, parsed_flags);
    const command = try collectCommand(alloc, &args);

    return .{
        .config = config,
        .command = command,
    };
}

fn parse_config(alloc: std.mem.Allocator, parsed: ParsedFlags) !Config {
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

fn collectCommand(alloc: std.mem.Allocator, args: *std.process.ArgIterator) ![]const []const u8 {
    var command = std.ArrayList([]const u8).init(alloc);
    while (args.next()) |arg| {
        try command.append(arg);
    }
    return command.toOwnedSlice();
}
