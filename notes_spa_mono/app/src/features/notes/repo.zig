
const planck = @import("planck");
const m = @import("models/note.zig");
const Note = m.Note;

pub const NoteModel = planck.Model(Note, .{
    .store = "notes",
    .primary_key = "NoteID",
    .timestamps = true,
    .schema = &.{
        .{ "Title", .{ .field_type = .string, .required = true, .min_length = 1, .max_length = 200 } },
        .{ "Body", .{ .field_type = .string, .required = false, .max_length = 10_000 } },
        .{ "Tags", .{ .field_type = .string, .required = false, .max_length = 500 } },
    },
});
