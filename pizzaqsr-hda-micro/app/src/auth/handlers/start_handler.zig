const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const sys = web.sys;

const state_cookie_name = "pizzaqsr_oauth_state";

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    _ = req;
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    if (ctx.google_client_id.len == 0 or ctx.google_redirect_uri.len == 0) {
        res.status = .internal_server_error;
        try res.write("OAuth misconfigured. Check `google.*` in config.yaml.");
        return;
    }

    const state = try randomHex(allocator, 16);

    try res.setCookie(.{
        .name = state_cookie_name,
        .value = state,
        .path = "/",
        .max_age = 300,
        .http_only = true,
        .same_site = .Lax,
    });

    const url = try std.fmt.allocPrint(
        allocator,
        "https://accounts.google.com/o/oauth2/v2/auth" ++
            "?client_id={s}" ++
            "&redirect_uri={s}" ++
            "&response_type=code" ++
            "&scope=openid%20email%20profile" ++
            "&state={s}" ++
            "&access_type=online" ++
            "&prompt=select_account",
        .{ ctx.google_client_id, ctx.google_redirect_uri, state },
    );

    res.status = .found;
    try res.setHeader("Location", url);
    try res.setHeader("Cache-Control", "no-store");
}

fn randomHex(allocator: std.mem.Allocator, n_bytes: usize) ![]u8 {
    var raw: [64]u8 = undefined;
    if (n_bytes > raw.len) return error.RequestedTooLarge;
    sys.randomBytes(raw[0..n_bytes]);
    const out = try allocator.alloc(u8, n_bytes * 2);
    const hex = "0123456789abcdef";
    for (raw[0..n_bytes], 0..) |b, i| {
        out[i * 2] = hex[b >> 4];
        out[i * 2 + 1] = hex[b & 0xF];
    }
    return out;
}
