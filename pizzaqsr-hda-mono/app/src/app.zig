const std = @import("std");
const planck = @import("planck");
const web = @import("web");

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

extern fn host_respond(ptr: [*]const u8, len: u32) void;

var app: web.WasmApp = undefined;
var client: planck.Client = undefined;
var ctx: Ctx = undefined;
var cors: web.CorsMiddleware = undefined;
var jwt_mw: auth_middleware.JwtAuthMiddleware = undefined;
var cid_mw: customer_id_mw.CustomerIdMiddleware = undefined;

export fn init(config_ptr: ?[*]const u8, config_len: u32) i32 {
    const allocator = std.heap.wasm_allocator;
    client = planck.Client.init(allocator, 4 * 1024 * 1024) catch return -1;

    ctx = .{
        .client = &client,
        .jwt_secret = "pizzaqsr-dev-only-replace-before-prod",
        .jwt_ttl_seconds = 30 * 24 * 60 * 60,
        .google_client_id = "",
        .google_client_secret = "",
        .google_redirect_uri = "",
        .stripe_publishable_key = "",
        .stripe_secret_key = "",
        .stripe_webhook_secret = "",
    };

    const yaml_text = if (config_ptr) |ptr| ptr[0..config_len] else &.{};
    app = web.WasmApp.init(allocator, .{}, yaml_text) catch return -1;

    ctx = .{
        .client = &client,
        .jwt_secret = "pizzaqsr-dev-only-replace-before-prod",
        .jwt_ttl_seconds = 30 * 24 * 60 * 60,
        .google_client_id = "",
        .google_client_secret = "",
        .google_redirect_uri = "",
        .stripe_publishable_key = "",
        .stripe_secret_key = "",
        .stripe_webhook_secret = "",
    };

    if(app.providers) |providers| {
        if (providers.stripe) |stripe| {
            ctx.stripe_publishable_key = allocator.dupe(u8, stripe.publishable_key) catch return -1;
            ctx.stripe_secret_key = allocator.dupe(u8, stripe.secret_key) catch return -1;
            ctx.stripe_webhook_secret = allocator.dupe(u8, stripe.webhook_secret) catch return -1;
        }
        if (providers.google_oauth) |google| {
            ctx.google_client_id = allocator.dupe(u8, google.client_id) catch return -1;
            ctx.google_client_secret = allocator.dupe(u8, google.client_secret) catch return -1;
            ctx.google_redirect_uri = allocator.dupe(u8, google.redirect_uri) catch return -1;
        }
    }

    cors = web.CorsMiddleware.init(.{});
    app.use(cors.middleware()) catch return -1;

    jwt_mw = auth_middleware.JwtAuthMiddleware.init(&ctx);
    app.use(jwt_mw.middleware()) catch return -1;

    cid_mw = customer_id_mw.CustomerIdMiddleware.init(&ctx);
    app.use(cid_mw.middleware()) catch return -1;

    auth_routes.register(&app, &ctx) catch return -1;
    products_routes.register(&app, &ctx) catch return -1;
    cart_routes.register(&app, &ctx) catch return -1;
    orders_routes.register(&app, &ctx) catch return -1;
    payments_routes.register(&app, &ctx) catch return -1;
    checkout_routes.register(&app, &ctx) catch return -1;
    users_routes.register(&app, &ctx) catch return -1;
    kitchen_routes.register(&app, &ctx) catch return -1;
    delivery_routes.register(&app, &ctx) catch return -1;

    app.onResponse(struct {
        fn hook(req: *const web.Request, res: *web.Response, resp_buf: []u8) void {
            _ = req;
            const bytes = res.toBytes(resp_buf) catch return;
            host_respond(bytes.ptr, @intCast(bytes.len));
        }
    }.hook);

    return 0;
}

export fn process(req_ptr: [*]const u8, req_len: u32) i32 {
    app.process(req_ptr, req_len) catch return -1;
    return 0;
}
