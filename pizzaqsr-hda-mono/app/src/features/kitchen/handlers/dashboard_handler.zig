
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const order_models = @import("../../orders/models/order.zig");
const orders_repo = @import("../../orders/repo.zig");
const KitchenDashboard = @import("../fragments/kitchen_dashboard.zig").KitchenDashboard;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const role = req.getLocal("role") orelse return error.Forbidden;
    if (!std.mem.eql(u8, role, "kitchen") and !std.mem.eql(u8, role, "admin")) return error.Forbidden;

    const statuses = [_][]const u8{
        order_models.status_paid,
        order_models.status_preparing,
        order_models.status_ready,
    };
    const orders = try orders_repo.findByStatuses(ctx.client, allocator, &statuses);
    defer orders_repo.freeOrders(allocator, orders);

    var out: std.ArrayList(u8) = .empty;
    try KitchenDashboard.render(.{
        .orders = orders,
        .sse_init = "@get('http://127.0.0.1:4510/kitchen/events', {openWhenHidden: true})",
    }, &out, allocator);
    try res.html(out.items);
}
