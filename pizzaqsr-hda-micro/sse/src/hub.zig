
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const bson = @import("bson");
const ssehub = @import("ssehub");

const order_models = @import("models/order.zig");
const Order = order_models.Order;

const render_tracking = @import("render_tracking.zig");
const render_kitchen = @import("render_kitchen.zig");
const render_delivery = @import("render_delivery.zig");

const log = std.log.scoped(.pizzaqsr_sse);

pub const HubCtx = struct {
    allocator: Allocator,
    io: Io,
    bus: *ssehub.EventBus,
    store: OrderStore,

    pub fn init(allocator: Allocator, io: Io, bus: *ssehub.EventBus) HubCtx {
        return .{
            .allocator = allocator,
            .io = io,
            .bus = bus,
            .store = OrderStore.init(allocator, io),
        };
    }

    pub fn deinit(self: *HubCtx) void {
        self.store.deinit();
    }
};

pub const OrderStore = struct {
    allocator: Allocator,
    io: Io,
    map: std.StringHashMapUnmanaged(Entry),
    mutex: Io.Mutex,

    pub const Entry = struct {
        body: []u8,
        status: []u8,
    };

    pub fn init(allocator: Allocator, io: Io) OrderStore {
        return .{
            .allocator = allocator,
            .io = io,
            .map = .empty,
            .mutex = .init,
        };
    }

    pub fn deinit(self: *OrderStore) void {
        self.mutex.lockUncancelable(self.io);
        defer self.mutex.unlock(self.io);
        var it = self.map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.body);
            self.allocator.free(entry.value_ptr.status);
        }
        self.map.deinit(self.allocator);
    }

    pub fn put(self: *OrderStore, order_key: []const u8, body: []const u8, status: []const u8) !void {
        self.mutex.lockUncancelable(self.io);
        defer self.mutex.unlock(self.io);

        const body_copy = try self.allocator.dupe(u8, body);
        errdefer self.allocator.free(body_copy);
        const status_copy = try self.allocator.dupe(u8, status);
        errdefer self.allocator.free(status_copy);

        if (self.map.getEntry(order_key)) |existing| {
            self.allocator.free(existing.value_ptr.body);
            self.allocator.free(existing.value_ptr.status);
            existing.value_ptr.* = .{ .body = body_copy, .status = status_copy };
            return;
        }

        const key_copy = try self.allocator.dupe(u8, order_key);
        errdefer self.allocator.free(key_copy);
        try self.map.put(self.allocator, key_copy, .{ .body = body_copy, .status = status_copy });
    }

    pub fn snapshotByStatus(
        self: *OrderStore,
        out_allocator: Allocator,
        statuses: []const []const u8
    ) ![][]u8 {
        self.mutex.lockUncancelable(self.io);
        defer self.mutex.unlock(self.io);

        var keep: std.ArrayList([]u8) = .empty;
        errdefer {
            for (keep.items) |b| out_allocator.free(b);
            keep.deinit(out_allocator);
        }

        var it = self.map.iterator();
        while (it.next()) |entry| {
            const sv = entry.value_ptr.*;
            for (statuses) |want| {
                if (std.mem.eql(u8, sv.status, want)) {
                    const body_dup = try out_allocator.dupe(u8, sv.body);
                    try keep.append(out_allocator, body_dup);
                    break;
                }
            }
        }
        return keep.toOwnedSlice(out_allocator);
    }
};

const OrderKeyStatus = struct {
    OrderKey: []const u8 = "",
    Status: []const u8 = "",
};

pub fn processOrderFrame(
    frame: ssehub.ChangeRecord,
    alloc: Allocator,
    ctx_ptr: ?*anyopaque
) anyerror!void {
    const c: *HubCtx = @ptrCast(@alignCast(ctx_ptr orelse return));

    const body = frame.value orelse {
        log.info("hub: skip frame (no body) lsn={d} kind={s}", .{ frame.lsn, @tagName(frame.kind) });
        return;
    };

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    const head = bson.decode(a, OrderKeyStatus, body) catch |err| {
        log.warn("hub: header decode failed: {s}", .{@errorName(err)});
        return;
    };
    if (head.OrderKey.len == 0) {
        log.warn("hub: frame missing OrderKey, ignoring (lsn={d})", .{frame.lsn});
        return;
    }

    log.info("hub: frame lsn={d} order_key={s} status={s}", .{ frame.lsn, head.OrderKey, head.Status });

    try c.store.put(head.OrderKey, body, head.Status);

    try render_tracking.publish(c, a, head.OrderKey, body);

    try render_kitchen.publish(c, a);
    try render_delivery.publish(c, a);

    if (std.mem.eql(u8, head.Status, order_models.status_delivered) or
        std.mem.eql(u8, head.Status, order_models.status_cancelled))
    {
        const topic = try std.fmt.allocPrint(a, "order:{s}", .{head.OrderKey});
        c.bus.deleteTopic(topic);
        log.info("hub: terminal status '{s}', closed tracking topic", .{head.Status});
    }
}
