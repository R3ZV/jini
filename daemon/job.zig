const std = @import("std");

const Priority = enum {
    Low,
    Normal,
    Heigh,
};

const Status = enum { Running, Done, Suspended };

const Job = struct {
    id: u8,
    priority: Priority,
    root: []const u8,
    files: u32 = 0,
    dirs: u32 = 0,
    work: u8 = 0,
    status: Status = .Running,

    pub fn new(id: u8, priority: Priority, root: []const u8) Job {
        return Job{
            .id = id,
            .priority = priority,
            .root = root,
        };
    }

    pub fn suspend_job(self: *Job) void {
        if (self.status == .Running) {
            self.status = .Suspended;
        }
    }

    pub fn resume_job(self: *Job) void {
        if (self.status == .Suspended) {
            self.status = .Running;
        }
    }

    pub fn print(self: *Job) void {
        // TODO:
        _ = self;
        unreachable;
    }

    pub fn info(self: *Job) void {
        switch (self.status) {
            .Running => std.debug.print("Status: Running {d}%\n", self.work),
            .Suspend => std.debug.print("Status: Suspended\n"),
            .Done => std.debug.print("Status: Done\n"),
        }
    }

    pub fn format(alloc: std.mem.Allocator, self: *Job) ?[]const u8 {
        return try std.fmt.allocPrint(alloc, "{d} {s} {d}% {s}  {d} files, {d} dirs", .{
            self.id,
            self.priority,
            self.root,
            self.work,
            self.status,
            self.files,
            self.dirs,
        });
    }
};

pub fn remove_job(jobs: std.ArrayList([]const Job), id: u8) bool {
    var idx: ?usize = null;
    for (jobs.items) |job| {
        if (job.id == id) {
            idx = id;
        }
    }
    if (idx != null) {
        jobs.orderedRemove(idx.?);
        return true;
    }
    return false;
}

pub fn get_by_id(jobs: std.ArrayList([]const Job), id: u8) ?Job {
    for (jobs.items) |job| {
        if (job.id == id) {
            return job;
        }
    }
    return null;
}
