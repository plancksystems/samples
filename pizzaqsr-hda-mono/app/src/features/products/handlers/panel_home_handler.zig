
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const PanelHome = @import("../fragments/panel_home.zig").PanelHome;

pub fn handle(_: ?*anyopaque, allocator: std.mem.Allocator, _: *const Request, res: *Response) !void {
    var out: std.ArrayList(u8) = .empty;
    try PanelHome.render(.{}, &out, allocator);
    try res.html(out.items);
}
