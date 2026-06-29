
const Ctx = @import("../../core/ctx.zig").Ctx;

const run = @import("handlers/run_handler.zig");
const setup = @import("handlers/setup_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.post("/api/pql/run", run.handle, ctx);
    try app.post("/api/setup", setup.handle, ctx);
}
