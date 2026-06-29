
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const ssehub = @import("ssehub");

const publish_notes = @import("publish_notes.zig");

const log = std.log.scoped(.notes_spa_micro_sse);

pub const HubCtx = struct {
    allocator: Allocator,
    io: Io,
    bus: *ssehub.EventBus,

    pub fn init(allocator: Allocator, io: Io, bus: *ssehub.EventBus) HubCtx {
        return .{ .allocator = allocator, .io = io, .bus = bus };
    }

    pub fn deinit(self: *HubCtx) void {
        _ = self;
    }
};

pub fn processFrame(
    frame: ssehub.ChangeRecord,
    alloc: Allocator,
    ctx_ptr: ?*anyopaque
) anyerror!void {
    const c: *HubCtx = @ptrCast(@alignCast(ctx_ptr orelse return));

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    log.info("hub: frame lsn={d} store={s} kind={s}", .{
        frame.lsn,
        frame.store_ns,
        @tagName(frame.kind),
    });

    if (std.mem.eql(u8, frame.store_ns, "notes")) {
        try publish_notes.publish(c, a, frame);
    }
}
