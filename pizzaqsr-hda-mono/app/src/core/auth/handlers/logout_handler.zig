
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

pub fn handle(_: ?*anyopaque, _: std.mem.Allocator, _: *const Request, res: *Response) !void {
    try res.setCookie(.{
        .name = "pizzaqsr_jwt",
        .value = "",
        .path = "/",
        .max_age = 0,
        .http_only = true,
        .same_site = .Lax,
    });
    res.status = .found;
    try res.setHeader("Location", "/");
    try res.setHeader("Cache-Control", "no-store");
}
