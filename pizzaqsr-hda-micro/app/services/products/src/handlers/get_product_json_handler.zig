
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const id_str = req.getLocal("id") orelse return error.InvalidRequest;
    const id = std.fmt.parseInt(i32, id_str, 10) catch return error.InvalidRequest;

    const product = try repo.getProduct(ctx.client, allocator, id) orelse return error.NotFound;

    const body_json = try std.fmt.allocPrint(
        allocator,
        "{{\"product_id\":{d},\"name\":\"{s}\",\"base_price\":{d:.2}}}",
        .{ product.ProductID, product.Name, product.BasePrice },
    );
    try res.json(body_json);
}
