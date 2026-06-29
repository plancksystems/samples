
const std = @import("std");
const web = @import("web");
const Ctx = @import("../ctx.zig").Ctx;

const skip_paths: []const []const u8 = &.{
    "/",
    "/index.css",
    "/auth/google",
    "/auth/callback",
    "/auth/me",
    "/auth/user-menu",
    "/auth/logout",
    "/public/*",
    "/payments/webhook",
    "/items",
    "/cart",
    "/cart/badge",
    "/cart/drawer",
    "/cart/events",
    "/products",
    "/products/*",
    "/api/products/*",
    "/categories",
    "/panel/*",
    "/checkout",
    "/pay/*",
    "/orders",
    "/orders/*",
    "/payments/by-order/*",
    "/admin/*",
    "/kitchen",
    "/kitchen/*",
    "/delivery",
    "/delivery/*",
};

pub const JwtAuthMiddleware = struct {
    inner: web.JwtAuthMiddleware,

    pub fn init(ctx: *Ctx) JwtAuthMiddleware {
        return .{
            .inner = web.JwtAuthMiddleware.init(ctx.jwt_secret, skip_paths),
        };
    }

    pub fn middleware(self: *JwtAuthMiddleware) web.Middleware {
        return self.inner.middleware();
    }
};
