
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const orders_repo = @import("../../orders/repo.zig");
const order_models = @import("../../orders/models/order.zig");
const repo = @import("../repo.zig");

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    if (ctx.stripe_webhook_secret.len == 0) {
        res.status = .internal_server_error;
        try res.write("webhook secret not configured");
        return;
    }

    const sig_header = req.getHeader("Stripe-Signature") orelse
        req.getHeader("stripe-signature") orelse
        return error.InvalidRequest;

    if (!verifyStripeSignature(allocator, ctx.stripe_webhook_secret, sig_header, req.body)) {
        res.status = .unauthorized;
        try res.write("invalid signature");
        return;
    }

    const event_type = parseStringField(req.body, "type") orelse return error.InvalidRequest;
    const data_at = std.mem.indexOf(u8, req.body, "\"data\"") orelse return error.InvalidRequest;
    const intent_id = parseStringField(req.body[data_at..], "id") orelse return error.InvalidRequest;

    if (std.mem.eql(u8, event_type, "payment_intent.succeeded")) {
        try repo.markStatus(ctx.client, allocator, intent_id, "succeeded");
        const pay = (try repo.findByIntent(ctx.client, allocator, intent_id)) orelse return error.NotFound;
        _ = try orders_repo.updateStatus(
            ctx.client,
            allocator,
            pay.OrderID,
            order_models.status_awaiting_payment,
            order_models.status_paid,
        );
    } else if (std.mem.eql(u8, event_type, "payment_intent.payment_failed")) {
        try repo.markStatus(ctx.client, allocator, intent_id, "failed");
        const pay = (try repo.findByIntent(ctx.client, allocator, intent_id)) orelse return error.NotFound;
        _ = try orders_repo.updateStatus(
            ctx.client,
            allocator,
            pay.OrderID,
            order_models.status_awaiting_payment,
            order_models.status_cancelled,
        );
    }

    try res.json("{\"received\":true}");
}

fn verifyStripeSignature(
    allocator: std.mem.Allocator,
    secret: []const u8,
    header: []const u8,
    body: []const u8
) bool {
    var ts: []const u8 = "";
    var v1_sigs: std.ArrayList([]const u8) = .empty;
    defer v1_sigs.deinit(allocator);

    var parts = std.mem.splitScalar(u8, header, ',');
    while (parts.next()) |part| {
        const eq = std.mem.indexOfScalar(u8, part, '=') orelse continue;
        const key = part[0..eq];
        const value = part[eq + 1 ..];
        if (std.mem.eql(u8, key, "t")) {
            ts = value;
        } else if (std.mem.eql(u8, key, "v1")) {
            v1_sigs.append(allocator, value) catch return false;
        }
    }
    if (ts.len == 0 or v1_sigs.items.len == 0) return false;

    const signed = std.fmt.allocPrint(allocator, "{s}.{s}", .{ ts, body }) catch return false;
    defer allocator.free(signed);

    const HmacSha256 = std.crypto.auth.hmac.sha2.HmacSha256;
    var mac: [HmacSha256.mac_length]u8 = undefined;
    HmacSha256.create(&mac, signed, secret);

    var hex_buf: [HmacSha256.mac_length * 2]u8 = undefined;
    const hex_chars = "0123456789abcdef";
    for (mac, 0..) |b, i| {
        hex_buf[i * 2] = hex_chars[b >> 4];
        hex_buf[i * 2 + 1] = hex_chars[b & 0xF];
    }
    const expected_hex: []const u8 = hex_buf[0..];

    for (v1_sigs.items) |sig| {
        if (sig.len != expected_hex.len) continue;
        var diff: u8 = 0;
        for (sig, expected_hex) |a, b| diff |= a ^ b;
        if (diff == 0) return true;
    }
    return false;
}

fn parseStringField(body: []const u8, field: []const u8) ?[]const u8 {
    var needle_buf: [128]u8 = undefined;
    if (field.len + 3 > needle_buf.len) return null;
    needle_buf[0] = '"';
    @memcpy(needle_buf[1..][0..field.len], field);
    needle_buf[1 + field.len] = '"';
    const needle = needle_buf[0 .. 2 + field.len];

    const start = std.mem.indexOf(u8, body, needle) orelse return null;
    var i = start + needle.len;
    while (i < body.len and (body[i] == ' ' or body[i] == ':')) i += 1;
    if (i >= body.len or body[i] != '"') return null;
    i += 1;
    const value_start = i;
    while (i < body.len and body[i] != '"') i += 1;
    if (i >= body.len) return null;
    return body[value_start..i];
}
