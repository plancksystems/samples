
const std = @import("std");
const planck = @import("planck");
const Order = @import("models/order.zig").Order;
const OrderItem = @import("models/order.zig").OrderItem;

pub fn findByStatuses(
    client: *planck.Client,
    allocator: std.mem.Allocator,
    statuses: []const []const u8
) ![]Order {
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

pub fn freeOrders(allocator: std.mem.Allocator, orders: []Order) void {
    for (orders) |o| if (o.Items.len > 0) allocator.free(o.Items);
    allocator.free(orders);
}

fn dupItems(allocator: std.mem.Allocator, order: Order) !Order {
    if (order.Items.len == 0) return order;
    var copy = order;
    copy.Items = try allocator.dupe(OrderItem, order.Items);
    return copy;
}
