const std = @import("std");
const Allocator = std.mem.Allocator;

const zgui = @import("zgui");

const GUI = @import("GUI.zig");
const Image = @import("Image.zig");

const Viewer = @This();

const log = std.log.scoped(.Viewer);
pub const window_title = "Viewer";

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
        self.image = Image.init(self.allocator, n) catch |err| {
            log.warn("{s}('{s}') {!} ignored", .{ @src().fn_name, n, err });
            return;
        };
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
                    .w = image.width,
                    .h = image.height,
                },
            );
        }
    }
    zgui.end();
}
