
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const CartBadge = @import("../fragments/cart_badge.zig").CartBadge;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    var loaded = try repo.loadCart(ctx.client, allocator, customer_id);
    defer if (loaded) |*c| repo.freeCart(allocator, c);

    const total: u32 = if (loaded) |c| c.totalQty() else 0;

    var out: std.ArrayList(u8) = .empty;
    try CartBadge.render(.{ .total = total }, &out, allocator);
    try res.html(out.items);
}
