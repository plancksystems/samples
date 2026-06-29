
const web = @import("web");
const Ctx = @import("../ctx.zig").Ctx;

const add_item = @import("handlers/add_item_handler.zig");
const update_item = @import("handlers/update_item_handler.zig");
const remove_item = @import("handlers/remove_item_handler.zig");
const get_cart = @import("handlers/get_cart_handler.zig");
const get_badge = @import("handlers/get_badge_handler.zig");
const get_drawer = @import("handlers/get_drawer_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/cart", get_cart.handle, ctx);
    try app.get("/cart/badge", get_badge.handle, ctx);
    try app.get("/cart/drawer", get_drawer.handle, ctx);
    try app.post("/items", add_item.handle, ctx);
    try app.put("/items", update_item.handle, ctx);
    try app.delete("/items", remove_item.handle, ctx);
}
