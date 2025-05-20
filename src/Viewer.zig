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
const Image = @import("Image.zig");

allocator: Allocator = undefined,
name: ?[:0]const u8 = undefined,
image: ?Image = null,

pub fn init(allocator: Allocator) !Viewer {
    log.debug("{s}() ", .{@src().fn_name});
    var self = Viewer{};
    self.allocator = allocator;
    return self;
}

pub fn deinit(self: *Viewer) void {
    log.debug("{s}()", .{@src().fn_name});
    if (self.image) |*image| {
        image.deinit();
    }
}

fn getStrOrAlt(name: ?[:0]const u8) [:0]const u8 {
    return if (name) |n| n else "N/A";
}

pub fn display(self: *Viewer, name: ?[:0]const u8) !void {
    log.info("{s}('{s}') ", .{ @src().fn_name, getStrOrAlt(name) });

    if (self.image) |*image| {
        image.deinit();
    }
    self.image = null;

    if (name) |n| {
        self.image = try Image.init(self.allocator, n);
    }
}

pub fn update(_: *Viewer) !void {}

pub fn draw(self: *Viewer, _: *GUI) !void {
    if (zgui.begin(window_title, .{ .flags = .{} })) {
        zgui.text("{s}", .{getStrOrAlt(self.name)});
        if (self.image) |*image| {
            zgui.image(
                @ptrFromInt(@as(usize, @intCast(image.texture))),
                .{
                    .w = @floatFromInt(image.width),
                    .h = @floatFromInt(image.height),
                },
            );
        }
    }
    zgui.end();
}
