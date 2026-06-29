
const std = @import("std");

pub fn parseStringField(allocator: std.mem.Allocator, body: []const u8, field: []const u8) ![]const u8 {
    var needle_buf: [128]u8 = undefined;
    if (field.len + 3 > needle_buf.len) return error.FieldNameTooLong;
    needle_buf[0] = '"';
    @memcpy(needle_buf[1..][0..field.len], field);
    needle_buf[1 + field.len] = '"';
    const needle = needle_buf[0 .. 2 + field.len];

    const start = std.mem.indexOf(u8, body, needle) orelse return error.FieldMissing;
    var i = start + needle.len;
    while (i < body.len and (body[i] == ' ' or body[i] == ':')) i += 1;
    if (i >= body.len or body[i] != '"') return error.FieldNotString;
    i += 1;
    const value_start = i;
    while (i < body.len and body[i] != '"') i += 1;
    if (i >= body.len) return error.UnterminatedString;
    return try allocator.dupe(u8, body[value_start..i]);
}
