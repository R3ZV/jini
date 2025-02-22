const std = @import("std");

pub fn build(b: *std.Build) void {
    // Copy config jini.config to /etc/jini
    // Copy jini.service into /etc/systemd/system
    // Copy binary into /usr/bin
    // Use libconfig++.a

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "counter",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const daemon = b.addExecutable(.{
        .name = "daemon",
        .root_source_file = b.path("daemon/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const daemon_cmd = b.addRunArtifact(daemon);
    const daemon_step = b.step("daemon", "Start the daemon");
    daemon_step.dependOn(&daemon_cmd.step);

    // Tests
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
