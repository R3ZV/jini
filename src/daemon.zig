const std = @import("std");

pub fn main() !void {
    const pid = std.os.linux.fork();
    if (pid == 0) {
        std.debug.print("Child\n", .{});
    } else {
        std.debug.print("Parent exiting\n", .{});
        std.posix.exit(1);
    }
    std.debug.print("New session for child\n", .{});
    if (std.os.linux.setsid() < 0) {
        defer std.debug.print("Session failed\n", .{});
        std.posix.exit(1);
    }

    try std.posix.chdir("/");

    std.posix.close(std.posix.STDIN_FILENO);
    std.posix.close(std.posix.STDOUT_FILENO);
    std.posix.close(std.posix.STDERR_FILENO);

    while (true) {
        // TODO: daemon specific
    }

    std.os.linux.exit(0);
}
