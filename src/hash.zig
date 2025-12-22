const std = @import("std");
const blake3 = std.crypto.hash.Blake3;

// 32 -> Blake3
pub const Hash = [32]u8;

pub fn hasher(data: []const u8) Hash {
    var out: Hash = undefined;
    blake3.hash(data, &out, .{});
    return out;
}

test "determ" {
    const h1 = blake3("hello");
    const h2 = blake3("hello");
    try std.testing.expect(std.mem.eql(u8, &h1, &h2));
}
