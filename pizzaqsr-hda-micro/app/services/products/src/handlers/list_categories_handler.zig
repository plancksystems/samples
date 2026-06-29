
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const CategoryList = @import("../fragments/category_list.zig").CategoryList;
const Ctx = @import("../ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, _: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const categories = try repo.listCategories(ctx.client, allocator);
    defer allocator.free(categories);

    var out: std.ArrayList(u8) = .empty;
    try CategoryList.render(.{ .categories = categories }, &out, allocator);
    try res.html(out.items);
}
