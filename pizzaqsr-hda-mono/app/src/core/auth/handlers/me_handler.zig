
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const auth_jwt = @import("../jwt.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const auth_header = req.getHeader("Authorization") orelse
        req.getHeader("authorization") orelse
        return unauthorized(res, "missing Authorization header");
    if (auth_header.len < 7 or !std.ascii.eqlIgnoreCase(auth_header[0..7], "bearer ")) {
        return unauthorized(res, "expected Bearer scheme");
    }
    const token = std.mem.trim(u8, auth_header[7..], " \t");

    const now_s = auth_jwt.nowSeconds();
    const claims = auth_jwt.verify(allocator, ctx.jwt_secret, token, now_s) catch |err| {
        const msg: []const u8 = switch (err) {
            error.Expired => "token expired",
            error.BadSignature => "invalid signature",
            else => "invalid token",
        };
        return unauthorized(res, msg);
    };

    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"user_id\":\"{s}\",\"email\":\"{s}\",\"name\":\"{s}\"}}",
        .{ claims.sub, claims.email, claims.name },
    );
    try res.json(body);
}

fn unauthorized(res: *Response, msg: []const u8) !void {
    res.status = .unauthorized;
    try res.setHeader("WWW-Authenticate", "Bearer realm=\"pizzaqsr\"");
    const body = try std.fmt.allocPrint(res.allocator, "{{\"error\":\"{s}\"}}", .{msg});
    try res.json(body);
}
