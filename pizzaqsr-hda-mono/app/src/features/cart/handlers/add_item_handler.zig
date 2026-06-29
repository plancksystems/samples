
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Cart = @import("../models/cart.zig").Cart;
const CartItem = @import("../models/cart.zig").CartItem;
const AddItemBody = @import("../models/cart.zig").AddItemBody;
const Ctx = @import("../../../core/ctx.zig").Ctx;
const repo = @import("../repo.zig");
const CartBadge = @import("../fragments/cart_badge.zig").CartBadge;
const CartDrawer = @import("../fragments/cart_drawer.zig").CartDrawer;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const body = try req.getBody(allocator, AddItemBody);
    if (body.productId == 0 or body.qty == 0) return error.InvalidRequest;

    const loaded = try repo.loadCart(ctx.client, allocator, customer_id);
    var cart = loaded orelse Cart{
        .CartID = @intCast(try ctx.client.nextSequence("carts_seq")),
        .CustomerID = customer_id,
        .Status = "open",
    };
    defer if (loaded != null) repo.freeCart(allocator, &cart);

    cart.Items = try upsertLine(allocator, cart.Items, &body, loaded != null);
    cart.SubTotal = cart.computeSubtotal();

    try repo.saveCart(ctx.client, allocator, cart, loaded != null);

    var out: std.ArrayList(u8) = .empty;
    try CartBadge.render(.{ .total = cart.totalQty() }, &out, allocator);
    try CartDrawer.render(.{ .cart = cart }, &out, allocator);
    try res.html(out.items);
}

fn upsertLine(
    allocator: std.mem.Allocator,
    current: []const CartItem,
    body: *const AddItemBody,
    had_old_slice: bool
) ![]const CartItem {
    var found_idx: ?usize = null;
    for (current, 0..) |it, i| {
        if (it.ProductID == body.productId) {
            found_idx = i;
            break;
        }
    }

    const new_len = if (found_idx != null) current.len else current.len + 1;
    const out = try allocator.alloc(CartItem, new_len);
    for (current, 0..) |it, i| out[i] = it;

    if (found_idx) |idx| {
        out[idx].Qty += body.qty;
        out[idx].LineTotal = out[idx].UnitPrice * @as(f64, @floatFromInt(out[idx].Qty));
    } else {
        out[current.len] = .{
            .ProductID = body.productId,
            .Name = body.name,
            .UnitPrice = body.unitPrice,
            .Qty = body.qty,
            .LineTotal = body.unitPrice * @as(f64, @floatFromInt(body.qty)),
        };
    }

    if (had_old_slice and current.len > 0) allocator.free(current);
    return out;
}
