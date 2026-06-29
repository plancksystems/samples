
const Ctx = @import("../../core/ctx.zig").Ctx;

const list = @import("handlers/list_handler.zig");
const create = @import("handlers/create_handler.zig");
const update = @import("handlers/update_handler.zig");
const delete_h = @import("handlers/delete_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/notes", list.handle, ctx);
    try app.post("/notes", create.handle, ctx);
    try app.put("/notes/:id", update.handle, ctx);
    try app.delete("/notes/:id", delete_h.handle, ctx);
}
