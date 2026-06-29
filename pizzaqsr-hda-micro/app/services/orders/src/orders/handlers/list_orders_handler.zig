
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const OrderList = @import("../fragments/order_list.zig").OrderList;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const orders = try repo.findByCustomer(ctx.client, allocator, customer_id, 50);
    defer repo.freeOrders(allocator, orders);

    var out: std.ArrayList(u8) = .empty;
    try OrderList.render(.{ .orders = orders }, &out, allocator);
    try res.html(out.items);
}
