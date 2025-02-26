const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

const PriorityLevel = enum {
    Low,
    Normal,
    High,
};

const ParseError = error{
    InvalidOption,
    InvalidCommand,
    InvalidArgument,
    ExpectedArgument,
};

const OptionType = enum {
    Help,
    Priority,

    fn from_str(arg: []const u8) ParseError!OptionType {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            return .Help;
        }

        if (std.mem.eql(u8, arg, "--priority") or std.mem.eql(u8, arg, "-p")) {
            return .Priority;
        }
        return ParseError.InvalidOption;
    }
};

const Option = union(OptionType) {
    Help: void,
    Priority: PriorityLevel,
};

const Command = enum {
    Add,
    Suspend,
    Resume,
    Remove,
    Info,
    List,
    Print,
    Empty,

    fn from_str(arg: []const u8) ParseError!Command {
        if (std.mem.eql(u8, arg, "add")) {
            return .Add;
        }

        if (std.mem.eql(u8, arg, "suspend")) {
            return .Suspend;
        }

        if (std.mem.eql(u8, arg, "resume")) {
            return .Resume;
        }

        if (std.mem.eql(u8, arg, "remove")) {
            return .Remove;
        }

        if (std.mem.eql(u8, arg, "info")) {
            return .Info;
        }

        if (std.mem.eql(u8, arg, "list")) {
            return .List;
        }

        if (std.mem.eql(u8, arg, "print")) {
            return .Print;
        }

        return ParseError.InvalidCommand;
    }
};

const Token = union(enum) {
    Cmd: Command,
    Val: []const u8,
    Opt: OptionType,
};

const Task = struct {
    const Self = @This();

    command: Command,
    alloc: std.mem.Allocator,
    option: ?OptionType = null,
    id: ?u8 = null,
    priority: ?PriorityLevel = null,
    root: ?[]const u8 = null,
    err: ?[]const u8 = null,

    pub fn init(command: Command, alloc: std.mem.Allocator) Self {
        return Self{
            .command = command,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *const Self) void {
        if (self.root != null) {
            self.alloc.free(self.root.?);
        }
    }

    pub fn resolve_option(self: *const Self) void {
        assert(self.option != null);
        switch (self.option.?) {
            .Help => {
                switch (self.command) {
                    .Add => {
                        std.debug.print("Add a new directory to be analyzed\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini add [OPTIONS] <DIR>\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mOptions:\x1b[0m\n", .{});
                        std.debug.print("  -p, --priority <value>\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mInfo:\x1b[0m\n", .{});
                        std.debug.print("  Value of 0 = Low\n", .{});
                        std.debug.print("  Value of 1 = Normal (default)\n", .{});
                        std.debug.print("  Value of 2 = High\n", .{});
                    },
                    .Resume => {
                        std.debug.print("Resume a running analyzing job\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini resume <ID>\n", .{});
                    },
                    .Remove => {
                        std.debug.print("Remove a running analyzing job\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini remove <ID>\n", .{});
                    },
                    .List => {
                        std.debug.print("Print a list of all the analyzing jobs\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini remove <ID>\n", .{});
                    },
                    .Suspend => {
                        std.debug.print("Suspend a running analyzing job\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini suspend <ID>\n", .{});
                    },
                    .Info => {
                        std.debug.print("Print the status (pending, progress, done) of a job\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini info <ID>\n", .{});
                    },
                    .Print => {
                        std.debug.print("Print the report of an analyzing job\n", .{});
                        std.debug.print("\n", .{});
                        std.debug.print("\x1b[4mUsage:\x1b[0m jini print <ID>\n", .{});
                    },
                    else => {},
                }
            },
            .Priority => {},
        }
    }
};

pub const CLI = struct {
    const Self = @This();

    alloc: std.mem.Allocator,
    args: [][]const u8,

    pub fn new(args: [][]const u8, alloc: std.mem.Allocator) Self {
        return Self{ .args = args, .alloc = alloc };
    }

    pub fn tokenize(self: *const Self) !ArrayList(Token) {
        var tokens = ArrayList(Token).init(self.alloc);
        errdefer tokens.deinit();

        for (self.args, 0..) |arg, i| {
            _ = i;

            if (std.mem.startsWith(u8, arg, "-")) {
                const option = try OptionType.from_str(arg);
                try tokens.append(Token{ .Opt = option });
            } else {
                const command = Command.from_str(arg) catch {
                    try tokens.append(Token{ .Val = arg });
                    continue;
                };
                try tokens.append(Token{ .Cmd = command });
            }
        }

        return tokens;
    }

    pub fn parse(self: *const Self) !Task {
        var task: Task = Task.init(.Empty, self.alloc);
        errdefer task.deinit();

        const tokens = try self.tokenize();
        defer tokens.deinit();

        var i: usize = 0;
        while (i < tokens.items.len) : (i += 1) {
            const token = tokens.items[i];
            switch (token) {
                .Cmd => |cmd| {
                    if (task.command != .Empty) continue;
                    task.command = cmd;

                    if (cmd != .List and cmd != .Empty) {
                        if (i + 1 >= tokens.items.len) {
                            task.option = .Help;
                            break;
                        }

                        if (tokens.items[i + 1] != .Val) {
                            task.option = .Help;
                            break;
                        }
                    }

                    switch (cmd) {
                        .Add => {
                            task.root = try self.alloc.dupe(u8, tokens.items[i + 1].Val);
                            if (task.priority == null) task.priority = .Normal;
                        },
                        .Suspend,
                        .Resume,
                        .Remove,
                        .Info,
                        .Print,
                        => {
                            task.id = std.fmt.parseInt(u8, tokens.items[i + 1].Val, 10) catch {
                                task.err = "error: Invalid argument!\n <id> should be a number\n";
                                break;
                            };
                        },
                        .List, .Empty => continue,
                    }
                },
                .Opt => |opt| {
                    if (task.option != null) continue;
                    switch (opt) {
                        .Help => task.option = .Help,
                        .Priority => {
                            if (i + 1 >= self.args.len) return ParseError.ExpectedArgument;
                            const lvl = std.fmt.parseInt(u8, tokens.items[i + 1].Val, 10) catch {
                                task.err = "error: Invalid argument!\n <priority> should be a number\n";
                                break;
                            };

                            if (lvl > 2) {
                                task.err = "error: <priority> should be a number between 0 and 2\n";
                                break;
                            }

                            task.priority = @enumFromInt(lvl);
                        },
                    }
                },
                .Val => continue,
            }
        }
        return task;
    }

    pub fn help() void {
        std.debug.print("Disk usage analyzer\n", .{});
        std.debug.print("\n", .{});
        std.debug.print("\x1b[4mUsage:\x1b[0m jini <COMMAND>\n", .{});
        std.debug.print("\n", .{});
        std.debug.print("\x1b[4mCommands:\x1b[0m\n", .{});
        std.debug.print("  add        Add a new directory to be analyzed \n", .{});
        std.debug.print("  suspend    Suspend a running analyzing job\n", .{});
        std.debug.print("  resume     Resume a suspended analyzing job\n", .{});
        std.debug.print("  remove     Remove an analyzing job\n", .{});
        std.debug.print("  info       Print the status (pending, progress, done) of a job\n", .{});
        std.debug.print("  list       Print a list of all the analyzing jobs\n", .{});
        std.debug.print("  print      Print the report of an analyzing job that is done\n", .{});
        std.debug.print("\n", .{});
        std.debug.print("\x1b[4mOptions:\x1b[0m\n", .{});
        std.debug.print("  -h, --help       Print help\n", .{});
        std.debug.print("  -v, --version    Print version\n", .{});
    }
};

const testing = std.testing;

test "parse_empty_add" {
    const alloc = testing.allocator;
    var args = [_][]const u8{"add"};
    const want = Task{
        .alloc = alloc,
        .command = .Add,
        .id = null,
        .option = .Help,
        .priority = null,
        .root = null,
        .err = null,
    };

    const cli = CLI.new(&args, alloc);
    const task = try cli.parse();
    defer task.deinit();

    try testing.expectEqualDeep(want, task);
}

test "parse_add" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "add", "/home/user/proj", "--priority", "2" };
    const want = Task{
        .alloc = alloc,
        .command = .Add,
        .id = null,
        .option = null,
        .priority = .High,
        .root = "/home/user/proj",
        .err = null,
    };

    const cli = CLI.new(&args, alloc);
    const task = try cli.parse();
    defer task.deinit();

    try testing.expectEqualDeep(want, task);
}

test "parse_add_invalid_value" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "add", "/home/user/proj", "--priority", "3" };
    const cli = CLI.new(&args, alloc);
    const want = Task{
        .alloc = alloc,
        .command = .Add,
        .id = null,
        .option = null,
        .priority = .Normal,
        .root = "/home/user/proj",
        .err = "error: <priority> should be a number between 0 and 2\n",
    };

    const task = try cli.parse();
    defer task.deinit();
    try testing.expectEqualDeep(want, task);
}

test "add_priority_not_a_number" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "add", "/home/user/proj", "--priority", "f" };
    const cli = CLI.new(&args, alloc);
    const want = Task{
        .alloc = alloc,
        .command = .Add,
        .id = null,
        .option = null,
        .priority = .Normal,
        .root = "/home/user/proj",
        .err = "error: Invalid argument!\n <priority> should be a number\n",
    };

    const task = try cli.parse();
    defer task.deinit();
    try testing.expectEqualDeep(want, task);
}

test "parse_add_reverse_order" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "-p", "2", "add", "/home/user/proj" };
    const cli = CLI.new(&args, alloc);
    const want = Task{
        .alloc = alloc,
        .command = .Add,
        .id = null,
        .option = null,
        .priority = .High,
        .root = "/home/user/proj",
        .err = null,
    };

    const task = try cli.parse();
    defer task.deinit();
    try testing.expectEqualDeep(want, task);
}

test "parse_add_invalid_option" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "add", "/home/user/proj", "--pro", "4" };
    const cli = CLI.new(&args, alloc);

    const task = cli.parse();
    try testing.expectEqualDeep(ParseError.InvalidOption, task);
}

test "parse_add_invalid_argument" {
    const alloc = testing.allocator;
    var args = [_][]const u8{ "add", "/home/user/proj", "--priority" };
    const cli = CLI.new(&args, alloc);

    const task = cli.parse();
    try testing.expectEqualDeep(ParseError.ExpectedArgument, task);
}
