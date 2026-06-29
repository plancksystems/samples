
const std_ = @import("std");
const web = @import("web");
const Schema = web.Schema;

pub const OrderItem = struct {
    ProductID: i32 = 0,
    Name: []const u8 = "",
    UnitPrice: f64 = 0,
    Qty: u32 = 1,
    LineTotal: f64 = 0,
};

pub const Address = struct {
    Label: []const u8 = "",
    Line1: []const u8 = "",
    Line2: []const u8 = "",
    City: []const u8 = "",
    State: []const u8 = "",
    Pincode: []const u8 = "",
    Lat: f64 = 0,
    Lng: f64 = 0,
};

pub const status_awaiting_payment: []const u8 = "AwaitingPayment";
pub const status_paid: []const u8 = "Paid";
pub const status_preparing: []const u8 = "Preparing";
pub const status_ready: []const u8 = "Ready";
pub const status_out_for_delivery: []const u8 = "OutForDelivery";
pub const status_delivered: []const u8 = "Delivered";
pub const status_cancelled: []const u8 = "Cancelled";

pub const Order = struct {
    OrderID: i64 = 0,
    OrderKey: []const u8 = "",
    CustomerID: []const u8 = "",
    Status: []const u8 = status_awaiting_payment,
    Items: []const OrderItem = &.{},
    SubTotal: f64 = 0,
    Tax: f64 = 0,
    DeliveryFee: f64 = 0,
    Total: f64 = 0,
    DeliveryAddress: Address = .{},
    KitchenID: i64 = 0,
    KitchenWorkerID: i64 = 0,
    DeliveryPartnerID: i64 = 0,
    PaymentIntentID: []const u8 = "",
    CreatedAt: []const u8 = "",
    CreatedAtMillis: i64 = 0,
    UpdatedAt: []const u8 = "",

    pub fn computeSubtotal(self: Order) f64 {
        var s: f64 = 0;
        for (self.Items) |it| s += it.UnitPrice * @as(f64, @floatFromInt(it.Qty));
        return s;
    }

    pub fn isStatusReached(self: Order, target: []const u8) bool {
        const stages = [_][]const u8{
            status_awaiting_payment,
            status_paid,
            status_preparing,
            status_ready,
            status_out_for_delivery,
            status_delivered,
        };
        var cur_idx: usize = 0;
        var tgt_idx: usize = 0;
        var found_cur = false;
        var found_tgt = false;
        for (stages, 0..) |s, i| {
            if (std_.mem.eql(u8, s, self.Status)) {
                cur_idx = i;
                found_cur = true;
            }
            if (std_.mem.eql(u8, s, target)) {
                tgt_idx = i;
                found_tgt = true;
            }
        }
        if (!found_cur or !found_tgt) return false;
        return cur_idx >= tgt_idx;
    }

    pub fn isCancelled(self: Order) bool {
        return std_.mem.eql(u8, self.Status, status_cancelled);
    }

    pub fn isStatusCurrent(self: Order, target: []const u8) bool {
        return std_.mem.eql(u8, self.Status, target);
    }

    pub fn statusBadge(self: Order) []const u8 {
        if (std_.mem.eql(u8, self.Status, status_awaiting_payment)) return "⏳";
        if (std_.mem.eql(u8, self.Status, status_paid)) return "✅";
        if (std_.mem.eql(u8, self.Status, status_preparing)) return "🍳";
        if (std_.mem.eql(u8, self.Status, status_ready)) return "📦";
        if (std_.mem.eql(u8, self.Status, status_out_for_delivery)) return "🛵";
        if (std_.mem.eql(u8, self.Status, status_delivered)) return "🎉";
        if (std_.mem.eql(u8, self.Status, status_cancelled)) return "❌";
        return "🍕";
    }

    pub fn stepTextClass(self: Order, target: []const u8) []const u8 {
        return if (self.isStatusReached(target)) "text-slate-700" else "text-slate-400";
    }

    pub fn stepRingClass(self: Order, target: []const u8, next: []const u8) []const u8 {
        if (next.len > 0 and self.isStatusReached(next)) return "border-emerald-500";
        if (self.isStatusCurrent(target)) return "border-blue-500";
        if (next.len == 0 and self.isStatusReached(target)) return "border-emerald-500";
        return "border-slate-200";
    }

    pub fn stepDotClass(self: Order, target: []const u8, next: []const u8) []const u8 {
        if (next.len > 0 and self.isStatusReached(next)) return "bg-emerald-500";
        if (self.isStatusCurrent(target)) return "bg-blue-600";
        if (next.len == 0 and self.isStatusReached(target)) return "bg-emerald-500";
        return "bg-slate-200";
    }

    pub fn statusMessage(self: Order) []const u8 {
        if (std_.mem.eql(u8, self.Status, status_awaiting_payment)) return "Waiting for payment to clear…";
        if (std_.mem.eql(u8, self.Status, status_paid)) return "Payment confirmed. Off to the kitchen!";
        if (std_.mem.eql(u8, self.Status, status_preparing)) return "Your order is being prepared.";
        if (std_.mem.eql(u8, self.Status, status_ready)) return "Ready for pickup by delivery.";
        if (std_.mem.eql(u8, self.Status, status_out_for_delivery)) return "On the way to you!";
        if (std_.mem.eql(u8, self.Status, status_delivered)) return "Delivered. Enjoy your meal!";
        if (std_.mem.eql(u8, self.Status, status_cancelled)) return "Order cancelled.";
        return "";
    }
};


pub const OrderSchema = Schema(&.{
    .{ "CustomerID", .{ .field_type = .string, .required = true, .min_length = 1, .max_length = 128 } },
    .{ "Status", .{ .field_type = .string, .required = true } },
});


pub const CheckoutBody = struct {
    addressLabel: []const u8 = "",
    line1: []const u8 = "",
    line2: []const u8 = "",
    city: []const u8 = "",
    state: []const u8 = "",
    pincode: []const u8 = "",
};

pub const StatusUpdateBody = struct {
    from: []const u8,
    to: []const u8,
};
