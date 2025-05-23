const std = @import("std");
const Allocator = std.mem.Allocator;

const Texture = @import("Texture.zig");
const Image = @import("Image.zig");

const Media = @This();
const log = std.log.scoped(.Media);

texture: Texture = undefined,

pub fn initImage(allocator: Allocator, name: [:0]const u8) !Media {
    log.debug("{s}()", .{@src().fn_name});
    var image = try Image.init(allocator, name);
    defer image.deinit();

    return Media{
        .texture = try Texture.initFromImage(image),
    };
}

pub fn deinit(self: *Media) void {
    log.debug("{s}()", .{@src().fn_name});
    self.texture.deinit();
}

const zgui = @import("zgui");

pub fn draw(self: Media, pos: [2]f32, scale: f32) void {
    //log.debug("{s}({d}, {d})", .{ @src().fn_name, pos, scale });

    const texptr: *anyopaque = @ptrFromInt(@as(usize, @intCast(self.texture.id)));
    const w = @as(f32, @floatFromInt(self.texture.width)) * scale;
    const h = @as(f32, @floatFromInt(self.texture.height)) * scale;

    zgui.setCursorPos(pos);
    zgui.image(texptr, .{ .w = w, .h = h });
}
