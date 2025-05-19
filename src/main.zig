const std = @import("std");
const log = std.log.scoped(.main);
const heap = std.heap;
const assert = std.debug.assert;

const GUI = @import("GUI.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("utils/logFn.zig").logFn,
};

pub fn main() !void {
    log.debug("{s}()", .{@src().fn_name});

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer assert(gpa.deinit() == .ok);

    var gui = try GUI.init(allocator);
    defer gui.deinit();

    try gui.run();
}
