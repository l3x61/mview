const Browser = @This();

const std = @import("std");
const log = std.log.scoped(.Browser);
const fs = std.fs;
const sort = std.sort;
const mem = std.mem;
const Dir = fs.Dir;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const zgui = @import("zgui");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const window_title = "Browser";

const Entry = @import("Entry.zig");
const GUI = @import("GUI.zig");

allocator: Allocator = undefined,
dir: Dir = undefined,
entries: ArrayList(Entry) = undefined,
selected_entry: ?*Entry = null,
cursor: ?usize = null,
cursor_moved: bool = false,

pub fn init(allocator: Allocator, sub_path: [:0]const u8) !Browser {
    log.debug("{s}('{s}') ", .{ @src().fn_name, sub_path });

    var self = Browser{};
    self.allocator = allocator;

    self.dir = try fs.cwd().openDir(sub_path, .{ .iterate = true });

    self.entries = ArrayList(Entry).init(allocator);
    try self.collectEntries();

    return self;
}

pub fn deinit(self: *Browser) void {
    log.debug("{s}()", .{@src().fn_name});

    self.clearEntries();
    self.entries.deinit();
}

pub fn changeDir(self: *Browser, sub_path: [*:0]const u8) !void {
    log.info("{s}('{s}')", .{ @src().fn_name, sub_path });

    var buffer: [fs.max_path_bytes]u8 = undefined;
    const path = try self.dir.realpath(".", &buffer);
    var iterator = try fs.path.componentIterator(path);
    const last_path_component = iterator.last();

    var old_dir = self.dir;
    self.dir = self.dir.openDirZ(sub_path, .{ .iterate = true }) catch |err| {
        log.err("{s}('{s}') {!}", .{ @src().fn_name, sub_path, err });
        return;
    };
    old_dir.close();

    self.clearEntries();
    try self.collectEntries();

    self.cursor = null;
    if (last_path_component) |last| {
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

    var iterator = self.dir.iterate();
    while (try iterator.next()) |entry| {
        const new_entry = try Entry.init(self.allocator, entry);
        try self.entries.append(new_entry);
    }

    const parent_dir = try Entry.init(self.allocator, .{ .kind = .directory, .name = ".." });
    try self.entries.insert(0, parent_dir);

    sort.pdq(Entry, self.entries.items, {}, entryLessThan);
}

fn entryLessThan(_: void, ea: Entry, eb: Entry) bool {
    const ea_is_dir = ea.directory();
    const eb_is_dir = eb.directory();

    if (ea_is_dir and !eb_is_dir) return true;
    if (!ea_is_dir and eb_is_dir) return false;

    return std.mem.lessThan(u8, ea.name, eb.name);
}

pub fn clearEntries(self: *Browser) void {
    log.debug("{s}()", .{@src().fn_name});

    for (self.entries.items) |*entry| {
        entry.deinit(self.allocator);
    }
    self.entries.clearRetainingCapacity();
}

pub fn selectEntry(self: *Browser, entry: Entry) !void {
    if (entry.directory()) {
        try self.changeDir(entry.name);
    } else {
        log.info("{s}() {s} selected", .{ @src().fn_name, @tagName(entry.kind) });
    }
}

pub fn update(self: *Browser) !void {
    if (self.selected_entry) |entry| {
        try self.selectEntry(entry.*);
        self.selected_entry = null;
    }

    const entries_len = self.entries.items.len - 1;
    if (zgui.isKeyPressed(.up_arrow, true)) {
        self.cursor =
            if (self.cursor) |*selected|
                (selected.* + entries_len) % (entries_len + 1)
            else
                entries_len;
        self.cursor_moved = true;
    }
    if (zgui.isKeyPressed(.down_arrow, true)) {
        self.cursor =
            if (self.cursor) |*selected|
                (selected.* + 1) % (entries_len + 1)
            else
                0;
        self.cursor_moved = true;
    }
    if (zgui.isKeyPressed(.enter, true)) {
        if (self.cursor) |cursor| {
            try self.selectEntry(self.entries.items[cursor]);
        }
    }
    if (zgui.isKeyPressed(.back_space, true)) {
        try self.changeDir("..");
    }
}

pub fn draw(self: *Browser, gui: *GUI) !void {
    if (zgui.begin(window_title, .{ .flags = .{} })) {
        for (0.., self.entries.items) |i, *entry| {
            const is_directory = entry.directory();
            if (is_directory) zgui.pushFont(gui.font_bold);

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
                if (zgui.isItemClicked(.left)) {
                    self.selected_entry = entry;
                }
            }

            if (is_directory) zgui.popFont();
        }
    }
    zgui.end();
}
