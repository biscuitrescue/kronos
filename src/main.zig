const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = struct {
    abs_path: []const u8,
    mount_path: []const u8,
    wal_path: []const u8,
    merkle_path: []const u8,
    snap_path: []const u8,
    store_path: []const u8,
    cache_size: usize,
    chunk_size: usize,
};

fn parse_config(alloc: Allocator, args: anytype) !Config {
    return Config {
        .abs_path = try alloc.dupe(u8, args.abs),
        .mount_path = try alloc.dupe(u8, args.mount),
        .wal_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/wal"}),
        .merkle_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/merkle.idx"}),
        .snap_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/snap"}),
        .store_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/chunks"}),
        .cache_size = args.cache orelse 512,
        .chunk_size = 64 * 1024,
    };
}

pub fn main() !void {

}
