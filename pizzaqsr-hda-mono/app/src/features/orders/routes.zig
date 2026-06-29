
const Ctx = @import("../../core/ctx.zig").Ctx;

const list_orders = @import("handlers/list_orders_handler.zig");
const get_order = @import("handlers/get_order_handler.zig");
const get_tracking = @import("handlers/get_tracking_handler.zig");
const update_status = @import("handlers/update_status_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/orders", list_orders.handle, ctx);
    try app.get("/orders/:order_key", get_order.handle, ctx);
    try app.get("/orders/:order_key/tracking", get_tracking.handle, ctx);
    try app.post("/orders/:order_key/status", update_status.handle, ctx);
}
