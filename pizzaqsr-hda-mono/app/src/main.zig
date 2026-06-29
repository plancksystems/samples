const std = @import("std");
const builtin = @import("builtin");
const schnell = @import("schnell");
const planck = @import("planck");

const Ctx = @import("core/ctx.zig").Ctx;
const auth_middleware = @import("core/auth/middleware.zig");
const customer_id_mw = @import("core/auth/customer_id.zig");
const auth_routes = @import("core/auth/routes.zig");
const cart_routes = @import("features/cart/routes.zig");
const products_routes = @import("features/products/routes.zig");
const orders_routes = @import("features/orders/routes.zig");
const payments_routes = @import("features/payments/routes.zig");
const checkout_routes = @import("features/checkout/routes.zig");
const users_routes = @import("features/users/routes.zig");
const kitchen_routes = @import("features/kitchen/routes.zig");
const delivery_routes = @import("features/delivery/routes.zig");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;
    defer if (builtin.mode == .Debug) {
        if (gpa.detectLeaks() > 0) std.process.exit(1);
    };

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const client = try planck.Client.init(allocator, io);
    defer client.deinit();
    var auth = try client.connect("127.0.0.1:24010;uid=admin;key=UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=;tls=false");
    auth.deinit();
    std.debug.print("Connected to Planck on port 24010\n", .{});

    var ctx = Ctx{
        .client = client,
        .jwt_secret = "pizzaqsr-dev-only-replace-before-prod",
        .jwt_ttl_seconds = 30 * 24 * 60 * 60,
        .google_client_id = "",
        .google_client_secret = "",
        .google_redirect_uri = "",
        .stripe_publishable_key = "",
        .stripe_secret_key = "",
        .stripe_webhook_secret = "",
    };

    var app = try schnell.App.init(allocator, .{
        .host = "127.0.0.1",
        .port = 4000,
        .static_dir = "/Users/kamlesh/planckapps/samples/pizzaqsr-hda-mono/app/public",
    });
    defer app.deinit();

    var cors = schnell.CorsMiddleware.init(.{});
    try app.use(cors.middleware());

    var jwt_mw = auth_middleware.JwtAuthMiddleware.init(&ctx);
    try app.use(jwt_mw.middleware());

    var cid_mw = customer_id_mw.CustomerIdMiddleware.init(&ctx);
    try app.use(cid_mw.middleware());

    try auth_routes.register(&app, &ctx);
    try products_routes.register(&app, &ctx);
    try cart_routes.register(&app, &ctx);
    try orders_routes.register(&app, &ctx);
    try payments_routes.register(&app, &ctx);
    try checkout_routes.register(&app, &ctx);
    try users_routes.register(&app, &ctx);
    try kitchen_routes.register(&app, &ctx);
    try delivery_routes.register(&app, &ctx);

    std.debug.print("pizzaqsr dev server running on http://127.0.0.1:4000\n", .{});
    try app.run(io);
}
