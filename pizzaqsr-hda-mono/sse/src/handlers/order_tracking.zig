const std = @import("std");
const Allocator = std.mem.Allocator;
const schnell = @import("schnell");
const ssehub = @import("ssehub");

const hub_mod = @import("../hub.zig");

const log = std.log.scoped(.pizzaqsr_sse);

fn parseLastEventId(header_value: ?[]const u8) u64 {
    const value = header_value orelse return 0;
    const trimmed = std.mem.trim(u8, value, " \t");
    if (trimmed.len == 0) return 0;
    return std.fmt.parseInt(u64, trimmed, 10) catch 0;
}

pub fn handle(ctx_ptr: ?*anyopaque, handler_allocator: Allocator, req: *const schnell.Request, writer: *std.Io.Writer) anyerror!void {
    const ctx: *hub_mod.HubCtx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const order_key = req.getLocal("order_key") orelse return error.InvalidRequest;
    if (order_key.len == 0) return error.InvalidRequest;

    if (!ctx.bus.canAcceptSubscriber()) {
        log.warn("order_tracking: subscriber cap reached, rejecting", .{});
        return error.ServiceUnavailable;
    }

    const topic = try std.fmt.allocPrint(handler_allocator, "order:{s}", .{order_key});
    defer handler_allocator.free(topic);

    const last_event_id = parseLastEventId(req.getHeader("Last-Event-ID"));

    log.info("order_tracking: subscribe topic='{s}' last_event_id={d}", .{ topic, last_event_id });
    defer log.info("order_tracking: exit topic='{s}'", .{topic});

    try ssehub.wire.writeHeaders(writer);
    try ssehub.wire.writeRetry(writer, ctx.bus.config.retry_ms);
    try writer.flush();

    const sub = try ssehub.Subscriber.init(handler_allocator, writer, ctx.io, ssehub.DEFAULT_QUEUE_SIZE);
    defer sub.deinit();

    try ctx.bus.subscribe(topic, sub, .{ .last_event_id = last_event_id });
    defer ctx.bus.unsubscribe(topic, sub);

    sub.runWriter();
}
