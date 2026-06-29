
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const Cart = @import("../../cart/models/cart.zig").Cart;
const cart_repo = @import("../../cart/repo.zig");
const CheckoutPage = @import("../fragments/checkout_page.zig").CheckoutPage;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    var loaded = try cart_repo.loadCart(ctx.client, allocator, customer_id);
    defer if (loaded) |*c| cart_repo.freeCart(allocator, c);

    const cart = loaded orelse Cart{ .CustomerID = customer_id };

    var out: std.ArrayList(u8) = .empty;
    try CheckoutPage.render(.{ .cart = cart }, &out, allocator);
    try res.html(out.items);
}
