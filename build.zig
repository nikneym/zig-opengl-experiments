const std = @import("std");
const glfw = @import("lib/mach-glfw/build.zig");
const zstbi = @import("lib/zig-gamedev/libs/zstbi/build.zig");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "game",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // add GLFW
    exe.addModule("glfw", glfw.module(b));
    try glfw.link(b, exe, .{});

    const zgl = b.createModule(.{
        .source_file = .{ .path = "lib/zgl/zgl.zig" },
    });
    exe.addModule("zgl", zgl);

    const zstbi_pkg = zstbi.Package.build(b, target, optimize, .{});
    exe.addModule("zstbi", zstbi_pkg.zstbi);
    zstbi_pkg.link(exe);

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
