
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const cart_repo = @import("../../cart/repo.zig");
const orders_repo = @import("../../orders/repo.zig");
const payments_repo = @import("../../payments/repo.zig");
const order_models = @import("../../orders/models/order.zig");
const PayPage = @import("../fragments/pay_page.zig").PayPage;
const CheckoutBody = order_models.CheckoutBody;
const Order = order_models.Order;
const OrderItem = order_models.OrderItem;
const Address = order_models.Address;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const body = try req.getBody(allocator, CheckoutBody);

    var cart = (try cart_repo.loadCart(ctx.client, allocator, customer_id)) orelse return error.EmptyBody;
    defer cart_repo.freeCart(allocator, &cart);
    if (cart.Items.len == 0) return error.EmptyBody;

    const order_items = try allocator.alloc(OrderItem, cart.Items.len);
    for (cart.Items, 0..) |it, i| {
        order_items[i] = .{
            .ProductID = it.ProductID,
            .Name = it.Name,
            .UnitPrice = it.UnitPrice,
            .Qty = it.Qty,
            .LineTotal = it.LineTotal,
        };
    }

    const subtotal = cart.computeSubtotal();
    const tax = subtotal * 0.05;
    const delivery_fee: f64 = 49;
    const total = subtotal + tax + delivery_fee;

    const order_key = try randomHex(allocator, 16);

    const created_at = try nowIsoString(allocator);
    const now_ms = web.sys.nowUnixSeconds() * 1000;

    var new_order = Order{
        .OrderKey = order_key,
        .CustomerID = customer_id,
        .Status = order_models.status_awaiting_payment,
        .Items = order_items,
        .SubTotal = subtotal,
        .Tax = tax,
        .DeliveryFee = delivery_fee,
        .Total = total,
        .DeliveryAddress = .{
            .Label = body.addressLabel,
            .Line1 = body.line1,
            .Line2 = body.line2,
            .City = body.city,
            .State = body.state,
            .Pincode = body.pincode,
        },
        .CreatedAt = created_at,
        .CreatedAtMillis = now_ms,
        .UpdatedAt = created_at,
    };

    new_order = try orders_repo.create(ctx.client, allocator, new_order);

    const amount_minor: i64 = @intFromFloat(@round(total * 100));
    const intent = payments_repo.createIntent(
        ctx.client,
        allocator,
        req.io.?,
        ctx.stripe_secret_key,
        new_order.OrderID,
        amount_minor,
        "inr",
    ) catch |err| {
        res.status = .bad_gateway;
        const msg = try std.fmt.allocPrint(allocator, "stripe error: {s}", .{@errorName(err)});
        try res.write(msg);
        return;
    };

    try orders_repo.setPaymentIntent(ctx.client, allocator, new_order.OrderID, intent.intent_id);

    cart_repo.deleteCart(ctx.client, allocator, customer_id) catch |err| {
        web.log.logFmt(.warn, "checkout: cart delete failed for {s}: {s}", .{ customer_id, @errorName(err) });
    };

    try res.setCookie(.{
        .name = "pizzaqsr_tracking_order",
        .value = new_order.OrderKey,
        .path = "/",
        .same_site = .Lax,
    });

    var out: std.ArrayList(u8) = .empty;
    try PayPage.render(.{ .order = new_order }, &out, allocator);
    try res.html(out.items);
}


fn randomHex(allocator: std.mem.Allocator, n_bytes: usize) ![]u8 {
    var raw: [64]u8 = undefined;
    if (n_bytes > raw.len) return error.RequestedTooLarge;
    web.sys.randomBytes(raw[0..n_bytes]);
    const out = try allocator.alloc(u8, n_bytes * 2);
    const hex = "0123456789abcdef";
    for (raw[0..n_bytes], 0..) |b, i| {
        out[i * 2] = hex[b >> 4];
        out[i * 2 + 1] = hex[b & 0xF];
    }
    return out;
}

fn nowIsoString(allocator: std.mem.Allocator) ![]u8 {
    const secs = web.sys.nowUnixSeconds();
    return std.fmt.allocPrint(allocator, "{d}", .{secs});
}
