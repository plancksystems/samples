
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const order_model = @import("../models/order.zig");
const StatusUpdateBody = order_model.StatusUpdateBody;
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const order_key = req.getLocal("order_key") orelse return error.InvalidRequest;
    if (order_key.len == 0) return error.InvalidRequest;

    const body = try req.getBody(allocator, StatusUpdateBody);
    if (body.from.len == 0 or body.to.len == 0) return error.InvalidRequest;

    var order = (try repo.findByKey(ctx.client, allocator, order_key)) orelse return error.NotFound;
    defer repo.freeOrder(allocator, &order);

    const ok = try repo.updateStatus(ctx.client, allocator, order.OrderID, body.from, body.to);
    if (!ok) {
        res.status = .conflict;
        try res.json("{\"error\":\"status changed\"}");
        return;
    }

    try res.json("{\"ok\":true}");
}
