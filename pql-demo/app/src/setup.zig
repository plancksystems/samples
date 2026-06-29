
const std = @import("std");
const builtin = @import("builtin");
const planck = @import("planck");

const db_setup = @import("core/db_setup.zig");

const DEFAULT_CONNECT: []const u8 =
    "127.0.0.1:24000;uid=admin;key=UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=;tls=false";

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;
    defer if (builtin.mode == .Debug) {
        if (gpa.detectLeaks() > 0) std.process.exit(1);
    };

    var threaded: std.Io.Threaded = .init(allocator, .{ .async_limit = .unlimited });
    defer threaded.deinit();
    const io = threaded.io();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const connect: []const u8 = if (args.len >= 2) args[1] else DEFAULT_CONNECT;

    std.debug.print("Connecting to {s}...\n", .{connect});
    const client = try planck.Client.init(allocator, io);
    var auth = try client.connect(connect);
    auth.deinit();
    defer client.deinit();

    std.debug.print("\n=== Setting up schema ===\n", .{});
    const store_counts = db_setup.setupSchema(client);
    std.debug.print("Stores: created={d}, skipped={d}\n", .{ store_counts.created, store_counts.skipped });

    std.debug.print("\n=== Creating secondary indexes ===\n", .{});
    const index_counts = db_setup.createIndexes(client);
    std.debug.print("Indexes: created={d}, skipped={d}\n", .{ index_counts.created, index_counts.skipped });

    std.debug.print("\nSetup complete. Now run planctl to import data from samples/json/.\n", .{});
}
