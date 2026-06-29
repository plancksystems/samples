
const std = @import("std");
const Allocator = std.mem.Allocator;

const order_models = @import("models/order.zig");
const DeliveryDashboard = @import("fragments/delivery_dashboard.zig").DeliveryDashboard;
const hub_mod = @import("hub.zig");
const render_dashboard = @import("render_dashboard.zig");

const DELIVERY_STATUSES = [_][]const u8{
    order_models.status_ready,
    order_models.status_out_for_delivery,
};

pub fn publish(c: *hub_mod.HubCtx, a: Allocator) !void {
    try render_dashboard.publish(
        "render_delivery",
        DeliveryDashboard,
        "delivery",
        &DELIVERY_STATUSES,
        c,
        a,
    );
}
