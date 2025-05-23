const std = @import("std");
const fs = std.fs;
const sort = std.sort;
const mem = std.mem;
const Dir = fs.Dir;
const posix = std.posix;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const zgui = @import("zgui");
const gl = @import("zopengl").bindings;

const App = @import("App.zig");
const Entry = @import("Entry.zig");
const Magic = @import("Magic.zig");

const Browser = @This();

const log = std.log.scoped(.Browser);
pub const window_title = "Browser";

allocator: Allocator = undefined,
working_dir: Dir = undefined,
magic: Magic = undefined,
entries: ArrayList(Entry) = undefined,
entry_selected: ?*Entry = null,
cursor: ?usize = null,
cursor_moved: bool = false,

pub fn init(allocator: Allocator, sub_path: [:0]const u8) !Browser {
    log.debug("{s}('{s}') ", .{ @src().fn_name, sub_path });

    var self = Browser{};
    self.allocator = allocator;

    self.working_dir = try fs.cwd().openDir(sub_path, .{ .iterate = true });
    self.magic = try Magic.init();

    self.entries = ArrayList(Entry).init(allocator);
    try self.collectEntries();

    return self;
}

pub fn deinit(self: *Browser) void {
    log.debug("{s}()", .{@src().fn_name});

    self.magic.deinit();
    self.clearEntries();
    self.entries.deinit();
}

pub fn changeDir(self: *Browser, sub_path: [*:0]const u8) !void {
    log.info("{s}('{s}')", .{ @src().fn_name, sub_path });

    var buffer: [2][fs.max_path_bytes]u8 = undefined;
    const old_path = try self.working_dir.realpath(".", &buffer[0]);
    var it = try fs.path.componentIterator(old_path);
    const prev_dir = it.last();

    var old_dir = self.working_dir;
    self.working_dir = self.working_dir.openDirZ(sub_path, .{ .iterate = true }) catch |err| {
        log.err("{s}('{s}') {!}", .{ @src().fn_name, sub_path, err });
        return;
    };
    old_dir.close();

    const new_path = try self.working_dir.realpath(".", &buffer[1]);
    try posix.chdir(new_path);

    self.clearEntries();
    try self.collectEntries();

    self.cursor = null;
    if (prev_dir) |last| {
        for (0.., self.entries.items) |i, entry| {
            if (mem.eql(u8, entry.name, last.name)) {
                self.cursor = i;
            }
        }
    }
    self.cursor_moved = true;
}

pub fn collectEntries(self: *Browser) !void {
    log.debug("{s}()", .{@src().fn_name});

    var iterator = self.working_dir.iterate();
    while (try iterator.next()) |entry| {
        var new_entry = try Entry.init(self.allocator, entry);
        // getMimeType() depends on the null terminated name
        new_entry.mime_type = try self.magic.getMimeType(new_entry.name);
        try self.entries.append(new_entry);
    }

    const parent_dir = try Entry.init(self.allocator, .{ .kind = .directory, .name = ".." });
    try self.entries.insert(0, parent_dir);

    sort.pdq(Entry, self.entries.items, Order.ascending, sortDirAlpha);
}

const Order = enum {
    ascending,
    descending,
};

// sort alphabetically, directories first in ascending order
fn sortDirAlpha(order: Order, a: Entry, b: Entry) bool {
    const a_is_dir = a.directory();
    const b_is_dir = b.directory();

    if (a_is_dir and !b_is_dir) return true;
    if (!a_is_dir and b_is_dir) return false;

    const less_than = mem.lessThan(u8, a.name, b.name);
    return switch (order) {
        .ascending => less_than,
        .descending => !less_than,
    };
}

pub fn clearEntries(self: *Browser) void {
    log.debug("{s}()", .{@src().fn_name});

    for (self.entries.items) |*entry| {
        entry.deinit(self.allocator);
    }
    self.entries.clearRetainingCapacity();
}

pub fn selectEntry(self: *Browser, entry: Entry, app: *App) !void {
    if (entry.directory()) {
        app.viewer.unloadMedia();
        try self.changeDir(entry.name);
    } else {
        switch (entry.mime_type) {
            .image => {
                app.viewer.unloadMedia();
                try app.viewer.loadMedia(entry.name);
            },
            else => {},
        }
    }
}

fn entryAtCursor(self: *Browser) ?*Entry {
    if (self.cursor) |cursor| {
        const entry = &self.entries.items[cursor];
        if (!entry.directory()) {
            return entry;
        }
    }
    return null;
}

pub fn update(self: *Browser, app: *App) !void {
    if (self.entry_selected) |entry| {
        try self.selectEntry(entry.*, app);
        self.entry_selected = null;
    }

    const entries_len = self.entries.items.len - 1;
    if (zgui.isKeyPressed(.up_arrow, true)) {
        self.cursor =
            if (self.cursor) |*selected|
                (selected.* + entries_len) % (entries_len + 1)
            else
                entries_len;
        self.cursor_moved = true;
        self.entry_selected = self.entryAtCursor();
    }
    if (zgui.isKeyPressed(.down_arrow, true)) {
        self.cursor =
            if (self.cursor) |*selected|
                (selected.* + 1) % (entries_len + 1)
            else
                0;
        self.cursor_moved = true;
        self.entry_selected = self.entryAtCursor();
    }
    if (zgui.isKeyPressed(.enter, true)) {
        if (self.cursor) |cursor| {
            try self.selectEntry(self.entries.items[cursor], app);
        }
    }
    if (zgui.isKeyPressed(.back_space, true)) {
        app.viewer.unloadMedia();
        try self.changeDir("..");
    }
}

pub fn draw(self: *Browser, app: *App) !void {
    if (zgui.begin(window_title, .{ .flags = .{} })) {
        for (0.., self.entries.items) |i, *entry| {
            if (entry.directory()) {
                zgui.pushFont(app.font_bold);
            } else {
                zgui.pushFont(app.font_regular);
            }

            if (entry.mime_type == .audio) {
                zgui.pushStyleColor1u(.{
                    .idx = .text,
                    .c = 0xFF39c5cf,
                });
            } else if (entry.mime_type == .video) {
                zgui.pushStyleColor1u(.{
                    .idx = .text,
                    .c = 0xFFbe8fff,
                });
            } else if (entry.mime_type == .image) {
                zgui.pushStyleColor1u(.{
                    .idx = .text,
                    .c = 0xFF3fb950,
                });
            } else {
                zgui.pushStyleColor1u(.{
                    .idx = .text,
                    .c = 0xFFf0f6fc,
                });
            }

            if (self.cursor_moved) {
                if (self.cursor) |cursor| {
                    if (cursor == i) {
                        zgui.setScrollHereY(.{});
                        self.cursor_moved = false;
                    }
                }
            }

            if (zgui.selectable(entry.name, .{
                .selected = if (self.cursor) |cursor| cursor == i else false,
                .flags = .{ .span_all_columns = true, .allow_double_click = true },
            })) {
                self.cursor = i;
                self.entry_selected = entry;
            }

            zgui.popFont();
            zgui.popStyleColor(.{ .count = 1 });
        }
    }
    zgui.end();
}
