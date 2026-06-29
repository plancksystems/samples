
const std = @import("std");
const planck = @import("planck");
const Cart = @import("models/cart.zig").Cart;
const CartItem = @import("models/cart.zig").CartItem;

pub fn loadCart(client: *planck.Client, allocator: std.mem.Allocator, customer_id: []const u8) !?Cart {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();

    var resp = q.store("carts")
        .where("CustomerID", .eq, .{ .string = customer_id })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, Cart) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;

    const items_dup = try allocator.alloc(CartItem, rows[0].Items.len);
    for (rows[0].Items, 0..) |it, i| items_dup[i] = it;
    var c = rows[0];
    c.Items = items_dup;
    return c;
}

pub fn freeCart(allocator: std.mem.Allocator, cart: *const Cart) void {
    if (cart.Items.len > 0) allocator.free(cart.Items);
}

pub fn saveCart(client: *planck.Client, allocator: std.mem.Allocator, cart: Cart, existed: bool) !void {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    if (existed) {
        var resp = try (try q.store("carts")
            .where("CartID", .eq, .{ .int = cart.CartID })
            .update(cart)).run();
        defer resp.deinit();
    } else {
        var resp = try (try q.store("carts").create(cart)).run();
        defer resp.deinit();
    }
}

pub fn deleteCart(client: *planck.Client, allocator: std.mem.Allocator, customer_id: []const u8) !void {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = q.store("carts")
        .where("CustomerID", .eq, .{ .string = customer_id })
        .delete()
        .run() catch |err| switch (err) {
        error.InvalidResponse => return,
        else => return err,
    };
    defer resp.deinit();
}
