
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const planck = @import("planck");
const Query = planck.Query;
const pql = planck.pql;

const Ctx = @import("../../../core/ctx.zig").Ctx;
const RunRequest = @import("../models/run_request.zig").RunRequest;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));

    const body = req.getBody(allocator, RunRequest) catch {
        try res.json("{\"success\":false,\"error\":\"Invalid request body\"}");
        return;
    };
    if (body.query.len == 0) {
        try res.json("{\"success\":false,\"error\":\"Query is required\"}");
        return;
    }

    var query_ast = pql.parse(allocator, body.query) catch {
        try res.json("{\"success\":false,\"error\":\"Parse error\"}");
        return;
    };
    defer query_ast.deinit();

    const store_name = query_ast.store orelse {
        try res.json("{\"success\":false,\"error\":\"No store specified\"}");
        return;
    };

    var q = Query.init(ctx.client);
    defer q.deinit();

    _ = q.store(store_name);

    if (query_ast.doc_id) |doc_id| _ = q.readByKey(doc_id);

    for (query_ast.filters.items, 0..) |filter, i| {
        if (i > 0 and query_ast.filters.items[i - 1].logic == .@"or") {
            _ = q.@"or"(filter.field, filter.op, filter.value);
        } else {
            _ = q.where(filter.field, filter.op, filter.value);
        }
    }

    if (query_ast.limit_val) |lim| _ = q.limit(lim);
    if (query_ast.skip_val) |sk| _ = q.skip(sk);
    if (query_ast.after_val) |av| _ = q.after(av);

    if (query_ast.order_by) |ob| {
        for (ob.items) |spec| _ = q.orderBy(spec.field, spec.direction);
    }

    if (query_ast.projection) |proj| {
        if (proj.items.len > 0) _ = q.select(proj.items);
    }

    if (query_ast.group_by) |gb| {
        for (gb.items) |field| _ = q.groupBy(field);
    }

    if (query_ast.aggregations) |aggs| {
        for (aggs.items) |agg| {
            switch (agg.func) {
                .count => _ = q.count(agg.name),
                .sum => if (agg.field) |f| {
                    _ = q.sum(agg.name, f);
                },
                .avg => if (agg.field) |f| {
                    _ = q.avg(agg.name, f);
                },
                .min => if (agg.field) |f| {
                    _ = q.min(agg.name, f);
                },
                .max => if (agg.field) |f| {
                    _ = q.max(agg.name, f);
                },
            }
        }
    }

    if (query_ast.mutation) |mut| {
        switch (mut) {
            .insert => |json_payload| {
                const bson_payload = planck.bson.fromJson(q.allocator, json_payload) catch {
                    try res.json("{\"success\":false,\"error\":\"Failed to convert document to BSON\"}");
                    return;
                };
                q.ast.mutation = .{ .insert = bson_payload };
                query_ast.allocator.free(json_payload);
            },
            .update => |json_payload| {
                const bson_payload = planck.bson.fromJson(q.allocator, json_payload) catch {
                    try res.json("{\"success\":false,\"error\":\"Failed to convert update to BSON\"}");
                    return;
                };
                q.ast.mutation = .{ .update = bson_payload };
                query_ast.allocator.free(json_payload);
            },
            .delete => {
                q.ast.mutation = .delete;
            },
        }
        query_ast.mutation = null;
    }

    if (query_ast.query_type == .count) _ = q.countOnly();

    var result = q.run() catch {
        try res.json("{\"success\":false,\"error\":\"Query execution failed\"}");
        return;
    };
    defer result.deinit();

    if (!result.success) {
        const err_msg = result.error_message orelse "Query failed";
        const body_str = try std.fmt.allocPrint(allocator,
            "{{\"success\":false,\"error\":{s}}}",
            .{try jsonEscape(allocator, err_msg)});
        try res.json(body_str);
        return;
    }

    if (result.data) |data| {
        const json_data = planck.bson.toJsonArray(allocator, data) catch {
            try res.json("{\"success\":false,\"error\":\"Failed to convert results\"}");
            return;
        };
        const body_str = try std.fmt.allocPrint(
            allocator,
            "{{\"success\":true,\"count\":{d},\"data\":{s}}}",
            .{ result.count, json_data },
        );
        try res.json(body_str);
        return;
    }

    const body_str = try std.fmt.allocPrint(
        allocator,
        "{{\"success\":true,\"count\":{d},\"data\":[]}}",
        .{result.count},
    );
    try res.json(body_str);
}

fn jsonEscape(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.append(allocator, '"');
    for (s) |c| {
        switch (c) {
            '"' => try out.appendSlice(allocator, "\\\""),
            '\\' => try out.appendSlice(allocator, "\\\\"),
            '\n' => try out.appendSlice(allocator, "\\n"),
            '\r' => try out.appendSlice(allocator, "\\r"),
            '\t' => try out.appendSlice(allocator, "\\t"),
            else => try out.append(allocator, c),
        }
    }
    try out.append(allocator, '"');
    return out.toOwnedSlice(allocator);
}
