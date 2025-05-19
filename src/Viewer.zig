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
name: ?[:0]const u8 = undefined,

pub fn init(allocator: Allocator) !Viewer {
    log.debug("{s}() ", .{@src().fn_name});

    var self = Viewer{};
    self.allocator = allocator;
    return self;
}

pub fn deinit(_: *Viewer) void {
    log.debug("{s}()", .{@src().fn_name});
}

fn getNameOrAlt(self: Viewer) [:0]const u8 {
    return if (self.name) |n| n else "N/A";
}

pub fn display(self: *Viewer, name: ?[:0]const u8) !void {
    self.name = name;
    log.info("{s}() {s}", .{ @src().fn_name, self.getNameOrAlt() });
}

pub fn update(_: *Viewer) !void {}

pub fn draw(self: *Viewer, _: *GUI) !void {
    if (zgui.begin(window_title, .{ .flags = .{} })) {
        zgui.text("{s}", .{self.getNameOrAlt()});
    }
    zgui.end();
}
