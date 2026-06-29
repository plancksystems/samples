
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const CartItem = @import("../models/cart.zig").CartItem;
const Ctx = @import("../../../core/ctx.zig").Ctx;
const repo = @import("../repo.zig");
const CartBadge = @import("../fragments/cart_badge.zig").CartBadge;
const CartDrawer = @import("../fragments/cart_drawer.zig").CartDrawer;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const product_id_str = req.getQuery("productId") orelse return error.InvalidRequest;
    const product_id = std.fmt.parseInt(i32, product_id_str, 10) catch return error.InvalidRequest;
    if (product_id == 0) return error.InvalidRequest;

    var cart = (try repo.loadCart(ctx.client, allocator, customer_id)) orelse return error.NotFound;
    defer repo.freeCart(allocator, &cart);

    const new_items = try filterOut(allocator, cart.Items, product_id);
    if (cart.Items.len > 0) allocator.free(cart.Items);
    cart.Items = new_items;
    cart.SubTotal = cart.computeSubtotal();

    try repo.saveCart(ctx.client, allocator, cart, true);

    var out: std.ArrayList(u8) = .empty;
    try CartBadge.render(.{ .total = cart.totalQty() }, &out, allocator);
    try CartDrawer.render(.{ .cart = cart }, &out, allocator);
    try res.html(out.items);
}

fn filterOut(
    allocator: std.mem.Allocator,
    current: []const CartItem,
    product_id: i32
) ![]const CartItem {
    var keep: usize = 0;
    for (current) |it| if (it.ProductID != product_id) {
        keep += 1;
    };
    const out = try allocator.alloc(CartItem, keep);
    var j: usize = 0;
    for (current) |it| {
        if (it.ProductID == product_id) continue;
        out[j] = it;
        j += 1;
    }
    return out;
}
