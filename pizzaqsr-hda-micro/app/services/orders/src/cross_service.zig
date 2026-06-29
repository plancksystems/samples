const std = @import("std");
const builtin = @import("builtin");
const web = @import("web");
const schnell = @import("schnell");

const Ctx = @import("ctx.zig").Ctx;

const is_wasm = builtin.target.cpu.arch == .wasm32;

pub const PaymentIntent = struct {
    intent_id: []const u8,
    client_secret: []const u8,
};

pub fn createPaymentIntent(ctx: *Ctx, allocator: std.mem.Allocator, io: std.Io, order_id: i64, amount_minor: i64, currency: []const u8) !PaymentIntent {
    _ = ctx;
    const body = try std.fmt.allocPrint(
        allocator,
        "{{\"order_id\":{d},\"amount_minor\":{d},\"currency\":\"{s}\"}}",
        .{ order_id, amount_minor, currency },
    );
    defer allocator.free(body);

    const response_body = try callJson(allocator, io, "payments", "/internal/intents", "POST", body);
    defer allocator.free(response_body);

    return .{
        .intent_id = try parseStringField(allocator, response_body, "intent_id"),
        .client_secret = try parseStringField(allocator, response_body, "client_secret"),
    };
}

fn callJson(allocator: std.mem.Allocator, io: std.Io, service: []const u8, path: []const u8, method: []const u8, body: []const u8) ![]const u8 {
    if (comptime is_wasm) {
        var out_buf: [16 * 1024]u8 = undefined;
        const resp = try web.callService(service, path, method, body, &out_buf);
        if (resp.status < 200 or resp.status >= 300) return error.UpstreamFailure;
        return try allocator.dupe(u8, resp.body);
    }

    const url = try std.fmt.allocPrint(
        allocator,
        "http://{s}",
        .{try serviceHostPort(service)},
    );
    defer allocator.free(url);
    const full = try std.fmt.allocPrint(allocator, "{s}{s}", .{ url, path });
    defer allocator.free(full);

    var resp = try schnell.Client.request(allocator, io, .{
        .method = method,
        .url = full,
        .body = body,
        .timeout_ms = 5_000,
        .headers = &.{.{ "Content-Type", "application/json" }},
    });
    defer resp.deinit();

    if (resp.status < 200 or resp.status >= 300) return error.UpstreamFailure;
    return try allocator.dupe(u8, resp.body);
}

fn serviceHostPort(service: []const u8) ![]const u8 {
    if (std.mem.eql(u8, service, "payments")) return "127.0.0.1:3103";
    return error.UnknownUpstream;
}

fn parseStringField(allocator: std.mem.Allocator, body: []const u8, field: []const u8) ![]const u8 {
    var needle_buf: [128]u8 = undefined;
    if (field.len + 3 > needle_buf.len) return error.FieldNameTooLong;
    needle_buf[0] = '"';
    @memcpy(needle_buf[1..][0..field.len], field);
    needle_buf[1 + field.len] = '"';
    const needle = needle_buf[0 .. 2 + field.len];

    const start = std.mem.indexOf(u8, body, needle) orelse return error.FieldMissing;
    var i = start + needle.len;
    while (i < body.len and (body[i] == ' ' or body[i] == ':')) i += 1;
    if (i >= body.len or body[i] != '"') return error.FieldNotString;
    i += 1;
    const value_start = i;
    while (i < body.len and body[i] != '"') i += 1;
    if (i >= body.len) return error.UnterminatedString;
    return try allocator.dupe(u8, body[value_start..i]);
}
