
const web = @import("web");
const Ctx = @import("./ctx.zig").Ctx;

const list_products = @import("handlers/list_products_handler.zig");
const get_product = @import("handlers/get_product_handler.zig");
const get_product_json = @import("handlers/get_product_json_handler.zig");
const create_product = @import("handlers/create_product_handler.zig");
const list_categories = @import("handlers/list_categories_handler.zig");
const create_category = @import("handlers/create_category_handler.zig");
const panel_home = @import("handlers/panel_home_handler.zig");

pub fn register(app: anytype, ctx: *Ctx) !void {
    try app.get("/panel/home", panel_home.handle, ctx);
    try app.get("/categories", list_categories.handle, ctx);
    try app.post("/categories", create_category.handle, ctx);
    try app.get("/products", list_products.handle, ctx);
    try app.get("/products/:id", get_product.handle, ctx);
    try app.post("/products", create_product.handle, ctx);
    try app.get("/api/products/:id", get_product_json.handle, ctx);
}
