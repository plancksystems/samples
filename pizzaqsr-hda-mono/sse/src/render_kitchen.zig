
const std = @import("std");
const Allocator = std.mem.Allocator;

const order_models = @import("models/order.zig");
const KitchenDashboard = @import("fragments/kitchen_dashboard.zig").KitchenDashboard;
const hub_mod = @import("hub.zig");
const render_dashboard = @import("render_dashboard.zig");

const KITCHEN_STATUSES = [_][]const u8{
    order_models.status_paid,
    order_models.status_preparing,
    order_models.status_ready,
};

pub fn publish(c: *hub_mod.HubCtx, a: Allocator) !void {
    try render_dashboard.publish(
        "render_kitchen",
        KitchenDashboard,
        "kitchen",
        &KITCHEN_STATUSES,
        c,
        a,
    );
}
