
const std = @import("std");

pub const Note = struct {
    NoteID: i64 = 0,
    Title: []const u8 = "",
    Body: []const u8 = "",
    Tags: []const u8 = "",
    CreatedAt: i64 = 0,
    UpdatedAt: i64 = 0,
};
