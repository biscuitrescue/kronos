const std = @import("std");
const Allocator = std.mem.Allocator;

const Config = @import("ds.zig").Config;
const RunArgs = @import("cli.zig").RunArgs;
const StateStore = @import("ds.zig").StateStore;
const Sandbox = @import("sandbox.zig");

const Engine = struct {
    alloc: std.mem.Allocator,
    config: Config,
    fs: StateStore,

    pub fn init(
        alloc: std.mem.Allocator,
        config: Config,
        fs: StateStore,
    ) !Engine {
        return .{
            .alloc = alloc,
            .config = config,
            .fs = fs,
        };
    }

    pub fn deinit(self: *Engine) !void {
        self.fs.deinit();
        self.config.deinit();
    }

    pub fn run(self: *Engine, args: RunArgs) !void {
        try self.recover();

        try Sandbox.run(
            self.alloc,
            self.config.mount_path,
            args.command,
        );

        try self.fs.commit();
    }

    pub fn recover(self: *Engine) !void {
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
};
