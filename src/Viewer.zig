const std = @import("std");
const math = std.math;
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
offset: [2]f32 = [_]f32{ 0, 0 },
scale: f32 = 1.0,

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
    self.name = null;
    self.image = null;

    if (name) |n| {
        self.name = n;
        self.image = Image.init(self.allocator, n) catch |err| {
            log.warn("{s}('{s}') {!} ignored", .{ @src().fn_name, n, err });
            return;
        };
        self.offset = [_]f32{ 0, 0 };
        self.scale = 1.0;
    }
}

pub fn update(_: *Viewer) !void {}

pub fn draw(self: *Viewer, _: *GUI) !void {
    if (zgui.begin(window_title, .{ .flags = .{ .no_scrollbar = true } })) {
        if (zgui.isWindowHovered(.{}) and zgui.isMouseDragging(.left, 0.0)) {
            zgui.setMouseCursor(.resize_all);
            const delta = zgui.getMouseDragDelta(.left, .{ .lock_threshold = 0 });
            self.offset[0] += delta[0];
            self.offset[1] += delta[1];
            zgui.resetMouseDragDelta(.left);
        }

        if (self.image) |*image| {
            const window_size = zgui.getWindowSize();
            const image_size = [_]f32{
                image.width * self.scale,
                image.height * self.scale,
            };
            const image_pos = [_]f32{
                (window_size[0] - image_size[0]) / 2 + self.offset[0],
                (window_size[1] - image_size[1]) / 2 + self.offset[1],
            };
            zgui.setCursorPos(image_pos);
            zgui.image(@ptrFromInt(@as(usize, @intCast(image.texture))), .{ .w = image_size[0], .h = image_size[1] });
        }
    }
    zgui.end();
}

// for debugging
fn point(s: f32, p: [2]f32, col: u32) void {
    const draw_list = zgui.getWindowDrawList();
    draw_list.addRectFilled(.{
        .pmin = [2]f32{ p[0] - s, p[1] - s },
        .pmax = [2]f32{ p[0] + s, p[1] + s },
        .col = col,
    });
}
