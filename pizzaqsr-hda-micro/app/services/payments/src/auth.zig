
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const Middleware = web.Middleware;

pub const IdentityMiddleware = struct {
    pub fn execute(_: *IdentityMiddleware, _: std.mem.Allocator, req: *const Request, _: *Response) !Middleware.Action {
        var customer_id: []const u8 = "";
        if (req.getLocal("customer_id")) |v| {
            customer_id = v;
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

        if (req.getLocal("role") == null) {
            const role: []const u8 = if (std.mem.eql(u8, customer_id, "demo-customer"))
                "admin"
            else
                "customer";
            try req.setLocal("role", role);
        }

        return .next;
    }

    pub fn middleware(self: *IdentityMiddleware) Middleware {
        return Middleware.from(IdentityMiddleware, self);
    }
};
