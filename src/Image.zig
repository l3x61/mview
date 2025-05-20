const std = @import("std");
const Allocator = std.mem.Allocator;

const gl = @import("zopengl").bindings;

const Image = @This();
const log = std.log.scoped(.Image);
const c = @cImport({
    @cInclude("MagickWand/MagickWand.h");
});

allocator: Allocator = undefined,
name: ?[:0]const u8 = undefined,
texture: gl.Uint = undefined,
width: usize = undefined,
height: usize = undefined,

pub fn init(allocator: Allocator, name: [:0]const u8) !Image {
    log.info("{s}('{s}') ", .{ @src().fn_name, name });

    var buffer: [std.fs.max_path_bytes]u8 = [_]u8{0} ** std.fs.max_path_bytes;
    const path = try std.fs.cwd().realpath(".", &buffer);
    log.info("realpath: {s}", .{path});

    c.MagickWandGenesis();
    defer c.MagickWandTerminus();

    const wand = c.NewMagickWand();
    defer _ = c.DestroyMagickWand(wand);

    if (c.MagickReadImage(wand, name) == c.MagickFalse) {
        printError(wand);
        return error.ImageReadError;
    }

    if (c.MagickSetImageFormat(wand, "RGBA") == c.MagickFalse) {
        printError(wand);
        return error.ImageFormatError;
    }

    const width = c.MagickGetImageWidth(wand);
    const height = c.MagickGetImageHeight(wand);

    const pixels = try allocator.alloc(u8, width * height * 4);
    defer allocator.free(pixels);
    if (c.MagickExportImagePixels(wand, 0, 0, width, height, "RGBA", c.CharPixel, pixels.ptr) == c.MagickFalse) {
        printError(wand);
        return error.ImageExportError;
    }

    var texture: gl.Uint = undefined;
    gl.genTextures(1, &texture);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        @intCast(width),
        @intCast(height),
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        pixels.ptr,
    );

    if (gl.getError() != gl.NO_ERROR) {
        return error.ImageOpenGLTextureError;
    }

    var self = Image{};
    self.allocator = allocator;
    self.name = name;
    self.width = width;
    self.height = height;
    self.texture = texture;
    return self;
}

fn printError(wand: ?*c.MagickWand) void {
    var severity: c.ExceptionType = undefined;
    const description = c.MagickGetException(wand, &severity);
    log.err("{d}: {s}", .{ severity, description });
}

pub fn deinit(self: *Image) void {
    log.debug("{s}()", .{@src().fn_name});
    if (self.name) |_| {
        gl.deleteTextures(1, &self.texture);
    }
}
