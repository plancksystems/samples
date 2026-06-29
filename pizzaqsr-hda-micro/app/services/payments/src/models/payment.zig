
pub const Payment = struct {
    PaymentID: i64 = 0,
    OrderID: i64 = 0,
    IntentID: []const u8 = "",
    ClientSecret: []const u8 = "",
    Amount: i64 = 0,
    Currency: []const u8 = "INR",
    Status: []const u8 = "pending",
    CreatedAt: []const u8 = "",
    UpdatedAt: []const u8 = "",
};

pub const IntentPayload = struct {
    client_secret: []const u8 = "",
    publishable_key: []const u8 = "",
};
