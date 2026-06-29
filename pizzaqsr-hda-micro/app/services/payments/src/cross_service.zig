const std = @import("std");
const builtin = @import("builtin");
const web = @import("web");
const schnell = @import("schnell");

const Ctx = @import("ctx.zig").Ctx;
const parseStringField = @import("json_field.zig").parseStringField;

const is_wasm = builtin.target.cpu.arch == .wasm32;

pub fn advanceOrderStatus(ctx: *Ctx, allocator: std.mem.Allocator, io: std.Io, intent_id: []const u8, new_status: []const u8) !void {
    _ = ctx;
    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"intent_id\":\"{s}\",\"new_status\":\"{s}\"}}",
        .{ intent_id, new_status },
    );
    defer allocator.free(body);

    const response_body = try callJson(allocator, io, "orders", "/internal/status-from-payment", "POST", body);
    allocator.free(response_body);
}

pub const OrderRef = struct {
    order_id: i64,
    order_key: []const u8,
    customer_id: []const u8,
    status: []const u8,
};

pub fn findOrderByKey(ctx: *Ctx, allocator: std.mem.Allocator, io: std.Io, order_key: []const u8) !?OrderRef {
    _ = ctx;
    const path = try std.fmt.allocPrint(allocator, "/internal/orders/by-key/{s}", .{order_key});
    defer allocator.free(path);

    const body = callJson(allocator, io, "orders", path, "GET", "") catch |err| switch (err) {
        error.UpstreamFailure => return null,
        else => return err,
    };
    defer allocator.free(body);

    return .{
        .order_id = try parseIntField(body, "order_id"),
        .order_key = try parseStringField(allocator, body, "order_key"),
        .customer_id = try parseStringField(allocator, body, "customer_id"),
        .status = try parseStringField(allocator, body, "status"),
    };
}

fn callJson(allocator: std.mem.Allocator, io: std.Io, service: []const u8, path: []const u8, method: []const u8, body: []const u8) ![]const u8 {
    if (comptime is_wasm) {
        var out_buf: [16 * 1024]u8 = undefined;
        const resp = try web.callService(service, path, method, body, &out_buf);
        if (resp.status < 200 or resp.status >= 300) return error.UpstreamFailure;
        return try allocator.dupe(u8, resp.body);
    }

    const host_port = try serviceHostPort(service);
    const url = try std.fmt.allocPrint(allocator, "http://{s}{s}", .{ host_port, path });
    defer allocator.free(url);

    var resp = try schnell.Client.request(allocator, io, .{
        .method = method,
        .url = url,
        .body = body,
        .timeout_ms = 5_000,
        .headers = &.{.{ "Content-Type", "application/json" }},
    });
    defer resp.deinit();

    if (resp.status < 200 or resp.status >= 300) return error.UpstreamFailure;
    return try allocator.dupe(u8, resp.body);
}

fn serviceHostPort(service: []const u8) ![]const u8 {
    if (std.mem.eql(u8, service, "orders")) return "127.0.0.1:3102";
    return error.UnknownUpstream;
}

fn parseIntField(body: []const u8, field: []const u8) !i64 {
    var needle_buf: [128]u8 = undefined;
    if (field.len + 3 > needle_buf.len) return error.FieldNameTooLong;
    needle_buf[0] = '"';
    @memcpy(needle_buf[1..][0..field.len], field);
    needle_buf[1 + field.len] = '"';
    const needle = needle_buf[0 .. 2 + field.len];

    const start = std.mem.indexOf(u8, body, needle) orelse return error.FieldMissing;
    var i = start + needle.len;
    while (i < body.len and (body[i] == ' ' or body[i] == ':')) i += 1;
    const num_start = i;
    while (i < body.len and (std.ascii.isDigit(body[i]) or body[i] == '-')) i += 1;
    if (i == num_start) return error.FieldNotInt;
    return try std.fmt.parseInt(i64, body[num_start..i], 10);
}
