
const Ctx = @import("../../core/ctx.zig").Ctx;

const dashboard = @import("handlers/dashboard_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/delivery", dashboard.handle, ctx);
}
