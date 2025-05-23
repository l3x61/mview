const std = @import("std");
const Allocator = std.mem.Allocator;

const gl = @import("zopengl").bindings;

const Image = @This();
const log = std.log.scoped(.Image);
const MagickWand = @import("MagickWand.zig");

allocator: Allocator = undefined,
width: usize = undefined,
height: usize = undefined,
pixels: []u8 = undefined,

pub fn init(allocator: Allocator, name: [:0]const u8) !Image {
    log.debug("{s}('{s}') ", .{ @src().fn_name, name });

    var wand = try MagickWand.init();
    defer wand.deinit();

    try wand.readImage(name);

    const format = "RGBA";
    try wand.setImageFormat(format);

    const width = wand.getImageWidth();
    const height = wand.getImageHeight();

    var self = Image{};

    self.allocator = allocator;
    self.width = width;
    self.height = height;
    self.pixels = try wand.exportImagePixels(allocator, 0, 0, @intCast(width), @intCast(height), format);

    return self;
}

pub fn deinit(self: *Image) void {
    self.allocator.free(self.pixels);
}
