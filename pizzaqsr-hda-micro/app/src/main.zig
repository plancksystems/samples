const std = @import("std");
const builtin = @import("builtin");
const schnell = @import("schnell");
const planck = @import("planck");

const Ctx = @import("ctx.zig").Ctx;
const auth_middleware = @import("auth/middleware.zig");
const customer_id_mw = @import("auth/customer_id.zig");
const auth_routes = @import("auth/routes.zig");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;
    defer if (builtin.mode == .Debug) {
        if (gpa.detectLeaks() > 0) std.process.exit(1);
    };

    var threaded: std.Io.Threaded = .init(allocator, .{ .async_limit = .unlimited });
    defer threaded.deinit();
    const io = threaded.io();

    const client = try planck.Client.init(allocator, io);
    var auth_resp = try client.connect("127.0.0.1:24105;uid=admin;key=UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=;tls=false");
    auth_resp.deinit();

    var ctx = Ctx{
        .client = client,
        .jwt_secret = "pizzaqsr-dev-only-replace-before-prod",
    };

    const providers_yaml = std.fs.cwd().readFileAlloc(allocator, "providers.yaml", 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => try allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(providers_yaml);

    var app = try schnell.App.init(allocator, .{
        .host = "127.0.0.1",
        .port = 4100,
        .static_dir = "public",
    }, providers_yaml);
    defer app.deinit();

    var cors = schnell.CorsMiddleware.init(.{});
    try app.use(cors.middleware());

    var jwt_mw = auth_middleware.JwtAuthMiddleware.init(&ctx);
    try app.use(jwt_mw.middleware());

    var cid_mw = customer_id_mw.CustomerIdMiddleware.init(&ctx);
    try app.use(cid_mw.middleware());

    try auth_routes.register(&app, &ctx);

    std.debug.print("shell on http://127.0.0.1:4100 (Caddy fronts the stack)\n", .{});
    try app.run(io);
}
