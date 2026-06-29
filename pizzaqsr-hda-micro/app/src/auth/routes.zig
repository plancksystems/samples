const builtin = @import("builtin");
const Ctx = @import("../ctx.zig").Ctx;

const start = @import("handlers/start_handler.zig");
const callback = @import("handlers/callback_handler.zig");
const callback_native = @import("handlers/callback_native_handler.zig");
const me = @import("handlers/me_handler.zig");
const user_menu = @import("handlers/user_menu_handler.zig");
const logout = @import("handlers/logout_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/auth/google", start.handle, ctx);
    if (builtin.mode == .Debug) {
        try app.get("/auth/callback", callback_native.handle, ctx);
    } else {
        try app.get("/auth/callback", callback.handle, ctx);
    }
    try app.get("/auth/me", me.handle, ctx);
    try app.get("/auth/user-menu", user_menu.handle, ctx);
    try app.get("/auth/logout", logout.handle, ctx);
}
