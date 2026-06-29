
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const auth_jwt = @import("../jwt.zig");
const users_repo = @import("../../../features/users/repo.zig");

const state_cookie_name = "pizzaqsr_oauth_state";

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const state_q = req.getQuery("state") orelse return errResp(res, .bad_request, "missing state");
    const state_c = req.getCookie(state_cookie_name) orelse return errResp(res, .bad_request, "missing state cookie");
    if (!std.mem.eql(u8, state_q, state_c)) {
        return errResp(res, .bad_request, "state mismatch");
    }
    const code = req.getQuery("code") orelse return errResp(res, .bad_request, "missing code");

    const form_body = try std.fmt.allocPrint(
        allocator,
        "code={s}&client_id={s}&client_secret={s}&redirect_uri={s}&grant_type=authorization_code",
        .{ code, ctx.google_client_id, ctx.google_client_secret, ctx.google_redirect_uri },
    );

    var token_buf: [8192]u8 = undefined;
    const token_resp = web.callServiceWithHeaders(
        "google_oauth",
        "/token",
        "POST",
        form_body,
        "Content-Type: application/x-www-form-urlencoded",
        &token_buf,
    ) catch |err| {
        return errResp(res, .bad_gateway, switch (err) {
            error.UnknownUpstream => "google_oauth upstream not configured in config.yaml",
            error.Timeout => "google token exchange timed out",
            error.CircuitOpen => "google_oauth circuit breaker open",
            else => "google token exchange failed",
        });
    };

    if (token_resp.status != 200) {
        const trunc = if (token_resp.body.len > 256) token_resp.body[0..256] else token_resp.body;
        web.log.logFmt(.err, "google token exchange non-2xx: status={d} body={s}", .{ token_resp.status, trunc });
        return errResp(res, .bad_gateway, "google token exchange returned non-200");
    }

    const id_token = try parseStringField(token_resp.body, "id_token");
    const claims = try decodeIdTokenPayload(allocator, id_token);

    if (claims.sub.len == 0) return errResp(res, .bad_gateway, "google response missing sub");

    _ = users_repo.upsertFromOAuth(ctx.client, allocator, claims.sub, claims.email, claims.name) catch |err| {
        web.log.logFmt(.warn, "auth/callback: users upsert failed for {s}: {s}", .{ claims.sub, @errorName(err) });
    };

    const now_s = auth_jwt.nowSeconds();
    const our_jwt = try auth_jwt.mint(
        allocator,
        ctx.jwt_secret,
        claims.sub,
        claims.email,
        claims.name,
        now_s,
        ctx.jwt_ttl_seconds,
    );

    try res.setCookie(.{
        .name = state_cookie_name,
        .value = "",
        .path = "/",
        .max_age = 0,
        .http_only = true,
        .same_site = .Lax,
    });
    try res.setCookie(.{
        .name = "pizzaqsr_jwt",
        .value = our_jwt,
        .path = "/",
        .max_age = ctx.jwt_ttl_seconds,
        .http_only = true,
        .same_site = .Lax,
    });

    res.status = .found;
    try res.setHeader("Location", "/");
    try res.setHeader("Cache-Control", "no-store");
}


fn errResp(res: *Response, status: web.Status, msg: []const u8) !void {
    res.status = status;
    try res.write(msg);
}

fn parseStringField(body: []const u8, field: []const u8) ![]const u8 {
    var needle_buf: [128]u8 = undefined;
    if (field.len + 3 > needle_buf.len) return error.FieldNameTooLong;
    needle_buf[0] = '"';
    @memcpy(needle_buf[1..][0..field.len], field);
    needle_buf[1 + field.len] = '"';
    const needle = needle_buf[0 .. 2 + field.len];

    const start = std.mem.indexOf(u8, body, needle) orelse return error.FieldMissing;
    var i = start + needle.len;
    while (i < body.len and (body[i] == ' ' or body[i] == ':')) i += 1;
    if (i >= body.len or body[i] != '"') return error.FieldNotString;
    i += 1;
    const value_start = i;
    while (i < body.len and body[i] != '"') i += 1;
    if (i >= body.len) return error.UnterminatedString;
    return body[value_start..i];
}

const IdTokenClaims = struct {
    sub: []const u8 = "",
    email: []const u8 = "",
    name: []const u8 = "",
};

fn decodeIdTokenPayload(allocator: std.mem.Allocator, id_token: []const u8) !IdTokenClaims {
    const first_dot = std.mem.indexOfScalar(u8, id_token, '.') orelse return error.MalformedIdToken;
    const rest = id_token[first_dot + 1 ..];
    const second_dot = std.mem.indexOfScalar(u8, rest, '.') orelse return error.MalformedIdToken;
    const payload_b64 = rest[0..second_dot];

    const b64 = std.base64.url_safe_no_pad;
    const decoded_len = try b64.Decoder.calcSizeForSlice(payload_b64);
    const decoded = try allocator.alloc(u8, decoded_len);
    try b64.Decoder.decode(decoded, payload_b64);

    return .{
        .sub = parseStringField(decoded, "sub") catch "",
        .email = parseStringField(decoded, "email") catch "",
        .name = parseStringField(decoded, "name") catch "",
    };
}
