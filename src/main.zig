const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 2) {
        std.debug.print("Must use either --minus or --plus\n", .{});
        return;
    }

    if (!std.mem.eql(u8, args[1], "--minus") and
        !std.mem.eql(u8, args[1], "--plus") and
        !std.mem.eql(u8, args[1], "--q"))
    {
        std.debug.print("{s} is an invalid argument\n", .{args[1]});
        std.debug.print("Must use either --minus, --plus, --q\n", .{});
    }

    const socket = try std.posix.socket(std.c.AF.UNIX, std.c.SOCK.STREAM, 0);
    const addr = try std.net.Address.initUnix("/tmp/counter.sock");
    try std.posix.connect(socket, &addr.any, addr.getOsSockLen());

    const msg = args[1];
    _ = try std.posix.send(socket, msg, 0);

    var buff: [1024]u8 = undefined;
    const read = try std.posix.recv(socket, &buff, 0);
    std.debug.print("Count: {s}\n", .{buff[0..read]});
}

// pub fn main() !void {
// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// const alloc = gpa.allocator();

// var arg_it = std.process.args();
// _ = arg_it.skip();
// var args = std.ArrayList([]const u8).init(alloc);
// defer args.deinit();

// while (arg_it.next()) |arg| {
//     try args.append(try alloc.dupe(u8, arg));
// }

// var cli = CLI.new(args.items, alloc);
// defer cli.deinit();
// try cli.parse();

// if (cli.hasErr()) {
//     std.debug.print("{s}\n", .{cli.getErr().?});
//     return;
// }

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
// }
