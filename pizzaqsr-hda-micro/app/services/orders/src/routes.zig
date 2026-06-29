
const Ctx = @import("ctx.zig").Ctx;

const cart_routes = @import("cart/routes.zig");
const checkout_routes = @import("checkout/routes.zig");
const orders_routes = @import("orders/routes.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try cart_routes.register(app, ctx);
    try checkout_routes.register(app, ctx);
    try orders_routes.register(app, ctx);
}
