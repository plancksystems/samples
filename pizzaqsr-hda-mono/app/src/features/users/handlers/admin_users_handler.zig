
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const AdminUsersPage = @import("../fragments/admin_users_page.zig").AdminUsersPage;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const role = req.getLocal("role") orelse return error.Forbidden;
    if (!std.mem.eql(u8, role, "admin")) return error.Forbidden;

    const users = try repo.listAll(ctx.client, allocator);
    defer allocator.free(users);

    var out: std.ArrayList(u8) = .empty;
    try AdminUsersPage.render(.{ .users = users }, &out, allocator);
    try res.html(out.items);
}
