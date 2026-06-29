
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const CreateUserBody = @import("../models/user.zig").CreateUserBody;
const AdminUsersPage = @import("../fragments/admin_users_page.zig").AdminUsersPage;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const role = req.getLocal("role") orelse return error.Forbidden;
    if (!std.mem.eql(u8, role, "admin")) return error.Forbidden;

    const body = try req.getBody(allocator, CreateUserBody);
    if (body.email.len == 0) return error.InvalidRequest;

    if (try repo.findByEmail(ctx.client, allocator, body.email)) |_| {
    } else {
        const now = web.sys.nowUnixSeconds();
        const created_at = try std.fmt.allocPrint(allocator, "{d}", .{now});
        _ = try repo.create(ctx.client, allocator, .{
            .Email = body.email,
            .Name = body.name,
            .Role = if (body.role.len > 0) body.role else "customer",
            .Phone = body.phone,
            .Status = "active",
            .CreatedAt = created_at,
            .UpdatedAt = created_at,
        });
    }

    const users = try repo.listAll(ctx.client, allocator);
    defer allocator.free(users);

    var out: std.ArrayList(u8) = .empty;
    try AdminUsersPage.render(.{ .users = users }, &out, allocator);
    try res.html(out.items);
}
