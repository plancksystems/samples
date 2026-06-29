
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const OrderDetail = @import("../fragments/order_detail.zig").OrderDetail;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse "";
    if (customer_id.len == 0) return error.MissingCustomer;

    const order_key = req.getLocal("order_key") orelse "";
    if (order_key.len == 0) return error.InvalidRequest;

    var order = (try repo.findByKey(ctx.client, allocator, order_key)) orelse return error.NotFound;
    defer repo.freeOrder(allocator, &order);

    if (!std.mem.eql(u8, order.CustomerID, customer_id)) return error.NotFound;

    var out: std.ArrayList(u8) = .empty;
    try OrderDetail.render(.{ .order = order }, &out, allocator);
    try res.html(out.items);
}
