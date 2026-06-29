
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../ctx.zig").Ctx;
const order_model = @import("../models/order.zig");
const repo = @import("../repo.zig");

const Body = struct {
    intent_id: []const u8,
    new_status: []const u8,
};

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const body = try req.getBody(allocator, Body);

    const order = (try repo.findByIntent(ctx.client, allocator, body.intent_id)) orelse return error.NotFound;
    defer repo.freeOrder(allocator, &order);

    const ok = try repo.updateStatus(
        ctx.client,
        allocator,
        order.OrderID,
        order_model.status_awaiting_payment,
        body.new_status,
    );
    if (!ok) {
        try res.json("{\"ok\":true,\"changed\":false}");
        return;
    }

    try res.json("{\"ok\":true,\"changed\":true}");
}
