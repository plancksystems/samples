const std = @import("std");
const schnell = @import("schnell");
const ssehub = @import("ssehub");

const hub = @import("hub.zig");
const notes_feed = @import("handlers/notes_feed.zig");
const publish_notes = @import("publish_notes.zig");

const log = std.log.scoped(.notes_spa_micro_sse);

pub const PLANCK_CONN: []const u8 = "127.0.0.1:24002;uid=admin;key=UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=;tls=false";

const WATCH_STORES = [_][]const u8{"notes"};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var bus = ssehub.EventBus.init(allocator, io, .{
        .heartbeat_interval_ms = 15_000,
        .retry_ms = 3000,
        .subscriber_queue_size = 256,
    });
    defer bus.deinit();
    try bus.registerTopic(publish_notes.TOPIC, .{ .replay_buffer_size = 200 });
    try bus.start();

    var hub_ctx = hub.HubCtx.init(allocator, io, &bus);
    defer hub_ctx.deinit();

    const watch = try ssehub.WatchClient.init(allocator, io, PLANCK_CONN, &WATCH_STORES);
    defer watch.deinit();
    watch.onFrame(hub.processFrame, &hub_ctx);
    try watch.start();
    log.info("notes_spa_micro_sse: watching planck at {s}", .{PLANCK_CONN});

    var app = try schnell.App.init(allocator, .{
        .host = "127.0.0.1",
        .port = 4502,
    });
    defer app.deinit();

    var cors = schnell.CorsMiddleware.init(.{
        .allow_origin = "*",
        .allow_methods = "GET, OPTIONS",
        .allow_headers = "*",
    });
    try app.use(cors.middleware());

    try app.routeStreaming(.get, "/events", notes_feed.handle, &hub_ctx);

    log.info("notes_spa_micro_sse: HTTP http://127.0.0.1:4502", .{});
    try app.run(io);
}
