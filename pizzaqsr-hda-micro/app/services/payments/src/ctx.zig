
const planck = @import("planck");

pub const Ctx = struct {
    client: *planck.Client,

    stripe_secret_key: []const u8 = "",

    stripe_publishable_key: []const u8 = "",

    stripe_webhook_secret: []const u8 = "",
};
