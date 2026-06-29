
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../ctx.zig").Ctx;
const cross_service = @import("../cross_service.zig");
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const order_key = req.getLocal("order_key") orelse return error.InvalidRequest;
    if (order_key.len == 0) return error.InvalidRequest;

    const order_ref = (try cross_service.findOrderByKey(ctx, allocator, req.io.?, order_key)) orelse return error.NotFound;
    if (!std.mem.eql(u8, order_ref.customer_id, customer_id)) return error.NotFound;

    const pay = (try repo.findByOrder(ctx.client, allocator, order_ref.order_id)) orelse return error.NotFound;

    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"client_secret\":\"{s}\",\"publishable_key\":\"{s}\"}}",
        .{ pay.ClientSecret, ctx.stripe_publishable_key },
    );
    try res.json(body);
}
