
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const ProductDetail = @import("../fragments/product_detail.zig").ProductDetail;
const Ctx = @import("../ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const id_str = req.getLocal("id") orelse return error.InvalidRequest;
    const id = std.fmt.parseInt(i32, id_str, 10) catch return error.InvalidRequest;

    const product = try repo.getProduct(ctx.client, allocator, id) orelse {
        try res.html(
            \\<div class="p-8 text-center">
            \\  <h2 class="text-lg font-semibold text-slate-700">Product Not Found</h2>
            \\  <p class="text-slate-400 mt-1">The requested product does not exist.</p>
            \\</div>
        );
        return;
    };

    var out: std.ArrayList(u8) = .empty;
    try ProductDetail.render(.{ .product = product }, &out, allocator);
    try res.html(out.items);
}
