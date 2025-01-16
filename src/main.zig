const std = @import("std");
const CLI = @import("cli.zig").CLI;
const Job = @import("job.zig");

fn exec() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var arg_it = std.process.args();
    _ = arg_it.skip();
    var args = std.ArrayList([]const u8).init(alloc);
    defer args.deinit();

    while (arg_it.next()) |arg| {
        try args.append(try alloc.dupe(u8, arg));
    }

    var cli = CLI.new(args.items, alloc);
    defer cli.deinit();
    try cli.parse();

    if (cli.hasErr()) {
        std.debug.print("{s}\n", .{cli.getErr().?});
        return;
    }

    // switch (cli.getCommand()) {
    //     .Add => {
    // const id = cli.getId().?;
    // const priority = cli.getPriority();
    // const root = cli.getRoot();
    // jobs.append(Job.new(id, priority, root));
    // },
    // .Suspend => {
    //     const id = cli.getId();
    //     var job = Job.getById(jobs, id);
    //     job.suspendJob();
    //  },
    // .Resume => {
    //     const id = cli.getId();
    //     var job = Job.getById(jobs, id);
    //     job.resumeJob();
    // },
    // .Remove => {
    //     const id = cli.getId();
    //     removeJob(jobs, id);
    // },
    // .Info => {
    //     var job = Job.getById(jobs, id);
    //     job.info();
    // },
    // .List => {
    //     std.debug.print("ID PRI  Path               Progress    Status   Details\n", .{});
    //     for (jobs.items) |job| {
    //         std.debug.print("{s}\n", .{job.format()});
    //     }
    // },
    // .Print => {
    //     const id = cli.getId();
    //     var job = Job.getById(jobs, id);
    //     job.print();
    // },
    // .Help, .Priority => {
    //     cli.help();
    // },
    // }
}

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
