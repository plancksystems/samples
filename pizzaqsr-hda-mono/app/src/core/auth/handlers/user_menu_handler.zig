
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const auth_jwt = @import("../jwt.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    var signed_in = false;
    var display_name: []const u8 = "";

    var token: []const u8 = "";
    if (req.getHeader("Authorization") orelse req.getHeader("authorization")) |hdr| {
        if (hdr.len > 7 and std.ascii.eqlIgnoreCase(hdr[0..7], "bearer ")) {
            token = std.mem.trim(u8, hdr[7..], " \t");
        }
    }
    if (token.len == 0) {
        if (req.getCookie("pizzaqsr_jwt")) |c| {
            token = c;
        }
    }

    if (token.len > 0) {
        const now_s = auth_jwt.nowSeconds();
        if (auth_jwt.verify(allocator, ctx.jwt_secret, token, now_s)) |claims| {
            signed_in = true;
            display_name = claims.name;
        } else |_| {}
    }

    var out: std.ArrayList(u8) = .empty;
    if (signed_in) {
        try out.appendSlice(allocator,
            \\<div id="user-menu" class="flex items-center">
            \\  <span class="text-slate-600 text-sm">
        );
        try out.appendSlice(allocator, display_name);
        try out.appendSlice(allocator,
            \\</span>
            \\  <a href="/auth/logout" class="ml-3 px-3 py-1 rounded-md bg-slate-100 hover:bg-slate-200 text-sm">Sign out</a>
            \\</div>
        );
    } else {
        try out.appendSlice(allocator,
            \\<div id="user-menu" class="flex items-center">
            \\  <a href="/auth/google" class="px-3 py-1 rounded-md bg-blue-600 text-white hover:bg-blue-700 text-sm">Sign in</a>
            \\</div>
        );
    }
    try res.html(out.items);
}
