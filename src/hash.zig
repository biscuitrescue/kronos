const std = @import("std");
const blake3 = std.crypto.hash.Blake3;

pub const Hash = [32]u8;

pub fn hasher(data: []const u8) Hash {
    var out: Hash = undefined;
    blake3.hash(data, &out, .{});
    return out;
}
