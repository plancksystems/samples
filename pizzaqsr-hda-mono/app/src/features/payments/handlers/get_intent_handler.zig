
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const orders_repo = @import("../../orders/repo.zig");
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const customer_id = req.getLocal("customer_id") orelse return error.MissingCustomer;
    if (customer_id.len == 0) return error.MissingCustomer;

    const order_key = req.getLocal("order_key") orelse return error.InvalidRequest;
    if (order_key.len == 0) return error.InvalidRequest;

    var order = (try orders_repo.findByKey(ctx.client, allocator, order_key)) orelse {
        web.log.logFmt(.warn, "intent: 404 — findByKey returned null for OrderKey='{s}'", .{order_key});

        if (orders_repo.findByCustomer(ctx.client, allocator, customer_id, 0)) |all| {
            defer orders_repo.freeOrders(allocator, all);
            web.log.logFmt(.warn, "intent: customer '{s}' has {d} order(s) in store:", .{ customer_id, all.len });
            for (all, 0..) |o, i| {
                web.log.logFmt(.warn, "  [{d}] OrderID={d} OrderKey='{s}' Status='{s}'", .{ i, o.OrderID, o.OrderKey, o.Status });
            }
        } else |err| {
            web.log.logFmt(.warn, "intent: findByCustomer also failed: {s}", .{@errorName(err)});
        }

        return error.NotFound;
    };
    defer orders_repo.freeOrder(allocator, &order);
    if (!std.mem.eql(u8, order.CustomerID, customer_id)) {
        web.log.logFmt(.warn, "intent: 404 — CustomerID mismatch order='{s}' req='{s}'", .{ order.CustomerID, customer_id });
        return error.NotFound;
    }

    const pay = (try repo.findByOrder(ctx.client, allocator, order.OrderID)) orelse {
        web.log.logFmt(.warn, "intent: 404 — findByOrder returned null for OrderID={d}", .{order.OrderID});
        return error.NotFound;
    };

    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"client_secret\":\"{s}\",\"publishable_key\":\"{s}\"}}",
        .{ pay.ClientSecret, ctx.stripe_publishable_key },
    );
    try res.json(body);
}
