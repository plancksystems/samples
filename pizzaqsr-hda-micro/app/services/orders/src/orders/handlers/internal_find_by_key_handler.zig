
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const order_key = req.getLocal("order_key") orelse return error.InvalidRequest;
    if (order_key.len == 0) return error.InvalidRequest;

    var order = (try repo.findByKey(ctx.client, allocator, order_key)) orelse return error.NotFound;
    defer repo.freeOrder(allocator, &order);

    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"order_id\":{d},\"order_key\":\"{s}\",\"customer_id\":\"{s}\",\"status\":\"{s}\"}}",
        .{ order.OrderID, order.OrderKey, order.CustomerID, order.Status },
    );
    try res.json(body);
}
