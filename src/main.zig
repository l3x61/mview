const std = @import("std");
const heap = std.heap;
const assert = std.debug.assert;

const GUI = @import("GUI.zig");

const log = std.log.scoped(.main);
pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("utils/logFn.zig").logFn,
};

pub fn main() !void {
    log.debug("{s}()", .{@src().fn_name});

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var gui = try GUI.init(allocator);
    defer gui.deinit();

    try gui.run();
}
