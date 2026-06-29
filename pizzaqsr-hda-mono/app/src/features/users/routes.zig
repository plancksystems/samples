
const web = @import("web");
const Ctx = @import("../../core/ctx.zig").Ctx;

const admin_users = @import("handlers/admin_users_handler.zig");
const create_user = @import("handlers/create_user_handler.zig");
const update_role = @import("handlers/update_role_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/admin/users", admin_users.handle, ctx);
    try app.post("/admin/users", create_user.handle, ctx);
    try app.put("/admin/users/:target_id/role", update_role.handle, ctx);
}
