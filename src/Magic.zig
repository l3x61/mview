// https://datatracker.ietf.org/doc/bcp13/ MIME related docs
// https://www.iana.org/assignments/media-types/media-types.xhtml official MIME registry

const std = @import("std");
const mem = std.mem;
const startsWith = std.mem.startsWith;

const Magic = @This();
const log = std.log.scoped(.Magic);

const c = @cImport({
    @cInclude("magic.h");
});

// https://datatracker.ietf.org/doc/rfc9694/ MIME types
pub const MimeType = enum {
    application,
    audio,
    example,
    font,
    haptics,
    image,
    message,
    model,
    multipart,
    text,
    video,
    // unofficial
    chemical,
    inode,
    package,
    x_content,
    x_office,
    //
    other,
};

pub const Mime = struct {
    mime_type: MimeType,
    mime_subtype: MimeSubType,
    mime_string: [:0]const u8,
};

pub const MimeSubType = enum {
    // TODO
};

cookie: *c.magic_set = undefined,

pub fn init() !Magic {
    log.debug("{s}()", .{@src().fn_name});
    var self = Magic{};

    // init magic
    if (c.magic_open(c.MAGIC_MIME_TYPE)) |cookie| {
        self.cookie = cookie;
    } else {
        self.logError();
        return error.MagicOpenError;
    }

    // load default database
    if (c.magic_load(self.cookie, null) == -1) {
        self.logError();
        return error.MagicLoadError;
    }

    return self;
}

/// Caller does **not** own the returned pointer.
pub fn getMimeString(self: *Magic, filename: [:0]const u8) ![]const u8 {
    log.debug("{s}('{s}')", .{ @src().fn_name, filename });

    if (c.magic_file(self.cookie, filename)) |mime| {
        return mem.span(mime[0..]);
    }

    self.logError();
    return error.MagicFileError;
}

pub fn getMimeType(self: *Magic, filename: [:0]const u8) !MimeType {
    //log.debug("{s}('{s}')", .{ @src().fn_name, filename });

    if (c.magic_file(self.cookie, filename)) |cstr| {
        const mime = mem.span(cstr[0.. :0]);

        if (startsWith(u8, mime, "video/")) {
            return MimeType.video;
        } else if (startsWith(u8, mime, "audio/")) {
            return MimeType.audio;
        } else if (startsWith(u8, mime, "image/")) {
            return MimeType.image;
        } else {
            return MimeType.other;
        }
    }

    self.logError();
    return error.MagicFileError;
}

pub fn deinit(self: *Magic) void {
    c.magic_close(self.cookie);
}

pub fn logError(self: Magic) void {
    log.err("{s}() {s}", .{ @src().fn_name, c.magic_error(self.cookie) });
}
