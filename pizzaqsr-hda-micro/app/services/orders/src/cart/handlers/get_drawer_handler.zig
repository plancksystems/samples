
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Cart = @import("../models/cart.zig").Cart;
const Ctx = @import("../../ctx.zig").Ctx;
const CartDrawer = @import("../fragments/cart_drawer.zig").CartDrawer;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    var loaded = try repo.loadCart(ctx.client, allocator, customer_id);
    defer if (loaded) |*c| repo.freeCart(allocator, c);

    const cart = loaded orelse Cart{ .CustomerID = customer_id };

    var out: std.ArrayList(u8) = .empty;
    try CartDrawer.render(.{ .cart = cart }, &out, allocator);
    try res.html(out.items);
}
