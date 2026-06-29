
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const orders_repo = @import("../../orders/repo.zig");
const PayPage = @import("../fragments/pay_page.zig").PayPage;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const order_key = req.getLocal("order_key") orelse return error.InvalidRequest;
    if (order_key.len == 0) return error.InvalidRequest;

    var order = (try orders_repo.findByKey(ctx.client, allocator, order_key)) orelse return error.NotFound;
    defer orders_repo.freeOrder(allocator, &order);
    if (!std.mem.eql(u8, order.CustomerID, customer_id)) return error.NotFound;

    var out: std.ArrayList(u8) = .empty;
    try PayPage.render(.{ .order = order }, &out, allocator);
    try res.html(out.items);
}
