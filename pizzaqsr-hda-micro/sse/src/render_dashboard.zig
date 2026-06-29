
const std = @import("std");
const Allocator = std.mem.Allocator;
const bson = @import("bson");

const Order = @import("models/order.zig").Order;
const hub_mod = @import("hub.zig");

const log = std.log.scoped(.pizzaqsr_sse);

pub fn publish(
    comptime name: []const u8,
    comptime Fragment: type,
    channel: []const u8,
    statuses: []const []const u8,
    c: *hub_mod.HubCtx,
    a: Allocator,
) !void {
    const bodies = try c.store.snapshotByStatus(a, statuses);
    defer {
        for (bodies) |b| a.free(b);
        a.free(bodies);
    }

    var orders: std.ArrayList(Order) = .empty;
    for (bodies) |body| {
        const order = bson.decode(a, Order, body) catch |err| {
            log.warn(name ++ ": bson decode failed: {s}", .{@errorName(err)});
            continue;
        };
        try orders.append(a, order);
    }

    var html: std.ArrayList(u8) = .empty;
    try Fragment.render(
        .{ .orders = orders.items, .sse_init = "" },
        &html,
        a,
    );

    const patch_data = try std.fmt.allocPrint(a, "elements {s}", .{html.items});
    _ = c.bus.publish(channel, .{
        .event = "datastar-patch-elements",
        .data = patch_data,
    }) catch |err| {
        log.warn(name ++ ": publish failed: {s}", .{@errorName(err)});
        return;
    };
}
