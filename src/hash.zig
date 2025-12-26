const std = @import("std");
const blake3 = std.crypto.hash.Blake3;

// 32 -> Blake3

pub fn main() !void {
    var hasher = blake3.Hasher.init(std.heap.page_allocator);
    defer hasher.deinit(); // Crucial for resource management

const data = try std.fmt.allocBufferToString(std.heap.page_allocator, "hello zig");
    defer std.heap.page_allocator.free(data.ptr); // Free allocated data

try hasher.update(data);
    const hash = hasher.finalize();

try std.io.getStdOut().writer().print("BLAKE3 hash: {}\n", .{hash});
}
