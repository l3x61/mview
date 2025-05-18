const GUI = @This();

const std = @import("std");
const log = std.log.scoped(.GUI);

const zgui = @import("zgui");
const zglfw = @import("zglfw");
const Window = zglfw.Window;

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const window_title = "vimv";
const window_width = 800;
const window_height = 450;
const font_size = 16;
const gl_major = 4;
const gl_minor = 0;

demo: bool = false,
exit: bool = false,
window: *Window = undefined,

pub fn init(allocator: std.mem.Allocator) !GUI {
    log.debug("{s}() entry", .{@src().fn_name});
    defer log.debug("{s}() exit", .{@src().fn_name});

    var self = GUI{};
    try zglfw.init();

    zglfw.windowHint(.context_version_major, gl_major);
    zglfw.windowHint(.context_version_minor, gl_minor);
    zglfw.windowHint(.opengl_profile, .opengl_core_profile);
    zglfw.windowHint(.opengl_forward_compat, true);
    zglfw.windowHint(.client_api, .opengl_api);
    zglfw.windowHint(.doublebuffer, true);

    log.info("{s}() create window", .{@src().fn_name});
    self.window = try zglfw.Window.create(window_width, window_height, window_title, null);
    self.window.setSizeLimits(-1, -1, -1, -1);

    zglfw.makeContextCurrent(self.window);
    zglfw.swapInterval(1);

    log.info("{s}() load opengl", .{@src().fn_name});
    try zopengl.loadCoreProfile(zglfw.getProcAddress, gl_major, gl_minor);

    log.info("{s}() init dear imgui", .{@src().fn_name});
    zgui.init(allocator);

    const scale = scale: {
        const scale = self.window.getContentScale();
        break :scale @max(scale[0], scale[1]);
    };

    zgui.getStyle().scaleAllSizes(scale);

    _ = zgui.io.addFontFromMemory(
        @embedFile("fonts/GitLabMono.ttf"),
        font_size * scale,
    );

    zgui.backend.init(self.window);

    return self;
}

pub fn deinit(self: *GUI) void {
    log.debug("{s}() entry", .{@src().fn_name});
    defer log.debug("{s}() exit", .{@src().fn_name});

    zgui.backend.deinit();
    zgui.deinit();
    self.window.destroy();
    zglfw.terminate();
}

pub fn run(self: *GUI) !void {
    log.debug("{s}() entry", .{@src().fn_name});
    defer log.debug("{s}() exit", .{@src().fn_name});

    while (!self.exit) {
        try self.update();
        try self.draw();
    }
}

fn update(self: *GUI) !void {
    zglfw.pollEvents();

    if (self.window.shouldClose() or self.window.getKey(.escape) == .press) {
        self.exit = true;
    }

    if (self.window.getKey(.d) == .press) {
        self.demo = !self.demo;
    }
}

fn draw(self: *GUI) !void {
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0, 0, 0, 0 });

    const fb_size = self.window.getFramebufferSize();
    zgui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

    if (self.demo) {
        zgui.showDemoWindow(null);
    }

    self.render();
}

fn render(self: *GUI) void {
    zgui.backend.draw();
    self.window.swapBuffers();
}
