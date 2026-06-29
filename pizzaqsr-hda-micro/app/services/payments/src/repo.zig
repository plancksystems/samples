const std = @import("std");
const builtin = @import("builtin");
const planck = @import("planck");
const web = @import("web");
const schnell = @import("schnell");
const Payment = @import("models/payment.zig").Payment;
const parseStringField = @import("json_field.zig").parseStringField;

const is_wasm = builtin.target.cpu.arch == .wasm32;

pub fn findByOrder(client: *planck.Client, allocator: std.mem.Allocator, order_id: i64) !?Payment {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();

    var resp = q.store("payments")
        .where("OrderID", .eq, .{ .int = order_id })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, Payment) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return rows[0];
}

pub fn findByIntent(client: *planck.Client, allocator: std.mem.Allocator, intent_id: []const u8) !?Payment {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();

    var resp = q.store("payments")
        .where("IntentID", .eq, .{ .string = intent_id })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, Payment) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return rows[0];
}

pub fn markStatus(client: *planck.Client, allocator: std.mem.Allocator, intent_id: []const u8, new_status: []const u8) !void {
    var pay = (try findByIntent(client, allocator, intent_id)) orelse return error.NotFound;
    pay.Status = new_status;

    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = try (try q.store("payments")
        .where("PaymentID", .eq, .{ .int = pay.PaymentID })
        .update(pay)).run();
    defer resp.deinit();
}

pub const CreatedIntent = struct {
    intent_id: []const u8,
    client_secret: []const u8,
};

pub fn createIntent(client: *planck.Client, allocator: std.mem.Allocator, io: std.Io, secret_key: []const u8, order_id: i64, amount_minor: i64, currency: []const u8) !CreatedIntent {
    if (comptime is_wasm) {
        const body = try std.fmt.allocPrint(
            allocator,
            "amount={d}&currency={s}&automatic_payment_methods[enabled]=true&metadata[order_id]={d}",
            .{ amount_minor, currency, order_id },
        );
        defer allocator.free(body);

        const headers = try std.fmt.allocPrint(
            allocator,
            "Content-Type: application/x-www-form-urlencoded\r\nAuthorization: Bearer {s}",
            .{secret_key},
        );
        defer allocator.free(headers);

        var out_buf: [16 * 1024]u8 = undefined;
        const resp = web.callServiceWithHeaders(
            "stripe_api",
            "/v1/payment_intents",
            "POST",
            body,
            headers,
            &out_buf,
        ) catch |err| {
            web.log.logFmt(.err, "stripe call failed: {s}", .{@errorName(err)});
            return error.UpstreamFailure;
        };

        if (resp.status < 200 or resp.status >= 300) {
            const trunc = if (resp.body.len > 256) resp.body[0..256] else resp.body;
            web.log.logFmt(.err, "stripe non-2xx: status={d} body={s}", .{ resp.status, trunc });
            return error.UpstreamFailure;
        }

        const intent_id = try parseStringField(allocator, resp.body, "id");
        const client_secret = try parseStringField(allocator, resp.body, "client_secret");

        var del_q = planck.Query.initWithAllocator(client, allocator);
        defer del_q.deinit();
        var del_resp = del_q.store("payments")
            .where("OrderID", .eq, .{ .int = order_id })
            .delete()
            .run() catch null;
        if (del_resp) |*r| r.deinit();

        const pay = Payment{
            .PaymentID = try client.nextSequence("payments_seq"),
            .OrderID = order_id,
            .IntentID = intent_id,
            .ClientSecret = client_secret,
            .Amount = amount_minor,
            .Currency = currency,
            .Status = "pending",
        };

        var q = planck.Query.initWithAllocator(client, allocator);
        defer q.deinit();
        var save_resp = try (try q.store("payments").create(pay)).run();
        defer save_resp.deinit();

        return .{ .intent_id = intent_id, .client_secret = client_secret };
    }

    const body = try std.fmt.allocPrint(
        allocator,
        "amount={d}&currency={s}&automatic_payment_methods[enabled]=true&metadata[order_id]={d}",
        .{ amount_minor, currency, order_id },
    );
    defer allocator.free(body);

    const auth = try std.fmt.allocPrint(allocator, "Bearer {s}", .{secret_key});
    defer allocator.free(auth);

    var resp = try schnell.Client.request(allocator, io, .{
        .method = "POST",
        .url = "https://api.stripe.com/v1/payment_intents",
        .body = body,
        .timeout_ms = 15_000,
        .headers = &.{
            .{ "Authorization", auth },
            .{ "Content-Type", "application/x-www-form-urlencoded" },
        },
    });
    defer resp.deinit();

    if (resp.status < 200 or resp.status >= 300) {
        return error.UpstreamFailure;
    }

    const intent_id = try parseStringField(allocator, resp.body, "id");
    const client_secret = try parseStringField(allocator, resp.body, "client_secret");

    const pay = Payment{
        .PaymentID = try client.nextSequence("payments_seq"),
        .OrderID = order_id,
        .IntentID = intent_id,
        .ClientSecret = client_secret,
        .Amount = amount_minor,
        .Currency = currency,
        .Status = "pending",
    };

    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var save_resp = try (try q.store("payments").create(pay)).run();
    defer save_resp.deinit();

    return .{ .intent_id = intent_id, .client_secret = client_secret };
}
