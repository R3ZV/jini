const std = @import("std");
const CLI = @import("cli.zig").CLI;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var args = [_][]const u8{ "-a", "/home/user/repo" };
    var cli = CLI.new(&args, alloc);
    defer cli.deinit();
    try cli.parse();
}
