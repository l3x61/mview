const GUI = @This();

const std = @import("std");
const log = std.log.scoped(.GUI);
const fs = std.fs;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const config = @import("config");

const zgui = @import("zgui");
const zglfw = @import("zglfw");
const Window = zglfw.Window;

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const Browser = @import("Browser.zig");
const Viewer = @import("Viewer.zig");

const window_title = config.exe_name;
const window_width = 800;
const window_height = 450;
const font_size = 16;
const gl_major = 4;
const gl_minor = 0;

allocator: Allocator = undefined,
demo: bool = false,
exit: bool = false,
window: *Window = undefined,
ini_file_path: ArrayList(u8) = undefined,
browser: Browser = undefined,
viewer: Viewer = undefined,
font_regular: zgui.Font = undefined,
font_bold: zgui.Font = undefined,
first: bool = true,

pub fn init(allocator: Allocator) !GUI {
    log.debug("{s}()", .{@src().fn_name});

    var self = GUI{};
    self.allocator = allocator;
    try zglfw.init();

    zglfw.windowHint(.context_version_major, gl_major);
    zglfw.windowHint(.context_version_minor, gl_minor);
    zglfw.windowHint(.opengl_profile, .opengl_core_profile);
    zglfw.windowHint(.opengl_forward_compat, true);
    zglfw.windowHint(.client_api, .opengl_api);
    zglfw.windowHint(.doublebuffer, true);

    self.window = try zglfw.Window.create(window_width, window_height, window_title, null);
    self.window.setSizeLimits(-1, -1, -1, -1);

    zglfw.makeContextCurrent(self.window);
    zglfw.swapInterval(1);

    try zopengl.loadCoreProfile(zglfw.getProcAddress, gl_major, gl_minor);

    zgui.init(allocator);

    const appdata_path = try std.fs.getAppDataDir(allocator, config.exe_name);
    try fs.cwd().makePath(appdata_path);

    log.info("{s}() config.ini location set to {s}", .{ @src().fn_name, appdata_path });
    self.ini_file_path = ArrayList(u8).fromOwnedSlice(allocator, appdata_path);
    try self.ini_file_path.appendSlice("/config.ini");
    try self.ini_file_path.append(0);
    const ini_cstr: [:0]u8 = self.ini_file_path.items[0 .. self.ini_file_path.items.len - 1 :0];
    zgui.io.setIniFilename(ini_cstr.ptr);

    const scale = scale: {
        const scale = self.window.getContentScale();
        break :scale @max(scale[0], scale[1]);
    };

    zgui.getStyle().scaleAllSizes(scale);

    self.font_regular = zgui.io.addFontFromMemory(
        @embedFile("fonts/JetBrainsMonoNL-Regular.ttf"),
        font_size * scale,
    );

    self.font_bold = zgui.io.addFontFromMemory(
        @embedFile("fonts/JetBrainsMonoNL-ExtraBold.ttf"),
        font_size * scale,
    );
    zgui.io.setConfigFlags(.{ .dock_enable = true });
    zgui.backend.init(self.window);

    self.browser = try Browser.init(allocator, ".");
    self.viewer = try Viewer.init(allocator);

    return self;
}

pub fn deinit(self: *GUI) void {
    log.debug("{s}()", .{@src().fn_name});

    zgui.backend.deinit();
    zgui.deinit();
    self.ini_file_path.deinit();
    self.window.destroy();
    zglfw.terminate();

    self.browser.deinit();
}

pub fn run(self: *GUI) !void {
    log.debug("{s}()", .{@src().fn_name});

    while (!self.exit) {
        try self.update();
        try self.draw();
    }
}

fn update(self: *GUI) !void {
    zglfw.pollEvents();

    if (self.window.shouldClose() or zgui.isKeyPressed(.escape, false)) {
        self.exit = true;
    }

    if (zgui.isKeyPressed(.d, false)) {
        self.demo = !self.demo;
    }

    try self.browser.update();
    try self.viewer.update();
}

fn draw(self: *GUI) !void {
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0, 0, 0, 0 });

    const fb_size = self.window.getFramebufferSize();
    zgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    const viewport = zgui.getMainViewport();
    const dockspace = zgui.DockSpaceOverViewport(0, viewport, .{ .no_undocking = true, .auto_hide_tab_bar = true });

    if (self.first) {
        log.info("{s}() init dockspace", .{@src().fn_name});

        zgui.dockBuilderRemoveNode(dockspace);
        _ = zgui.dockBuilderAddNode(dockspace, .{ .dock_space = true, .no_undocking = true });
        zgui.dockBuilderSetNodeSize(dockspace, viewport.getSize());

        var node_left: u32 = undefined;
        var node_right: u32 = undefined;
        _ = zgui.dockBuilderSplitNode(dockspace, .left, 0.3333, &node_left, &node_right);

        zgui.dockBuilderDockWindow(Browser.window_title, node_left);
        zgui.dockBuilderDockWindow(Viewer.window_title, node_right);

        zgui.dockBuilderFinish(dockspace);
        self.first = false;
    }

    try self.browser.draw(self);
    try self.viewer.draw(self);

    if (self.demo) {
        zgui.showDemoWindow(null);
    }

    self.render();
}

fn render(self: *GUI) void {
    zgui.backend.draw();
    self.window.swapBuffers();
}
