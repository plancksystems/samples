const std = @import("std");

/// Loads environment variables from a `.env` file in the current directory
/// and injects them into the provided Environ.Map.
pub fn loadDotEnv(io: std.Io, allocator: std.mem.Allocator, env_map: *std.process.Environ.Map) !void {
    const content = std.Io.Dir.readFileAlloc(.cwd(), io, ".env", allocator, .unlimited) catch |err| switch (err) {
        error.FileNotFound => return, // Gracefully ignore if file does not exist
        else => return err,
    };
    defer allocator.free(content);

    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;

        const eq_idx = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const key = std.mem.trim(u8, line[0..eq_idx], " \t");
        var val = std.mem.trim(u8, line[eq_idx + 1 ..], " \t");

        // Strip surrounding double quotes
        if (val.len >= 2 and val[0] == '"' and val[val.len - 1] == '"') {
            val = val[1 .. val.len - 1];
        }
        // Strip surrounding single quotes
        else if (val.len >= 2 and val[0] == '\'' and val[val.len - 1] == '\'') {
            val = val[1 .. val.len - 1];
        }

        try env_map.put(key, val);
    }
}
