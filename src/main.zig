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

const Determ_FS = struct {
    alloc: Allocator,
    config: Config,
    merkle: MerkleTree,
    hasher_pool: Blake3Pool,
    wal: WriteAheadLog,
    snap_idx: SnapIndex,
    cache: ChunkCache,

    log_clock: std.atomic.Value(u64),
    is_mounted: std.atomic.Value(bool),

    pub fn init(alloc: Allocator, config: Config) !@This() {
        // try ensure_directories(config);

        const cpu_count = std.Thread.getCpuCount() catch 4;
        const hasher_pool = try Blake3Pool.init(alloc, cpu_count);

        const merkle_tree = MerkleTree.load(
            alloc,
            config.merkle_path,
            ) catch |err| switch (err) {
            error.FileNotFound => try MerkleTree.create(alloc),
            else => return err,
        };

        const wal = try WriteAheadLog.init(alloc, config.wal_path);

        const snap_idx = try SnapIndex.load(
            alloc,
            config.snap_path,
            ) catch |err| switch (err) {
            error.FileNotFound => try SnapIndex.create(alloc),
            else => return err,
        };

        const cache = try ChunkCache.init(alloc, config.cache_size * 1024 * 1024);

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

const MerkleTree = struct {
    alloc: Allocator,
    root: ?*Node,
    path_to_node: std.StringHashMap(*Node),

    const Node = struct {};

    pub fn load(alloc: Allocator, path: []const u8) !@This() {
        const file = try std.fs.openFileAbsolute(path, .{});
        defer file.close();

        const tree: @This() = .{
            .alloc = alloc,
            .root = null,
            .path_to_node = std.StringHashMap(*Node).init(alloc),
        };

        return tree;
    }

    pub fn create(alloc: Allocator) !@This() {
        return .{
            .alloc = alloc,
            .root = null,
            .path_to_node = std.StringHashMap(*Node).init(),
        };
    }

    pub fn deinit(self: @This()) void {
        self.path_to_node.deinit();
    }
};

const WriteAheadLog = struct {
    alloc: Allocator,
    file: std.fs.File,
    buffer: std.ArrayList(u8),

    pub fn init(alloc: Allocator, path: []const u8) !@This() {
        const file = try std.fs.createFileAbsolute(path, .{
            .read = true,
            .truncate = false,
        });

        return .{
            .alloc = Allocator,
            .file = file,
            .buffer = std.ArrayList(u8).init(alloc),
        };
    }

    pub fn deinit(self: @This()) void {
      self.buffer.deinit();
      self.file.close();
    }

    pub fn verify(self: *@This()) !WALState {
        _ = self;
        return .clean;
    }

    pub fn getUncommittedOperations(self: *@This()) ![]Operation {
        _ = self;
        return &.{}; // Empty slice
    }

    pub fn getLastTimestamp(self: *@This()) !u64 {
        _ = self;
        return 0;
    }

    pub fn truncate(self: *@This(), index: u64) !void {
        _ = self;
        _ = index;
    }
};

const Operation = struct {};

const Blake3Pool = struct {
    pub fn init(alloc: Allocator, count: usize) !@This() {
        _ = alloc;
        _ = count;
    }

    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const SnapIndex = struct {
    pub fn load(allocator: Allocator, path: []const u8) !@This() {
        _ = allocator;
        _ = path;
        return .{};
    }
    pub fn create(allocator: Allocator) !@This() {
        _ = allocator;
        return .{};
    }
    pub fn deinit(self: *@This()) void {
        _ = self;
    }
};

const ChunkCache = struct {
    pub fn init(allocator: Allocator, size: usize) !@This() {
        _ = allocator;
        _ = size;
        return .{};
    }
    pub fn deinit(self: *@This()) void {
        _ = self;
    }
};

const WALState = union(enum) {
    clean,
    incomplete: u64,
    corrupted: []const u8,
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

fn ensureDirectories(config: Config) !void {
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

}
