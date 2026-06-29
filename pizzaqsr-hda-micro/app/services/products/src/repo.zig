
const std = @import("std");
const planck = @import("planck");

const m = @import("models/product.zig");
const Product = m.Product;
const Category = m.Category;
const CreateProductBody = m.CreateProductBody;
const CreateCategoryBody = m.CreateCategoryBody;


pub const ProductModel = planck.Model(Product, .{
    .store = "products",
    .primary_key = "ProductID",
    .schema = &.{
        .{ "SKU", .{ .field_type = .string, .required = true, .min_length = 1, .max_length = 50 } },
        .{ "Name", .{ .field_type = .string, .required = true, .min_length = 1, .max_length = 200 } },
        .{ "CategoryID", .{ .field_type = .int32, .required = true, .min = 1 } },
        .{ "BasePrice", .{ .field_type = .double, .required = true, .min = 0 } },
    },
});

pub const CategoryModel = planck.Model(Category, .{
    .store = "categories",
    .primary_key = "CategoryID",
    .schema = &.{
        .{ "Name", .{ .field_type = .string, .required = true, .min_length = 1, .max_length = 100 } },
    },
});


pub fn listProducts(
    client: *planck.Client,
    allocator: std.mem.Allocator,
    category_id: ?i32,
    search: ?[]const u8
) ![]const Product {
    const all: []const Product = blk: {
        if (category_id) |cid| if (cid > 0) {
            var qb = ProductModel.query(client, allocator);
            defer qb.deinit();
            break :blk try qb
                .where("CategoryID", .eq, .{ .int = cid })
                .limit(200)
                .find();
        };
        break :blk try ProductModel.find(client, allocator, .{});
    };

    if (search) |needle_raw| {
        const filtered = filterByName(allocator, all, needle_raw) catch return all;
        if (filtered.ptr != all.ptr) allocator.free(all);
        return filtered;
    }
    return all;
}

pub fn getProduct(client: *planck.Client, allocator: std.mem.Allocator, id: i32) !?Product {
    return ProductModel.findById(client, allocator, id);
}

pub fn createProduct(
    client: *planck.Client,
    allocator: std.mem.Allocator,
    body: CreateProductBody
) !void {
    _ = try ProductModel.create(client, allocator, body);
}


pub fn listCategories(client: *planck.Client, allocator: std.mem.Allocator) ![]const Category {
    return CategoryModel.find(client, allocator, .{});
}

pub fn createCategory(
    client: *planck.Client,
    allocator: std.mem.Allocator,
    body: CreateCategoryBody
) !void {
    _ = try CategoryModel.create(client, allocator, body);
}


fn filterByName(allocator: std.mem.Allocator, products: []const Product, needle_raw: []const u8) ![]const Product {
    const needle = std.mem.trim(u8, needle_raw, " \t\r\n");
    if (needle.len == 0) return products;

    const needle_lower = try allocator.alloc(u8, needle.len);
    defer allocator.free(needle_lower);
    for (needle, 0..) |c, i| needle_lower[i] = std.ascii.toLower(c);

    var out: std.ArrayList(Product) = .empty;
    errdefer out.deinit(allocator);

    var name_buf: [256]u8 = undefined;
    for (products) |p| {
        const len = @min(p.Name.len, name_buf.len);
        for (p.Name[0..len], 0..) |c, i| name_buf[i] = std.ascii.toLower(c);
        if (std.mem.indexOf(u8, name_buf[0..len], needle_lower) != null) {
            try out.append(allocator, p);
        }
    }
    return try out.toOwnedSlice(allocator);
}
