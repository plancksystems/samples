
const std = @import("std");
const planck = @import("planck");
const web = @import("web");
const User = @import("models/user.zig").User;
const role_admin = @import("models/user.zig").role_admin;
const role_customer = @import("models/user.zig").role_customer;

pub fn findByGoogleSub(client: *planck.Client, allocator: std.mem.Allocator, sub: []const u8) !?User {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = q.store("users")
        .where("GoogleSub", .eq, .{ .string = sub })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, User) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return rows[0];
}

pub fn findById(client: *planck.Client, allocator: std.mem.Allocator, user_id: i64) !?User {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = q.store("users")
        .where("UserID", .eq, .{ .int = user_id })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, User) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return rows[0];
}

pub fn findByEmail(client: *planck.Client, allocator: std.mem.Allocator, email: []const u8) !?User {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = q.store("users")
        .where("Email", .eq, .{ .string = email })
        .limit(1)
        .run() catch |err| switch (err) {
        error.InvalidResponse => return null,
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, User) catch return null;
    defer allocator.free(rows);
    if (rows.len == 0) return null;
    return rows[0];
}

pub fn listAll(client: *planck.Client, allocator: std.mem.Allocator) ![]User {
    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = q.store("users").run() catch |err| switch (err) {
        error.InvalidResponse => return &.{},
        else => return err,
    };
    defer resp.deinit();

    const rows = resp.decode(allocator, User) catch return &.{};
    const out = try allocator.alloc(User, rows.len);
    for (rows, 0..) |r, i| out[i] = r;
    allocator.free(rows);
    return out;
}

pub fn count(client: *planck.Client, allocator: std.mem.Allocator) !u32 {
    const all = listAll(client, allocator) catch return 0;
    defer allocator.free(all);
    return @intCast(all.len);
}

pub fn create(client: *planck.Client, allocator: std.mem.Allocator, user: User) !User {
    var to_save = user;
    to_save.UserID = try client.nextSequence("users_seq");

    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = try (try q.store("users").create(to_save)).run();
    defer resp.deinit();
    return to_save;
}

pub fn updateRole(client: *planck.Client, allocator: std.mem.Allocator, user_id: i64, new_role: []const u8) !void {
    var user = (try findById(client, allocator, user_id)) orelse return error.NotFound;
    user.Role = new_role;

    var q = planck.Query.initWithAllocator(client, allocator);
    defer q.deinit();
    var resp = try (try q.store("users")
        .where("UserID", .eq, .{ .int = user_id })
        .update(user)).run();
    defer resp.deinit();
}

pub fn upsertFromOAuth(
    client: *planck.Client,
    allocator: std.mem.Allocator,
    sub: []const u8,
    email: []const u8,
    name: []const u8
) !User {
    if (try findByGoogleSub(client, allocator, sub)) |existing| {
        var refreshed = existing;
        refreshed.Email = email;
        refreshed.Name = name;
        var q = planck.Query.initWithAllocator(client, allocator);
        defer q.deinit();
        var resp = try (try q.store("users")
            .where("UserID", .eq, .{ .int = existing.UserID })
            .update(refreshed)).run();
        defer resp.deinit();
        return refreshed;
    }

    const existing_count = count(client, allocator) catch 0;
    const role = if (existing_count == 0) role_admin else role_customer;

    const created_at_s = web.sys.nowUnixSeconds();
    const created_at = try std.fmt.allocPrint(allocator, "{d}", .{created_at_s});

    return try create(client, allocator, .{
        .GoogleSub = sub,
        .Email = email,
        .Name = name,
        .Role = role,
        .Status = "active",
        .CreatedAt = created_at,
        .UpdatedAt = created_at,
    });
}
