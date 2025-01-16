const std = @import("std");
const Priority = @import("job.zig").Priority;

const Command = enum {
    Add,
    Priority,
    Suspend,
    Resume,
    Remove,
    Info,
    List,
    Print,
    Help,
    Unknown,

    fn fromStr(arg: []const u8) Command {
        if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--add")) {
            return .Add;
        }

        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--priority")) {
            return .Priority;
        }

        if (std.mem.eql(u8, arg, "-S") or std.mem.eql(u8, arg, "--suspend")) {
            return .Suspend;
        }

        if (std.mem.eql(u8, arg, "-R") or std.mem.eql(u8, arg, "--resume")) {
            return .Resume;
        }

        if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "--remove")) {
            return .Remove;
        }

        if (std.mem.eql(u8, arg, "-i") or std.mem.eql(u8, arg, "--info")) {
            return .Info;
        }

        if (std.mem.eql(u8, arg, "-l") or std.mem.eql(u8, arg, "--list")) {
            return .List;
        }

        if (std.mem.eql(u8, arg, "-P") or std.mem.eql(u8, arg, "--print")) {
            return .Print;
        }

        if (std.mem.eql(u8, arg, "--help")) {
            return .Help;
        }

        return .Unknown;
    }
};

pub const CLI = struct {
    command: Command = .Help,
    priority: Priority = .Normal,
    id: ?u8 = null,
    arg_err: ?[]const u8 = null,
    root: []const u8 = "",
    alloc: std.mem.Allocator,
    args: [][]const u8,

    pub fn new(args: [][]const u8, alloc: std.mem.Allocator) CLI {
        return CLI{ .args = args, .alloc = alloc };
    }

    pub fn deinit(self: *CLI) void {
        self.alloc.free(self.root);
        if (self.arg_err) |err| {
            self.alloc.free(err);
        }
    }

    pub fn getId(self: *CLI) ?u8 {
        return self.id;
    }

    pub fn getPriority(self: *CLI) Priority {
        return self.priority;
    }

    pub fn getRoot(self: *CLI) []const u8 {
        return self.root;
    }

    pub fn hasErr(self: *CLI) bool {
        return self.arg_err != null;
    }

    pub fn getErr(self: *CLI) ?[]const u8 {
        return self.arg_err;
    }

    pub fn parse(self: *CLI) !void {
        var i: usize = 0;
        while (i < self.args.len) : (i += 1) {
            const arg = self.args[i];
            const command = Command.fromStr(arg);
            switch (command) {
                .Add => {
                    if (i + 1 < self.args.len and Command.fromStr(self.args[i + 1]) == .Unknown) {
                        i += 1;

                        self.command = command;
                        self.root = try self.alloc.dupe(u8, self.args[i]);
                    } else {
                        if (self.arg_err == null) {
                            self.arg_err = try std.fmt.allocPrint(self.alloc, "jini: Missing argumet for option {s}", .{arg});
                        }
                    }
                },
                .List => {
                    self.command = command;
                },
                .Priority => {
                    if (i + 1 < self.args.len and Command.fromStr(self.args[i + 1]) == .Unknown) {
                        i += 1;

                        const id = try std.fmt.parseInt(u8, self.args[i], 10);
                        self.id = id;
                    } else {
                        if (self.arg_err == null) {
                            self.arg_err = try std.fmt.allocPrint(self.alloc, "jini: Missing argumet for option {s}", .{arg});
                        }
                    }
                },
                .Suspend, .Resume, .Remove, .Info, .Print => {
                    if (i + 1 < self.args.len and Command.fromStr(self.args[i + 1]) == .Unknown) {
                        i += 1;

                        self.command = command;
                        const id = try std.fmt.parseInt(u8, self.args[i], 10);
                        self.id = id;
                    } else {
                        if (self.arg_err == null) {
                            self.arg_err = try std.fmt.allocPrint(self.alloc, "jini: Missing argumet for option {s}", .{arg});
                        }
                    }
                },
                .Help => {
                    self.command = command;
                },
                .Unknown => unreachable,
            }
        }
    }

    fn help() void {
        const message =
            \\Usage: `jini [OPTION] [DIR]`
            \\Analyze the space occupied by the directory at `[DIR]`
            \\  -a, --add analyze a new directory path for disk usage
            \\  -p, --priority set priority for the new analysis (works only with -a argument)
            \\  -S, --suspend <id> suspend task with <id>
            \\  -R, --resume <id> resume task with <id>
            \\  -r, --remove <id> remove the analysis with the given <id>
            \\  -i, --info <id> print status about the analysis with <id> (pending, progress, done)
            \\  -l, --list list all analysis tasks, with their ID and the corresponding root
            \\  -P, --print <id> print analysis report for those tasks that are "done"
        ;

        std.debug.print("{s}\n", .{message});
    }
};

const testing = std.testing;
test "add_parse" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "-a", "/home/dev/repo" };
    var want = CLI{
        .alloc = alloc,
        .command = .Add,
        .priority = .Normal,
        .args = &args,
        .arg_err = null,
        .id = null,
        .root = try alloc.dupe(u8, "/home/dev/repo"),
    };
    defer want.deinit();

    var cli = CLI.new(&args, alloc);
    try cli.parse();
    defer cli.deinit();

    try testing.expectEqualDeep(want, cli);
}

test "add_parse_err" {
    const alloc = testing.allocator;
    var args = [_][]const u8{"-a"};
    var want = CLI{
        .alloc = alloc,
        .command = .Help,
        .priority = .Normal,
        .args = &args,
        .arg_err = try alloc.dupe(u8, "jini: Missing argumet for option -a"),
        .id = null,
        .root = "",
    };
    defer want.deinit();

    var cli = CLI.new(&args, alloc);
    try cli.parse();
    defer cli.deinit();

    try testing.expectEqualDeep(want, cli);
}

test "add_parse_err2" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "-a", "-p" };
    var want = CLI{
        .alloc = alloc,
        .command = .Help,
        .priority = .Normal,
        .args = &args,
        .arg_err = try alloc.dupe(u8, "jini: Missing argumet for option -a"),
        .id = null,
        .root = "",
    };
    defer want.deinit();

    var cli = CLI.new(&args, alloc);
    try cli.parse();
    defer cli.deinit();

    try testing.expectEqualDeep(want, cli);
}
