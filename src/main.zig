const CLI = @import("cli.zig").CLI;
const std = @import("std");
const assert = @import("std").debug.assert;

pub fn main() !void {
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
    const task = try cli.parse();
    defer task.deinit();

    if (task.err != null and task.option == null) {
        std.debug.print("{s}", .{task.err.?});
        return;
    }

    // std.debug.print("Task: {any}\n", .{task});
    if (task.command == .Empty) {
        CLI.help();
        return;
    }

    if (task.option != null) {
        task.resolve_option();
        return;
    }

    const socket = try std.posix.socket(std.c.AF.UNIX, std.c.SOCK.STREAM, 0);
    const addr_path = "/tmp/jini.sock";
    const addr = try std.net.Address.initUnix(addr_path);
    std.posix.connect(socket, &addr.any, addr.getOsSockLen()) catch |err| {
        switch (err) {
            error.FileNotFound => {
                std.debug.print("Socket '{s}' doesn't exist!\n", .{addr_path});
                std.debug.print("Make sure the daemon is active!\n", .{});
            },
            else => std.debug.print("Couldn't connect to the main socket!\n", .{}),
        }
        return;
    };

    switch (task.command) {
        .Add => {
            const priority = task.priority.?;
            const root = task.root.?;

            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "add {s} {s}", .{ @tagName(priority), root });
            assert(try std.posix.send(socket, msg, 0) != 0);
        },
        .Suspend => {
            const id = task.id.?;
            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "suspend {}", .{id});
            assert(try std.posix.send(socket, msg, 0) != 0);
        },
        .Resume => {
            const id = task.id.?;
            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "resume {}", .{id});
            assert(try std.posix.send(socket, msg, 0) != 0);
        },
        .Remove => {
            const id = task.id.?;
            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "remove {}", .{id});
            assert(try std.posix.send(socket, msg, 0) != 0);
        },
        .Info => {
            const id = task.id.?;
            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "info {}", .{id});
            assert(try std.posix.send(socket, msg, 0) != 0);

            const read = try std.posix.recv(socket, &buff, 0);
            std.debug.print("{s}", .{buff[0..read]});
        },
        .List => {
            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "list", .{});
            assert(try std.posix.send(socket, msg, 0) != 0);

            std.debug.print("ID PRI  Path               Progress    Status   Details\n", .{});
            // const read = try std.posix.recv(socket, &msg, 0);
            // TODO:
            // const jobs = toNum(msg);
            // for (0..jobs) |i| {
            //   send(give ith)
            //   job = recieve()
            //   print(job)
            // }
        },
        .Print => {
            const id = task.id.?;
            var buff: [1024]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buff, "print {}", .{id});
            assert(try std.posix.send(socket, msg, 0) != 0);

            const read = try std.posix.recv(socket, &buff, 0);
            std.debug.print("{s}", .{buff[0..read]});
        },
        .Empty => {},
    }
}

test {
    _ = @import("cli.zig");
}
