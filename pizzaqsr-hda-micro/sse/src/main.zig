const std = @import("std");
const schnell = @import("schnell");
const ssehub = @import("ssehub");

const hub = @import("hub.zig");
const order_tracking = @import("handlers/order_tracking.zig");
const kitchen = @import("handlers/kitchen.zig");
const delivery = @import("handlers/delivery.zig");

const log = std.log.scoped(.pizzaqsr_sse);

pub const PLANCK_CONN: []const u8 = "127.0.0.1:24102;uid=admin;key=UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=;tls=false";

const SseConfig = struct {
    http: struct {
        host: []const u8 = "127.0.0.1",
        port: u16 = 4511,
    } = .{},
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cfg: SseConfig = .{};

    var bus = ssehub.EventBus.init(allocator, io, .{
        .heartbeat_interval_ms = 15_000,
        .retry_ms = 3000,
        .subscriber_queue_size = 256,
    });
    defer bus.deinit();
    try bus.registerTopic("kitchen", .{ .replay_buffer_size = 50 });
    try bus.registerTopic("delivery", .{ .replay_buffer_size = 50 });
    try bus.start();

    var hub_ctx = hub.HubCtx.init(allocator, io, &bus);
    defer hub_ctx.deinit();

    const watch = try ssehub.WatchClient.init(allocator, io, PLANCK_CONN, &.{"orders"});
    defer watch.deinit();
    watch.onFrame(hub.processOrderFrame, &hub_ctx);
    try watch.start();
    log.info("connected to planck at {s}", .{PLANCK_CONN});

    var app = try schnell.App.init(allocator, .{
        .host = cfg.http.host,
        .port = cfg.http.port,
    });
    defer app.deinit();

    var cors = schnell.CorsMiddleware.init(.{
        .allow_origin = "*",
        .allow_methods = "GET, OPTIONS",
        .allow_headers = "*",
    });
    try app.use(cors.middleware());

    try app.routeStreaming(.get, "/orders/:order_key/events", order_tracking.handle, &hub_ctx);
    try app.routeStreaming(.get, "/kitchen/events", kitchen.handle, &hub_ctx);
    try app.routeStreaming(.get, "/delivery/events", delivery.handle, &hub_ctx);

    log.info("pizzaqsr_sse: HTTP http://{s}:{d}", .{ cfg.http.host, cfg.http.port });
    try app.run(io);
}
