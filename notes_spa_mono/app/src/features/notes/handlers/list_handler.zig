
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const repo = @import("../repo.zig");
const Note = @import("../models/note.zig").Note;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, _: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const notes = try repo.NoteModel.find(ctx.client, allocator, .{});
    defer if (notes.len > 0) allocator.free(notes);

    const body = try std.json.Stringify.valueAlloc(allocator, notes, .{});
    try res.json(body);
}
