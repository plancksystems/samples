
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const ProductList = @import("../fragments/product_list.zig").ProductList;
const Ctx = @import("../ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const category_id: ?i32 = if (req.getQuery("category")) |cat|
        std.fmt.parseInt(i32, cat, 10) catch null
    else
        null;

    const products = try repo.listProducts(ctx.client, allocator, category_id, req.getQuery("q"));
    defer allocator.free(products);

    var out: std.ArrayList(u8) = .empty;
    try ProductList.render(.{ .products = products }, &out, allocator);
    try res.html(out.items);
}
