
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const order_models = @import("../../orders/models/order.zig");
const orders_repo = @import("../../orders/repo.zig");
const DeliveryDashboard = @import("../fragments/delivery_dashboard.zig").DeliveryDashboard;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const role = req.getLocal("role") orelse return error.Forbidden;
    if (!std.mem.eql(u8, role, "delivery") and !std.mem.eql(u8, role, "admin")) return error.Forbidden;

    const statuses = [_][]const u8{
        order_models.status_ready,
        order_models.status_out_for_delivery,
    };
    const orders = try orders_repo.findByStatuses(ctx.client, allocator, &statuses);
    defer orders_repo.freeOrders(allocator, orders);

    var out: std.ArrayList(u8) = .empty;
    try DeliveryDashboard.render(.{
        .orders = orders,
        .sse_init = "@get('http://127.0.0.1:4510/delivery/events', {openWhenHidden: true})",
    }, &out, allocator);
    try res.html(out.items);
}
