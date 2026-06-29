
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const db_setup = @import("../../../core/db_setup.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, _: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const store_counts = db_setup.setupSchema(ctx.client);
    const index_counts = db_setup.createIndexes(ctx.client);

    const body = try std.fmt.allocPrint(allocator,
        "{{\"success\":true," ++
            "\"stores\":{{\"created\":{d},\"skipped\":{d}}}," ++
            "\"indexes\":{{\"created\":{d},\"skipped\":{d}}}" ++
            "}}",
        .{
            store_counts.created, store_counts.skipped,
            index_counts.created, index_counts.skipped,
        });
    defer allocator.free(body);

    try res.json(body);
}
