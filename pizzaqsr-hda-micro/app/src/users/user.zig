
const web = @import("web");
const Schema = web.Schema;

pub const role_admin: []const u8 = "admin";
pub const role_customer: []const u8 = "customer";
pub const role_kitchen: []const u8 = "kitchen";
pub const role_delivery: []const u8 = "delivery";

pub const User = struct {
    UserID: i64 = 0,
    GoogleSub: []const u8 = "",
    Email: []const u8 = "",
    Name: []const u8 = "",
    Role: []const u8 = "customer",
    Phone: []const u8 = "",
    Status: []const u8 = "active",
    CreatedAt: []const u8 = "",
    UpdatedAt: []const u8 = "",
};

pub const UserSchema = Schema(&.{
    .{ "Email", .{ .field_type = .string, .required = true, .min_length = 3, .max_length = 254 } },
    .{ "Role", .{ .field_type = .string, .required = true } },
    .{ "Status", .{ .field_type = .string, .required = true } },
});


pub const CreateUserBody = struct {
    email: []const u8,
    name: []const u8 = "",
    role: []const u8 = "customer",
    phone: []const u8 = "",
};

pub const UpdateRoleBody = struct {
    role: []const u8,
};
