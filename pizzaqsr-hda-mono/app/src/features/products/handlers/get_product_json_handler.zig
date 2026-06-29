
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const planck = @import("planck");

const Product = @import("../models/product.zig").Product;
const Ctx = @import("../../../core/ctx.zig").Ctx;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const id_str = req.getLocal("id") orelse return error.InvalidRequest;
    const id = std.fmt.parseInt(i32, id_str, 10) catch return error.InvalidRequest;

    var q = planck.Query.initWithAllocator(ctx.client, allocator);
    defer q.deinit();
    var resp = try q.store("products")
        .where("ProductID", .eq, .{ .int = id })
        .limit(1)
        .run();
    defer resp.deinit();

    const products = try resp.decode(allocator, Product);
    defer allocator.free(products);
    if (products.len == 0) return error.NotFound;

    const p = products[0];
    const body_json = try std.fmt.allocPrint(
        allocator,
        "{{\"product_id\":{d},\"name\":\"{s}\",\"base_price\":{d:.2}}}",
        .{ p.ProductID, p.Name, p.BasePrice },
    );
    try res.json(body_json);
}
