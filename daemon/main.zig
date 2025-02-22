const std = @import("std");

pub fn main() !void {
    const socket = try std.posix.socket(std.c.AF.UNIX, std.c.SOCK.STREAM, 0);
    const addr_path = "/tmp/counter.sock";
    const addr = try std.net.Address.initUnix(addr_path);

    try std.posix.bind(socket, &addr.any, addr.getOsSockLen());
    defer std.posix.unlink(addr_path) catch @panic("Couldn't unlink!");

    std.debug.print("Listening...\n", .{});
    try std.posix.listen(socket, 0);

    var cnt: u8 = 0;
    while (true) {
        const client = try std.posix.accept(socket, null, null, 0);
        defer std.posix.close(client);

        var buff: [1024]u8 = undefined;
        const read = try std.posix.recv(client, &buff, 0);
        std.debug.print("Received: {s}\n", .{buff[0..read]});

        if (std.mem.eql(u8, buff[0..read], "--minus")) {
            cnt -= 1;
        } else if (std.mem.eql(u8, buff[0..read], "--plus")) {
            cnt += 1;
        } else {
            break;
        }

        const res = try std.fmt.bufPrint(&buff, "{}", .{cnt});
        _ = try std.posix.send(client, res, 0);
    }
}
