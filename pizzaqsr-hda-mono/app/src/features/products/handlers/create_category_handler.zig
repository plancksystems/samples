
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const planck = @import("planck");

const Category = @import("../models/product.zig").Category;
const CreateCategoryBody = @import("../models/product.zig").CreateCategoryBody;
const Ctx = @import("../../../core/ctx.zig").Ctx;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const body = try req.getBody(allocator, CreateCategoryBody);

    const category = Category{ .Name = body.Name, .Description = body.Description };
    var q = planck.Query.initWithAllocator(ctx.client, allocator);
    defer q.deinit();
    var resp = try (try q.store("categories").create(category)).run();
    defer resp.deinit();

    try res.html("<span>Category created</span>");
}
