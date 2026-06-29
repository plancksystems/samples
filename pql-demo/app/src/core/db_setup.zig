
const std = @import("std");
const planck = @import("planck");
const proto = @import("proto");
const bson = @import("bson");

pub const Counts = struct {
    created: usize = 0,
    skipped: usize = 0,
};

const STORE_NAMES: []const []const u8 = &.{
    "orders",
    "customers",
    "employees",
    "products",
    "productcategories",
    "productsubcategories",
    "vendors",
    "vendorproduct",
    "addresses",
};

const IndexSpec = struct {
    ns: []const u8,
    field: []const u8,
    field_type: proto.FieldType,
};

const INDEXES: []const IndexSpec = &.{
    .{ .ns = "orders.employee_id_idx", .field = "EmployeeID", .field_type = .I64 },
    .{ .ns = "orders.customer_id_idx", .field = "CustomerID", .field_type = .I64 },
    .{ .ns = "orders.total_due_idx", .field = "TotalDue", .field_type = .F64 },
    .{ .ns = "orders.order_id_idx", .field = "SalesOrderID", .field_type = .I64 },
    .{ .ns = "employees.employee_id_idx", .field = "EmployeeID", .field_type = .I64 },
    .{ .ns = "employees.gender_idx", .field = "Gender", .field_type = .String },
    .{ .ns = "employees.marital_status_idx", .field = "MaritalStatus", .field_type = .String },
    .{ .ns = "products.makeflag_idx", .field = "MakeFlag", .field_type = .I64 },
    .{ .ns = "products.listprice_idx", .field = "ListPrice", .field_type = .F64 },
    .{ .ns = "products.subcategory_id_idx", .field = "SubCategoryID", .field_type = .I64 },
    .{ .ns = "vendors.activeflag_idx", .field = "ActiveFlag", .field_type = .I64 },
    .{ .ns = "vendors.credit_rating_idx", .field = "CreditRating", .field_type = .I64 },
    .{ .ns = "vendors.vendor_id_idx", .field = "VendorID", .field_type = .I64 },
    .{ .ns = "vendors.vendor_name_idx", .field = "VendorName", .field_type = .String },
    .{ .ns = "productcategories.category_name_idx", .field = "CategoryName", .field_type = .String },
    .{ .ns = "customers.address_city", .field = "Address.City", .field_type = .String },
    .{ .ns = "customers.address_state", .field = "Address.State", .field_type = .String },
    .{ .ns = "customers.address_country", .field = "Address.Country", .field_type = .String },
    .{ .ns = "customers.address_zipcode", .field = "Address.ZipCode", .field_type = .String },
};

fn createDoc(client: *planck.Client, doc_type: proto.DocType, ns: []const u8, value: anytype) !bool {
    var encoder = bson.Encoder.init(client.allocator);
    defer encoder.deinit();
    const payload = try encoder.encode(value);
    defer client.allocator.free(payload);

    const packet = try client.doOperation(.{ .Create = .{
        .doc_type = doc_type,
        .ns = ns,
        .payload = payload,
        .auto_create = true,
        .metadata = null,
    } });
    defer proto.Packet.free(client.allocator, packet);

    switch (packet.op) {
        .Reply => |reply| return switch (reply.status) {
            .ok => true,
            .already_exists => false,
            else => error.CreateFailed,
        },
        else => return error.InvalidResponse,
    }
}

pub fn setupSchema(client: *planck.Client) Counts {
    var counts: Counts = .{};
    for (STORE_NAMES) |name| {
        const created = createDoc(client, .Store, name, proto.Store{
            .id = 0,
            .store_id = 0,
            .ns = name,
            .description = "Store",
        }) catch {
            counts.skipped += 1;
            continue;
        };
        if (created) counts.created += 1 else counts.skipped += 1;
    }
    return counts;
}

pub fn createIndexes(client: *planck.Client) Counts {
    var counts: Counts = .{};
    for (INDEXES) |idx| {
        const created = createDoc(client, .Index, idx.ns, proto.Index{
            .id = 0,
            .store_id = 0,
            .ns = idx.ns,
            .field = idx.field,
            .field_type = idx.field_type,
            .unique = false,
            .description = null,
            .created_at = 0,
        }) catch {
            counts.skipped += 1;
            continue;
        };
        if (created) counts.created += 1 else counts.skipped += 1;
    }
    return counts;
}

pub fn storeNames() []const []const u8 {
    return STORE_NAMES;
}

pub fn indexCount() usize {
    return INDEXES.len;
}
