
const std = @import("std");
const Allocator = std.mem.Allocator;
const bson = @import("bson");

const Order = @import("models/order.zig").Order;
const OrderDetail = @import("fragments/order_detail.zig").OrderDetail;
const hub_mod = @import("hub.zig");

const log = std.log.scoped(.pizzaqsr_sse);

pub fn publish(c: *hub_mod.HubCtx, a: Allocator, order_key: []const u8, body: []const u8) !void {
    const topic = try std.fmt.allocPrint(a, "order:{s}", .{order_key});

    const order = bson.decode(a, Order, body) catch |err| {
        log.warn("render_tracking: bson decode failed: {s}", .{@errorName(err)});
        return;
    };

    var html: std.ArrayList(u8) = .empty;
    try OrderDetail.render(
        .{ .order = order, .sse_init = "" },
        &html,
        a,
    );

    const patch_data = try std.fmt.allocPrint(a, "elements {s}", .{html.items});
    _ = c.bus.publish(topic, .{
        .event = "datastar-patch-elements",
        .data = patch_data,
    }) catch |err| {
        log.warn("render_tracking: publish failed: {s}", .{@errorName(err)});
        return;
    };
}
