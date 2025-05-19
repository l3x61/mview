const Viewer = @This();

const std = @import("std");
const log = std.log.scoped(.Viewer);
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const zgui = @import("zgui");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

pub const window_title = "Viewer";

const GUI = @import("GUI.zig");

allocator: Allocator = undefined,

pub fn init(allocator: Allocator) !Viewer {
    log.debug("{s}() ", .{@src().fn_name});

    var self = Viewer{};
    self.allocator = allocator;
    return self;
}

pub fn deinit(_: *Viewer) void {
    log.debug("{s}()", .{@src().fn_name});
}

pub fn update(_: *Viewer) !void {}

pub fn draw(_: *Viewer, _: *GUI) !void {
    if (zgui.begin(window_title, .{ .flags = .{} })) {}
    zgui.end();
}
