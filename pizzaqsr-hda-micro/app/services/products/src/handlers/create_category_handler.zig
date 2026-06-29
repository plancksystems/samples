
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const CreateCategoryBody = @import("../models/product.zig").CreateCategoryBody;
const Ctx = @import("../ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const body = try req.getBody(allocator, CreateCategoryBody);

    try repo.createCategory(ctx.client, allocator, body);

    try res.html("<span>Category created</span>");
}
