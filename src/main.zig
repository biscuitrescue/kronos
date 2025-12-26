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

const Determ_FS = struct {
    alloc: Allocator,
    config: Config,
    merkle: MerkleTree,
    hasher_pool: Blake3Pool,
    wal: WriteAheadLog,
    snap_index: SnapIndex,
    cache: ChunkCache,

    log_clock: std.atomic.Value(u64),
    is_mounted: std.atomic.Value(bool),

    // pub fn init(alloc: Allocator, config: Config)
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
            .path_to_node = std.StringHashMap(*Node).deinit(),
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
const WALState = struct {};

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

pub fn main() !void {

}
