const std = @import("std");
const Allocator = std.mem.Allocator;

const Image = @import("Image.zig");
const gl = @import("zopengl").bindings;

const Texture = @This();
const log = std.log.scoped(.Texture);

id: gl.Uint = undefined,
width: usize = undefined,
height: usize = undefined,

pub fn initFromImage(image: Image) !Texture {
    var self = Texture{};
    self.width = image.width;
    self.height = image.height;

    gl.genTextures(1, &self.id);
    gl.bindTexture(gl.TEXTURE_2D, self.id);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @intCast(image.width), @intCast(image.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, image.pixels.ptr);

    // TODO: check opengl calls for errors

    return self;
}

pub fn deinit(self: *Texture) void {
    gl.deleteTextures(1, &self.id);
}
