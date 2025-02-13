const std = @import("std");

pub fn build(b: *std.Build) void {
    // Copy config jini.config to /etc/jini
    // Copy jini.service into /etc/systemd/system
    // Copy binary into /usr/bin
    // Use libconfig++.a

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "jini",
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

    // Daemon build
    const daemon = b.addExecutable(.{
        .name = "disk-analyzer-daemon",
        .root_source_file = b.path("src/daemon.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(daemon);

    const run_daemon = b.addRunArtifact(daemon);
    run_daemon.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_daemon.addArgs(args);
    }

    const daemon_step = b.step("daemon", "Run the daemon");
    daemon_step.dependOn(&run_daemon.step);

    // Tests
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cli_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/cli.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_cli_unit_tests = b.addRunArtifact(cli_unit_tests);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_cli_unit_tests.step);
}
