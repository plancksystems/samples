
const Ctx = @import("../ctx.zig").Ctx;

const list_orders = @import("handlers/list_orders_handler.zig");
const get_order = @import("handlers/get_order_handler.zig");
const get_tracking = @import("handlers/get_tracking_handler.zig");
const update_status = @import("handlers/update_status_handler.zig");
const internal_status_from_payment = @import("handlers/internal_status_from_payment_handler.zig");
const internal_find_by_key = @import("handlers/internal_find_by_key_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/orders", list_orders.handle, ctx);
    try app.get("/orders/:order_key", get_order.handle, ctx);
    try app.get("/orders/:order_key/tracking", get_tracking.handle, ctx);
    try app.post("/orders/:order_key/status", update_status.handle, ctx);

    try app.post("/internal/status-from-payment", internal_status_from_payment.handle, ctx);
    try app.get("/internal/orders/by-key/:order_key", internal_find_by_key.handle, ctx);
}
