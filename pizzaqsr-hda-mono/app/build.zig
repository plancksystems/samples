const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const deps = wireDeps(b, target, optimize);

    const cart_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/cart/fragments/" });
    const cart_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/cart/zsx/", "src/features/cart/fragments/" });
    cart_preprocess.step.dependOn(&cart_clean.step);

    const products_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/products/fragments/" });
    const products_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/products/zsx/", "src/features/products/fragments/" });
    products_preprocess.step.dependOn(&products_clean.step);

    const orders_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/orders/fragments/" });
    const orders_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/orders/zsx/", "src/features/orders/fragments/" });
    orders_preprocess.step.dependOn(&orders_clean.step);

    const checkout_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/checkout/fragments/" });
    const checkout_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/checkout/zsx/", "src/features/checkout/fragments/" });
    checkout_preprocess.step.dependOn(&checkout_clean.step);

    const users_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/users/fragments/" });
    const users_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/users/zsx/", "src/features/users/fragments/" });
    users_preprocess.step.dependOn(&users_clean.step);

    const kitchen_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/kitchen/fragments/" });
    const kitchen_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/kitchen/zsx/", "src/features/kitchen/fragments/" });
    kitchen_preprocess.step.dependOn(&kitchen_clean.step);

    const delivery_clean = b.addSystemCommand(&.{ "planctl", "clean", "src/features/delivery/fragments/" });
    const delivery_preprocess = b.addSystemCommand(&.{ "planctl", "src/features/delivery/zsx/", "src/features/delivery/fragments/" });
    delivery_preprocess.step.dependOn(&delivery_clean.step);

    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm = b.addExecutable(.{
        .name = "pizzaqsr-hda-mono",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/app.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "web", .module = deps.web },
                .{ .name = "planck", .module = deps.planck_zig_client },
            },
        }),
    });
    wasm.entry = .disabled;
    wasm.rdynamic = true;
    wasm.max_memory = 256 * 1024 * 1024;
    wasm.step.dependOn(&cart_preprocess.step);
    wasm.step.dependOn(&products_preprocess.step);
    wasm.step.dependOn(&orders_preprocess.step);
    wasm.step.dependOn(&checkout_preprocess.step);
    wasm.step.dependOn(&users_preprocess.step);
    wasm.step.dependOn(&kitchen_preprocess.step);
    wasm.step.dependOn(&delivery_preprocess.step);

    const wasm_install = b.addInstallArtifact(wasm, .{
        .dest_dir = .{ .override = .{ .custom = "wasm" } },
    });

    const dev_exe = b.addExecutable(.{
        .name = "pizzaqsr-dev",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .Debug,
            .imports = &.{
                .{ .name = "web", .module = deps.web },
                .{ .name = "schnell", .module = deps.schnell },
                .{ .name = "planck", .module = deps.planck_zig_client },
            },
        }),
    });
    dev_exe.step.dependOn(&cart_preprocess.step);
    dev_exe.step.dependOn(&products_preprocess.step);
    dev_exe.step.dependOn(&orders_preprocess.step);
    dev_exe.step.dependOn(&checkout_preprocess.step);
    dev_exe.step.dependOn(&users_preprocess.step);
    dev_exe.step.dependOn(&kitchen_preprocess.step);
    dev_exe.step.dependOn(&delivery_preprocess.step);
    const dev_install = b.addInstallArtifact(dev_exe, .{});

    const run_dev = b.addRunArtifact(dev_exe);
    run_dev.step.dependOn(&dev_install.step);

    b.step("wasm", "Build WASM bundle (deployable monolith)").dependOn(&wasm_install.step);
    b.step("preprocess", "Preprocess all features' zsx → ui only").dependOn(&products_preprocess.step);
    b.step("dev", "Run dev server (Native, Debug build)").dependOn(&run_dev.step);
    b.step("dev-build", "Build dev server without running it (for lldb/gdb)").dependOn(&dev_install.step);
    b.default_step = &wasm_install.step;
}

const Deps = struct {
    bson: *std.Build.Module,
    utils: *std.Build.Module,
    tls: *std.Build.Module,
    proto: *std.Build.Module,
    planck_zig_client: *std.Build.Module,
    schnell: *std.Build.Module,
    web: *std.Build.Module,
};

fn wireDeps(b: *std.Build, target: anytype, optimize: anytype) Deps {
    const bson_dep = b.dependency("bson", .{});
    const bson = b.createModule(.{
        .root_source_file = bson_dep.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const utils_dep = b.dependency("utils", .{});
    const utils = b.createModule(.{
        .root_source_file = utils_dep.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tls_dep = b.dependency("tls", .{});
    const tls = b.createModule(.{
        .root_source_file = tls_dep.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const proto_dep = b.dependency("proto", .{});
    const proto = b.createModule(.{
        .root_source_file = proto_dep.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    proto.addImport("utils", utils);

    const planck_dep = b.dependency("planck_zig_client", .{});
    const planck_zig_client = b.createModule(.{
        .root_source_file = planck_dep.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    planck_zig_client.addImport("tls", tls);
    planck_zig_client.addImport("bson", bson);
    planck_zig_client.addImport("utils", utils);
    planck_zig_client.addImport("proto", proto);

    const schnell_dep = b.dependency("schnell", .{});
    const yaml_dep = schnell_dep.builder.dependency("yaml", .{});
    const yaml = b.createModule(.{
        .root_source_file = yaml_dep.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const schnell = b.createModule(.{
        .root_source_file = schnell_dep.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    schnell.addImport("bson", bson);
    schnell.addImport("utils", utils);
    schnell.addImport("tls", tls);
    schnell.addImport("proto", proto);
    schnell.addImport("planck_zig_client", planck_zig_client);
    schnell.addImport("yaml", yaml);

    const web = b.createModule(.{
        .root_source_file = schnell_dep.path("src/web/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    web.addImport("bson", bson);
    web.addImport("schnell", schnell);

    return .{
        .bson = bson,
        .utils = utils,
        .tls = tls,
        .proto = proto,
        .planck_zig_client = planck_zig_client,
        .schnell = schnell,
        .web = web,
    };
}
