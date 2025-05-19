const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "barehttp",
        .root_source_file = b.path("src/c_api.zig"), // C-compatible Zig interface
        .target = target,
        .optimize = optimize,
    });

    // Include paths
    lib.addIncludePath(b.path("src/uip"));
    lib.addIncludePath(b.path("src"));

    // Add C source files (uIP stack, etc.)
    lib.addCSourceFiles(.{
        .files = &.{
            "src/uip/uip.c",
            "src/uip/uip_arp.c",
            "src/uip/uip-fw.c",
            "src/uip/uip-neighbor.c",
            "src/uip/psock.c",
            "src/uip/timer.c",
            "src/uip/clock-arch.c",
        },
        .flags = &.{},
    });

    lib.linkLibC();

    b.installArtifact(lib);
}
