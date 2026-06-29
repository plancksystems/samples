
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Cart = @import("../models/cart.zig").Cart;
const CartItem = @import("../models/cart.zig").CartItem;
const UpdateItemBody = @import("../models/cart.zig").UpdateItemBody;
const Ctx = @import("../../ctx.zig").Ctx;
const repo = @import("../repo.zig");
const CartBadge = @import("../fragments/cart_badge.zig").CartBadge;
const CartDrawer = @import("../fragments/cart_drawer.zig").CartDrawer;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const body = try req.getBody(allocator, UpdateItemBody);
    if (body.productId == 0) return error.InvalidRequest;

    var cart = (try repo.loadCart(ctx.client, allocator, customer_id)) orelse return error.NotFound;
    defer repo.freeCart(allocator, &cart);

    const new_items = try mutateLines(allocator, cart.Items, &body);
    if (cart.Items.len > 0) allocator.free(cart.Items);
    cart.Items = new_items;
    cart.SubTotal = cart.computeSubtotal();

    try repo.saveCart(ctx.client, allocator, cart, true);

    var out: std.ArrayList(u8) = .empty;
    try CartBadge.render(.{ .total = cart.totalQty() }, &out, allocator);
    try CartDrawer.render(.{ .cart = cart }, &out, allocator);
    try res.html(out.items);
}

fn mutateLines(
    allocator: std.mem.Allocator,
    current: []const CartItem,
    body: *const UpdateItemBody
) ![]const CartItem {
    var match: ?usize = null;
    for (current, 0..) |it, i| {
        if (it.ProductID == body.productId) {
            match = i;
            break;
        }
    }

    if (match == null) {
        const copy = try allocator.alloc(CartItem, current.len);
        for (current, 0..) |it, i| copy[i] = it;
        return copy;
    }

    if (body.qty == 0) {
        const out = try allocator.alloc(CartItem, current.len - 1);
        var j: usize = 0;
        for (current, 0..) |it, i| {
            if (i == match.?) continue;
            out[j] = it;
            j += 1;
        }
        return out;
    }

    const out = try allocator.alloc(CartItem, current.len);
    for (current, 0..) |it, i| out[i] = it;
    out[match.?].Qty = body.qty;
    out[match.?].LineTotal = out[match.?].UnitPrice * @as(f64, @floatFromInt(body.qty));
    return out;
}
