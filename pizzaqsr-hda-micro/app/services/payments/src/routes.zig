
const Ctx = @import("ctx.zig").Ctx;

const get_intent = @import("handlers/get_intent_handler.zig");
const webhook = @import("handlers/webhook_handler.zig");
const create_intent = @import("handlers/create_intent_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/payments/by-order/:order_key/intent", get_intent.handle, ctx);
    try app.post("/payments/webhook", webhook.handle, ctx);
    try app.post("/internal/intents", create_intent.handle, ctx);
}
