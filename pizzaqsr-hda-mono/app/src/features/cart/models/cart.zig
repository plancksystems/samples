const web = @import("web");
const Schema = web.Schema;

pub const CartItem = struct {
    ProductID: i32 = 0,
    Name: []const u8 = "",
    UnitPrice: f64 = 0,
    Qty: u32 = 1,
    LineTotal: f64 = 0,
    AddedAt: []const u8 = "",
};

pub const Cart = struct {
    CartID: i64 = 0,
    CustomerID: []const u8 = "",
    Status: []const u8 = "open",
    Items: []const CartItem = &.{},
    SubTotal: f64 = 0,
    CreatedAt: []const u8 = "",
    UpdatedAt: []const u8 = "",

    pub fn totalQty(self: Cart) u32 {
        var n: u32 = 0;
        for (self.Items) |it| n += it.Qty;
        return n;
    }

    pub fn computeSubtotal(self: Cart) f64 {
        var s: f64 = 0;
        for (self.Items) |it| s += it.UnitPrice * @as(f64, @floatFromInt(it.Qty));
        return s;
    }
};


pub const CartSchema = Schema(&.{
    .{ "CustomerID", .{ .field_type = .string, .required = true, .min_length = 1, .max_length = 128 } },
    .{ "Status", .{ .field_type = .string, .required = true } },
});


pub const CartParams = struct {
    customer_id: ?[]const u8 = null,
};

pub const AddItemBody = struct {
    productId: i32,
    name: []const u8 = "",
    unitPrice: f64 = 0,
    qty: u32 = 1,
};

pub const UpdateItemBody = struct {
    productId: i32,
    qty: u32,
};

pub const RemoveItemBody = struct {
    productId: i32,
};
