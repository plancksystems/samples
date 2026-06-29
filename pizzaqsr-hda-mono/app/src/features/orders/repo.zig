const std = @import("std");
const planck = @import("planck");
const web = @import("web");
const Order = @import("models/order.zig").Order;
const OrderItem = @import("models/order.zig").OrderItem;

pub fn findById(client: *planck.Client, allocator: std.mem.Allocator, order_id: i64) !?Order {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();

    var resp = q.store("orders")
        .where("OrderID", .eq, .{ .int = order_id })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, Order) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return try dupItems(allocator, rows[0]);
}

pub fn findByKey(client: *planck.Client, allocator: std.mem.Allocator, order_key: []const u8) !?Order {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();

    var resp = q.store("orders")
        .where("OrderKey", .eq, .{ .string = order_key })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, Order) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return try dupItems(allocator, rows[0]);
}

pub fn findByStatuses(client: *planck.Client, allocator: std.mem.Allocator, statuses: []const []const u8) ![]Order {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = q.store("orders").run() catch |err| switch (err) {
        error.InvalidResponse => return &.{},
        else => return err,
    };
    defer resp.deinit();

    const all = resp.decode(allocator, Order) catch return &.{};
    defer allocator.free(all);

    var keep_count: usize = 0;
    for (all) |o| {
        for (statuses) |s| if (std.mem.eql(u8, o.Status, s)) {
            keep_count += 1;
            break;
        };
    }

    const out = try allocator.alloc(Order, keep_count);
    var j: usize = 0;
    for (all) |o| {
        for (statuses) |s| if (std.mem.eql(u8, o.Status, s)) {
            out[j] = try dupItems(allocator, o);
            j += 1;
            break;
        };
    }
    return out;
}

pub fn findByCustomer(client: *planck.Client, allocator: std.mem.Allocator, customer_id: []const u8, limit: u32) ![]Order {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();

    var builder = q.store("orders")
        .where("CustomerID", .eq, .{ .string = customer_id });
    if (limit > 0) builder = builder.limit(limit);

    var resp = builder.run() catch |err| switch (err) {
        error.InvalidResponse => return &.{},
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, Order) catch return &.{};
    defer allocator.free(rows);

    const out = try allocator.alloc(Order, rows.len);
    for (rows, 0..) |r, i| out[i] = try dupItems(allocator, r);
    return out;
}

pub fn freeOrders(allocator: std.mem.Allocator, orders: []Order) void {
    for (orders) |o| freeOrder(allocator, &o);
    allocator.free(orders);
}

pub fn freeOrder(allocator: std.mem.Allocator, order: *const Order) void {
    if (order.Items.len > 0) allocator.free(order.Items);
}

pub fn create(client: *planck.Client, allocator: std.mem.Allocator, order: Order) !Order {
    var to_save = order;
    to_save.OrderID = try client.nextSequence("orders_seq");

    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = try (try q.store("orders").create(to_save)).run();
    defer resp.deinit();

    return to_save;
}

pub fn updateStatus(client: *planck.Client, allocator: std.mem.Allocator, order_id: i64, from: []const u8, to: []const u8) !bool {
    var order = (try findById(client, allocator, order_id)) orelse return false;
    defer freeOrder(allocator, &order);
    if (!std.mem.eql(u8, order.Status, from)) return false;

    order.Status = to;
    try saveOrder(client, allocator, order);
    return true;
}

pub fn setPaymentIntent(client: *planck.Client, allocator: std.mem.Allocator, order_id: i64, intent_id: []const u8) !void {
    var order = (try findById(client, allocator, order_id)) orelse return error.NotFound;
    defer freeOrder(allocator, &order);
    order.PaymentIntentID = intent_id;
    try saveOrder(client, allocator, order);
}

pub fn claimKitchen(client: *planck.Client, allocator: std.mem.Allocator, order_id: i64, worker_id: i64) !bool {
    var order = (try findById(client, allocator, order_id)) orelse return false;
    defer freeOrder(allocator, &order);
    if (order.KitchenWorkerID != 0) return false;
    order.KitchenWorkerID = worker_id;
    try saveOrder(client, allocator, order);
    return true;
}

pub fn claimDelivery(client: *planck.Client, allocator: std.mem.Allocator, order_id: i64, partner_id: i64) !bool {
    var order = (try findById(client, allocator, order_id)) orelse return false;
    defer freeOrder(allocator, &order);
    if (order.DeliveryPartnerID != 0) return false;
    order.DeliveryPartnerID = partner_id;
    try saveOrder(client, allocator, order);
    return true;
}

pub fn saveOrder(client: *planck.Client, allocator: std.mem.Allocator, order: Order) !void {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = try (try q.store("orders")
        .where("OrderID", .eq, .{ .int = order.OrderID })
        .update(order)).run();
    defer resp.deinit();
}

fn dupItems(allocator: std.mem.Allocator, row: Order) !Order {
    var c = row;
    if (row.Items.len > 0) {
        const items_dup = try allocator.alloc(OrderItem, row.Items.len);
        for (row.Items, 0..) |it, i| items_dup[i] = it;
        c.Items = items_dup;
    }
    return c;
}
