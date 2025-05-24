const std = @import("std");
const math = std.math;
const time = std.time;
const Timer = time.Timer;
const Allocator = std.mem.Allocator;

const zgui = @import("zgui");
const App = @import("App.zig");
const Media = @import("Media.zig");
const Entry = @import("Entry.zig");


const Viewer = @This();
const log = std.log.scoped(.Viewer);

pub const window_title = "Viewer";

allocator: Allocator = undefined,
media: ?Media = null,
pan: [2]f32 = [_]f32{ 0, 0 },
zoom: f32 = 1.0,
zoom_factor: f32 = 1.5,

pub fn init(allocator: Allocator) !Viewer {
    log.debug("{s}() ", .{@src().fn_name});
    var self = Viewer{};
    self.allocator = allocator;
    return self;
}

pub fn deinit(self: *Viewer) void {
    log.debug("{s}()", .{@src().fn_name});
    if (self.media) |*image| {
        image.deinit();
    }
}

pub fn loadMedia(self: *Viewer, name: [:0]const u8) !void {
    log.info("{s}('{s}')", .{ @src().fn_name, name });

    var timer = try Timer.start();
    self.media = Media.initImage(self.allocator, name) catch |err| {
        log.warn("{s}('{s}') {!} ignored", .{ @src().fn_name, name, err });
        return;
    };
    const ns = timer.read();
    log.info("{s}() took {d}ms", .{ @src().fn_name, ns / time.ns_per_ms});

    self.resetView();
}

pub fn unloadMedia(self: *Viewer) void {
    log.debug("{s}()", .{@src().fn_name});

    if (self.media) |*media| media.deinit();
    self.media = null;
}

pub fn resetView(self: *Viewer) void {
    self.pan = [_]f32{ 0, 0 };
    if (self.media) |media| {
        const window_size = zgui.getMainViewport().getWorkSize();

        const sx: f32 = window_size[0] / @as(f32, @floatFromInt(media.texture.width));
        const sy: f32 = window_size[1] / @as(f32, @floatFromInt(media.texture.height));

        self.zoom = @min(sx, sy);
    }
}

pub fn update(_: *Viewer) !void {}

pub fn draw(self: *Viewer) !void {
    if (zgui.begin(window_title, .{ .flags = .{ .no_scrollbar = true, .no_scroll_with_mouse = true } })) {
        if (zgui.isWindowHovered(.{})) {
            if (zgui.isMouseDragging(.left, 0.0)) {
                zgui.setMouseCursor(.resize_all);
                const delta = zgui.getMouseDragDelta(.left, .{ .lock_threshold = 0 });
                self.pan[0] += delta[0];
                self.pan[1] += delta[1];
                zgui.resetMouseDragDelta(.left);
            }

            const old_zoom = self.zoom;
            // zoom in/out
            const scroll_y = App.mouseWheelScrollY();
            if (scroll_y > 0) {
                self.zoom *= self.zoom_factor;
            } else if (scroll_y < 0) {
                self.zoom /= self.zoom_factor;
            }
            // reset zoom
            if (zgui.isKeyPressed(.mouse_middle, false)) {
                self.zoom = 1.0;
            }
            self.zoom = std.math.clamp(self.zoom, 0.005, 1000);
            const window_pos = zgui.getWindowPos();
            const global_mouse_pos = zgui.getMousePos();
            const local_mouse_pos = [_]f32{
                global_mouse_pos[0] - window_pos[0],
                global_mouse_pos[1] - window_pos[1],
            };
            if (self.zoom != old_zoom) {
                const scale = self.zoom / old_zoom;
                self.pan[0] = (self.pan[0] - local_mouse_pos[0]) * scale + local_mouse_pos[0];
                self.pan[1] = (self.pan[1] - local_mouse_pos[1]) * scale + local_mouse_pos[1];
            }
        }

        if (self.media) |media| media.draw(self.pan, self.zoom);
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
