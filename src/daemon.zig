const std = @import("std");

const Signal = enum(u8) {
    /// Terminate cleanly
    SIGTERM,

    /// Reload config file
    SIGHUP,

    SIGINT,

    UNKNOWN,
};

pub const Daemon = struct {
    const Self = @This();

    running: bool = true,
    reload: bool = false,

    // signal(SIGINT, Daemon::signalHandler);
    // signal(SIGTERM, Daemon::signalHandler);
    // signal(SIGHUP, Daemon::signalHandler);

    pub fn init() Self {
        return Self{};
    }

    pub fn check_reload(self: *Self) bool {
        if (self.reload) {
            self.handle_reload();
            self.reload = false;
        }

        return self.running;
    }

    pub fn handle_reload(self: *Self) void {
        _ = self;
        std.debug.print("Reloading...");
    }

    pub fn handle_signals(self: *Self, signal: u32) void {
        const variant: Signal = @enumFromInt(signal);
        switch (variant) {
            .SIGTERM, .SIGINT => self.running = false,
            .SIGHUP => self.reload = true,
            .UNKNOWN => unreachable,
        }
    }
};
