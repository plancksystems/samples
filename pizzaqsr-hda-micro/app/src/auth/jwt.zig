const std = @import("std");
const web = @import("web");

pub const Claims = web.jwt.Claims;
pub const Error = web.jwt.Error;

pub fn mint(allocator: std.mem.Allocator, secret: []const u8, sub: []const u8, email: []const u8, name: []const u8, now_unix_s: i64, ttl_seconds: i64) ![]u8 {
    const claims = Claims{
        .sub = sub,
        .email = email,
        .name = name,
        .iat = now_unix_s,
        .exp = now_unix_s + ttl_seconds,
    };
    return web.jwt.mint(allocator, secret, claims);
}

pub fn verify(allocator: std.mem.Allocator, secret: []const u8, token: []const u8, now_unix_s: i64) !Claims {
    return web.jwt.verify(allocator, secret, token, now_unix_s);
}

pub fn nowSeconds() i64 {
    return web.sys.nowUnixSeconds();
}
