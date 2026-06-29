
const web = @import("web");
const Ctx = @import("../ctx.zig").Ctx;

const get_checkout = @import("handlers/get_checkout_handler.zig");
const post_checkout = @import("handlers/post_checkout_handler.zig");
const get_pay = @import("handlers/get_pay_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/checkout", get_checkout.handle, ctx);
    try app.post("/checkout", post_checkout.handle, ctx);
    try app.get("/pay/:order_key", get_pay.handle, ctx);
}
