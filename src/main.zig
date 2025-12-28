const std = @import("std");
const Config = @import("ds").Config;
const Allocator = std.mem.Allocator;

fn parse_config(alloc: Allocator, args: anytype) !Config {
    return Config{
        .abs_path = try alloc.dupe(u8, args.abs),
        .mount_path = try alloc.dupe(u8, args.mount),
        .wal_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/wal" }),
        .merkle_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/merkle.idx" }),
        .snap_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/snap" }),
        .store_path = try std.fs.path.join(alloc, &.{ args.abs, ".kronos/chunks" }),
        .cache_size = args.cache orelse 512,
        .chunk_size = 64 * 1024,
    };
}

fn ensureDirectories(config: Config) !void {
    // std.fs.path.dirname now returns ?[]const u8
    const wal_dir = std.fs.path.dirname(config.wal_path) orelse ".";
    const merkle_dir = std.fs.path.dirname(config.merkle_index_path) orelse ".";

    const paths = [][]const u8{
        wal_dir,
        merkle_dir,
        config.snapshot_path,
        config.chunk_store_path,
    };

    for (paths) |path| {
        std.fs.makeDirAbsolute(path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
}

pub fn recover(self: *@This()) !void {
    std.log.info("Starting recovery process...", .{});

    const wal_state = try self.wal.verify();

    switch (wal_state) {
        .clean => {
            std.log.info("WAL is clean", .{});
        },
        .incomplete => |last_valid_index| {
            std.log.warn("WAL has incomplete transaction, rolling back to {}", .{last_valid_index});
            try self.wal.truncate(last_valid_index);
        },
        .corrupted => |details| {
            std.log.err("WAL corruption detected: {s}", .{details});
            return error.WALCorrupted;
        },
    }

    const uncommitted_ops = try self.wal.getUncommittedOperations();
    defer self.allocator.free(uncommitted_ops);

    if (uncommitted_ops.len > 0) {
        std.log.info("Replaying {} uncommitted operations", .{uncommitted_ops.len});

        for (uncommitted_ops) |op| {
            try self.replayOperation(op);
        }
    }

    const last_timestamp = try self.wal.getLastTimestamp();
    self.logical_clock.store(last_timestamp + 1, .monotonic);

    std.log.info("Recovery complete. Logical clock at {}", .{self.logical_clock.load(.monotonic)});
}

pub fn mount(self: *@This()) !void {
    // swap returns the previous value
    if (self.is_mounted.swap(true, .acquire)) {
        return error.AlreadyMounted;
    }

    errdefer self.is_mounted.store(false, .release);

    try self.recover();

    // @import("builtin") still works in 0.15.2
    switch (@import("builtin").os.tag) {
        .linux => try self.mountFuse(),
        .windows => try self.mountDokan(),
        else => return error.UnsupportedPlatform,
    }

    std.log.info("Mounted deterministic FS at {s}", .{self.config.mount_point});
}

pub fn main() !void {
    std.debug.print("Program is compiling ;)", .{});
}
