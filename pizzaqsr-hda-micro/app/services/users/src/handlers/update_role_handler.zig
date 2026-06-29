
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../ctx.zig").Ctx;
const UpdateRoleBody = @import("../models/user.zig").UpdateRoleBody;
const AdminUsersPage = @import("../fragments/admin_users_page.zig").AdminUsersPage;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const role_claim = req.getLocal("role") orelse return error.Forbidden;
    if (!std.mem.eql(u8, role_claim, "admin")) return error.Forbidden;

    const target_id_str = req.getLocal("target_id") orelse return error.InvalidRequest;
    const user_id = std.fmt.parseInt(i64, target_id_str, 10) catch return error.InvalidRequest;

    const body = try req.getBody(allocator, UpdateRoleBody);
    if (body.role.len == 0) return error.InvalidRequest;

    try repo.updateRole(ctx.client, allocator, user_id, body.role);

    const users = try repo.listAll(ctx.client, allocator);
    defer allocator.free(users);

    var out: std.ArrayList(u8) = .empty;
    try AdminUsersPage.render(.{ .users = users }, &out, allocator);
    try res.html(out.items);
}
