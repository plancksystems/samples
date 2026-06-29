const planck = @import("planck");

pub const Ctx = struct {
    client: *planck.Client,

    jwt_secret: []const u8 = "",

    jwt_ttl_seconds: i64 = 30 * 24 * 60 * 60,

    google_client_id: []const u8 = "",
    google_client_secret: []const u8 = "",
    google_redirect_uri: []const u8 = "",

    stripe_secret_key: []const u8 = "",

    stripe_publishable_key: []const u8 = "",

    stripe_webhook_secret: []const u8 = "",
};
