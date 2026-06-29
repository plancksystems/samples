
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../ctx.zig").Ctx;
const repo = @import("../repo.zig");

const CreateIntentBody = struct {
    order_id: i64,
    amount_minor: i64,
    currency: []const u8,
};

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const body = try req.getBody(allocator, CreateIntentBody);

    const created = repo.createIntent(
        ctx.client,
        allocator,
        req.io.?,
        ctx.stripe_secret_key,
        body.order_id,
        body.amount_minor,
        body.currency,
    ) catch |err| {
        res.status = .bad_gateway;
        const msg = try std.fmt.allocPrint(allocator, "{{\"error\":\"stripe: {s}\"}}", .{@errorName(err)});
        try res.json(msg);
        return;
    };

    const reply = try std.fmt.allocPrint(
        allocator,
        "{{\"intent_id\":\"{s}\",\"client_secret\":\"{s}\"}}",
        .{ created.intent_id, created.client_secret },
    );
    try res.json(reply);
}
