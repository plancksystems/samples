
const std = @import("std");
const Allocator = std.mem.Allocator;
const bson = @import("bson");
const ssehub = @import("ssehub");

const Note = @import("models/note.zig").Note;
const HubCtx = @import("hub.zig").HubCtx;

const log = std.log.scoped(.notes_spa_mono_sse);

pub const TOPIC = "notes";

pub fn publish(c: *HubCtx, alloc: Allocator, frame: ssehub.ChangeRecord) !void {
    switch (frame.kind) {
        .insert, .update => {
            const value = frame.value orelse {
                log.warn("publish_notes: insert/update with null value lsn={d}", .{frame.lsn});
                return;
            };
            const note = bson.decode(alloc, Note, value) catch |err| {
                log.warn("publish_notes: decode failed lsn={d} err={s}", .{ frame.lsn, @errorName(err) });
                return;
            };
            const json_payload = try std.json.Stringify.valueAlloc(alloc, note, .{});
            const event_name = if (frame.kind == .insert) "note-created" else "note-updated";
            _ = try c.bus.publish(TOPIC, .{ .event = event_name, .data = json_payload });
        },
        .delete => {
            const note_id: i64 = @intCast(@as(u64, @truncate(frame.key)));
            const json_payload = try std.fmt.allocPrint(alloc, "{{\"NoteID\":{d}}}", .{note_id});
            _ = try c.bus.publish(TOPIC, .{ .event = "note-deleted", .data = json_payload });
        },
    }
}
