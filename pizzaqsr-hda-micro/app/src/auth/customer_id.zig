const std = @import("std");
const builtin = @import("builtin");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const Middleware = web.Middleware;

const Ctx = @import("../ctx.zig").Ctx;
const users_repo = @import("../users/repo.zig");

pub const CustomerIdMiddleware = struct {
    ctx: *Ctx,

    pub fn init(ctx: *Ctx) CustomerIdMiddleware {
        return .{ .ctx = ctx };
    }

    pub fn execute(self: *CustomerIdMiddleware, allocator: std.mem.Allocator, req: *const Request, _: *Response) !Middleware.Action {
        var customer_id: []const u8 = "";
        if (req.getLocal("customer_id")) |v| {
            customer_id = v;
        } else if (req.getLocal("user_id")) |uid| {
            customer_id = uid;
            try req.setLocal("customer_id", uid);
        } else if (req.getQuery("customer_id")) |q| {
            if (q.len > 0) {
                customer_id = q;
                try req.setLocal("customer_id", q);
            }
        } else if (req.getCookie("pizzaqsr_dev_customer")) |c| {
            if (c.len > 0) {
                customer_id = c;
                try req.setLocal("customer_id", c);
            }
        }
        if (customer_id.len == 0) {
            customer_id = "demo-customer";
            try req.setLocal("customer_id", customer_id);
        }

        if (req.getLocal("role") != null) return .next;

        var role: []const u8 = "customer";
        if (users_repo.findByGoogleSub(self.ctx.client, allocator, customer_id)) |maybe| {
            if (maybe) |user| role = user.Role;
        } else |_| {
        }

        if (std.mem.eql(u8, role, "customer") and std.mem.eql(u8, customer_id, "demo-customer")) {
            role = "admin";
        }

        try req.setLocal("role", role);
        return .next;
    }

    pub fn middleware(self: *CustomerIdMiddleware) Middleware {
        return Middleware.from(CustomerIdMiddleware, self);
    }
};
