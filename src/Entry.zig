const Entry = @This();

const std = @import("std");
const fs = std.fs;
const Kind = fs.Dir.Entry.Kind;

const Allocator = std.mem.Allocator;

kind: Kind = undefined,
name: [:0]u8 = undefined,

pub fn init(allocator: Allocator, dir_entry: fs.Dir.Entry) !Entry {
    var self = Entry{};

    self.kind = dir_entry.kind;
    self.name = try allocator.dupeZ(u8, dir_entry.name);

    return self;
}

pub fn deinit(self: *Entry, allocator: Allocator) void {
    allocator.free(self.name);
}

pub fn directory(self: Entry) bool {
    return self.kind == .directory;
}

pub fn format(self: Entry, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("{s} '{s}'", .{ @tagName(self.kind), self.name });
}
