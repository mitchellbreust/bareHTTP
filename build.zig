const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "barehttp",
        .root_source_file = .{ .path = "src/api.zig" }, // adjust if your main entry is different
        .target = target,
        .optimize = optimize,
    });

    // Add uIP include path
    exe.addIncludePath(.{ .path = "src/uip" });

    // Add uIP C source files
    exe.addCSourceFiles(&.{
        "src/uip/uip.c",
        "src/uip/uip_arp.c",
        "src/uip/uip-fw.c",
        "src/uip/uip-neighbor.c",
        "src/uip/uip-split.c",
        "src/uip/psock.c",
        "src/uip/timer.c",
    }, &.{}); // No extra flags needed, unless your chip/platform requires defines

    // Link C standard library
    exe.linkLibC();

    // Optional: enable debug symbols or warnings
    // exe.addCSourceFiles(..., &.{"-Wall", "-g"});

    b.installArtifact(exe);
}
