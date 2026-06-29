
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Cart = @import("../models/cart.zig").Cart;
const Ctx = @import("../../../core/ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    var loaded = try repo.loadCart(ctx.client, allocator, customer_id);
    defer if (loaded) |*c| repo.freeCart(allocator, c);

    const cart = loaded orelse Cart{ .CustomerID = customer_id };
    const body_json = try renderJson(allocator, cart);
    try res.json(body_json);
}

fn renderJson(allocator: std.mem.Allocator, cart: Cart) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    try out.appendSlice(allocator, "{\"customer_id\":\"");
    try out.appendSlice(allocator, cart.CustomerID);
    try out.appendSlice(allocator, "\",\"cart_id\":");
    const cart_id_str = try std.fmt.allocPrint(allocator, "{d}", .{cart.CartID});
    defer allocator.free(cart_id_str);
    try out.appendSlice(allocator, cart_id_str);
    try out.appendSlice(allocator, ",\"status\":\"");
    try out.appendSlice(allocator, cart.Status);
    try out.appendSlice(allocator, "\",\"items\":[");

    for (cart.Items, 0..) |it, i| {
        if (i > 0) try out.append(allocator, ',');
        const line = try std.fmt.allocPrint(
            allocator,
            "{{\"product_id\":{d},\"name\":\"{s}\",\"unit_price\":{d},\"qty\":{d},\"line_total\":{d}}}",
            .{ it.ProductID, it.Name, it.UnitPrice, it.Qty, it.LineTotal },
        );
        defer allocator.free(line);
        try out.appendSlice(allocator, line);
    }

    const tail = try std.fmt.allocPrint(
        allocator,
        "],\"total_qty\":{d},\"subtotal\":{d}}}",
        .{ cart.totalQty(), cart.SubTotal },
    );
    defer allocator.free(tail);
    try out.appendSlice(allocator, tail);

    return out.toOwnedSlice(allocator);
}
