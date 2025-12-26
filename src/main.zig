const std = @import("std");
const ds = @import("ds.zig");

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

const Determ_FS = struct {
    alloc: ds.Allocator,
    config: ds.Config,
    merkle: ds.MerkleTree,
    hasher_pool: ds.Blake3Pool,
    wal: ds.WriteAheadLog,
    snap_idx: ds.SnapIndex,
    cache: ds.ChunkCache,

    log_clock: std.atomic.Value(u64),
    is_mounted: std.atomic.Value(bool),

    pub fn init(alloc: ds.Allocator, config: ds.Config) !@This() {
        // try ensure_directories(config);

        const cpu_count = std.Thread.getCpuCount() catch 4;
        const hasher_pool = try ds.Blake3Pool.init(alloc, cpu_count);

        const merkle_tree = ds.MerkleTree.load(
            alloc,
            config.merkle_path,
        ) catch |err| switch (err) {
            error.FileNotFound => try ds.MerkleTree.create(alloc),
            else => return err,
        };

        const wal = try ds.WriteAheadLog.init(alloc, config.wal_path);

        const snap_idx = try ds.SnapIndex.load(
            alloc,
            config.snap_path,
        ) catch |err| switch (err) {
            error.FileNotFound => try ds.SnapIndex.create(alloc),
            else => return err,
        };

        const cache = try ds.ChunkCache.init(alloc, config.cache_size * 1024 * 1024);

        return .{
            .alloc = alloc,
            .config = config,
            .merkle_tree = merkle_tree,
            .hasher_pool = hasher_pool,
            .wal = wal,
            .snap_idx = snap_idx,
            .cache = cache,
            .log_clock = std.atomic.Value(u64).init(0),
            .is_mounted = std.atomic.Value(bool).init(false),
        };
    }

    pub fn deinit(self: @This()) void {
        self.cache.deinit();
        self.snap_idx.deinit();
        self.wal.deinit();
        self.merkle_tree.deinit();
        self.hasher_pool.deinit();
    }
};

fn parse_config(alloc: ds.Allocator, args: anytype) !Config {
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

fn ensureDirectories(config: ds.Config) !void {
    // std.fs.path.dirname now returns ?[]const u8
    const wal_dir = std.fs.path.dirname(config.wal_path) orelse ".";
    const merkle_dir = std.fs.path.dirname(config.merkle_index_path) orelse ".";

    const paths = [_][]const u8{
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
