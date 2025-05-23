const std = @import("std");
const Allocator = std.mem.Allocator;

const MagickWand = @This();
const log = std.log.scoped(.MagickWand);
const c = @cImport({
    @cInclude("MagickWand/MagickWand.h");
});

wand: *c.MagickWand = undefined,

const MagickTrue = c.MagickTrue;
const MagickFalse = c.MagickFalse;

const MagickWandGenesis = c.MagickWandGenesis; // https://imagemagick.org/api/magick-wand.php#MagickWandGenesis
const MagickWandTerminus = c.MagickWandTerminus; // https://imagemagick.org/api/magick-wand.php#MagickWandTerminus

const NewMagickWand = c.NewMagickWand; // https://imagemagick.org/api/magick-wand.php#NewMagickWand
const DestroyMagickWand = c.DestroyMagickWand; // https://imagemagick.org/api/magick-wand.php#DestroyMagickWand

const MagickGetException = c.MagickGetException; // https://imagemagick.org/api/magick-wand.php#MagickGetException
const MagickRelinquishMemory = c.MagickRelinquishMemory; // https://imagemagick.org/api/magick-wand.php#MagickRelinquishMemory

const MagickSetImageFormat = c.MagickSetImageFormat; // https://imagemagick.org/api/magick-image.php#MagickSetImageFormat

const MagickGetImageWidth = c.MagickGetImageWidth; // https://imagemagick.org/api/magick-image.php#MagickGetImageWidth
const MagickGetImageHeight = c.MagickGetImageHeight; // https://imagemagick.org/api/magick-image.php#MagickGetImageHeight

const MagickReadImage = c.MagickReadImage; // https://imagemagick.org/api/magick-image.php#MagickReadImage

const MagickExportImagePixels = c.MagickExportImagePixels; // https://imagemagick.org/api/magick-image.php#MagickExportImagePixels

pub fn init() !MagickWand {
    MagickWandGenesis();

    var self = MagickWand{};
    if (NewMagickWand()) |wand| {
        self.wand = wand;
    } else {
        return error.MagickWandInit;
    }

    return self;
}

pub fn deinit(self: *MagickWand) void {
    _ = DestroyMagickWand(self.wand);
    MagickWandTerminus();
}

pub fn setImageFormat(self: *MagickWand, format: [:0]const u8) !void {
    log.debug("{s}('{s}') ", .{ @src().fn_name, format });

    if (MagickSetImageFormat(self.wand, format) == MagickFalse)
        self.logException() catch return error.SetImageFormatError;
}

pub fn getImageWidth(self: *MagickWand) usize {
    log.debug("{s}()", .{@src().fn_name});

    return MagickGetImageWidth(self.wand);
}

pub fn getImageHeight(self: *MagickWand) usize {
    log.debug("{s}()", .{@src().fn_name});

    return MagickGetImageHeight(self.wand);
}

pub fn readImage(self: *MagickWand, name: [:0]const u8) !void {
    log.debug("{s}('{s}') ", .{ @src().fn_name, name });

    if (MagickReadImage(self.wand, name) == MagickFalse)
        self.logException() catch return error.ReadImageError;
}

pub fn exportImagePixels(
    self: *MagickWand,
    allocator: Allocator,
    x: isize,
    y: isize,
    width: usize,
    height: usize,
    map: [:0]const u8,
) ![]u8 {
    log.debug("{s}({d}, {d}, {d}, {d}, '{s}') ", .{ @src().fn_name, x, y, width, height, map });

    const pixels = try allocator.alloc(u8, width * height * map.len);
    errdefer allocator.free(pixels);

    // NOTE: `CharPixel` is set because the function returns `u8`
    if (MagickExportImagePixels(self.wand, 0, 0, width, height, map, c.CharPixel, pixels.ptr) == MagickFalse)
        self.logException() catch return error.ExportImagePixelsError;

    return pixels;
}

fn logException(self: *MagickWand) !void {
    var severity: c_uint = undefined;
    const description = MagickGetException(self.wand, &severity);
    defer _ = MagickRelinquishMemory(description);

    if (isWarning(severity)) {
        log.warn("{s}", .{description});
    } else {
        log.err("{s}", .{description});
    }
    return error.Exception;
}

// https://imagemagick.org/script/exception.php
// Warning:     something unusual occurred     (most likely the results are still usable)
// Error:       could not complete as expected (any results are unreliable)
// Fatal Error: could not complete             (no results are available)
// https://github.com/ImageMagick/ImageMagick/blob/1ad038c7ce265a117c2f3fb70cb51561bd7c176a/MagickCore/exception.h#L27
fn isWarning(exception: c.ExceptionType) bool {
    return exception >= c.WarningException or exception < c.ErrorException;
}
