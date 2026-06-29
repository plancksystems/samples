
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const planck = @import("planck");

const Product = @import("../models/product.zig").Product;
const ProductDetail = @import("../fragments/product_detail.zig").ProductDetail;
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

    if (products.len == 0) {
        try res.html(
            \\<div class="p-8 text-center">
            \\  <h2 class="text-lg font-semibold text-slate-700">Product Not Found</h2>
            \\  <p class="text-slate-400 mt-1">The requested product does not exist.</p>
            \\</div>
        );
        return;
    }

    var out: std.ArrayList(u8) = .empty;
    try ProductDetail.render(.{ .product = products[0] }, &out, allocator);
    try res.html(out.items);
}
