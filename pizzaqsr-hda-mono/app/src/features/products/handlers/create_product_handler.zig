
const std = @import("std");
const web = @import("web");
const Request = web.Request;
const Response = web.Response;
const planck = @import("planck");

const Product = @import("../models/product.zig").Product;
const CreateProductBody = @import("../models/product.zig").CreateProductBody;
const Ctx = @import("../../../core/ctx.zig").Ctx;

pub fn handle(ctx_ptr: ?*anyopaque, allocator: std.mem.Allocator, req: *const Request, res: *Response) !void {
    const ctx: *Ctx = @ptrCast(@alignCast(ctx_ptr orelse return error.NoContext));
    const body = try req.getBody(allocator, CreateProductBody);

    const product = Product{
        .SKU = body.SKU,
        .Name = body.Name,
        .Description = body.Description,
        .CategoryID = body.CategoryID,
        .BasePrice = body.BasePrice,
        .ImageURL = body.ImageURL,
        .Attributes = body.Attributes,
    };
    var q = planck.Query.initWithAllocator(ctx.client, allocator);
    defer q.deinit();
    var resp = try (try q.store("products").create(product)).run();
    defer resp.deinit();

    try res.html("<span>Product created</span>");
}
