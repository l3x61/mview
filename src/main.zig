const std = @import("std");
const log = std.log.scoped(.main);

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("utils/logFn.zig").logFn,
};

pub fn main() !void {
    log.debug("{s}() started", .{@src().fn_name});
    defer log.debug("{s}() exited", .{@src().fn_name});

    std.debug.print("Hello World!\n", .{});
}
