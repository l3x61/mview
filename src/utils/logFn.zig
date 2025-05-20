const std = @import("std");

const Ansi = @import("Ansi.zig");

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_prefix = switch (level) {
        .debug => Ansi.Dim,
        .info => Ansi.Cyan,
        .warn => Ansi.Yellow,
        .err => Ansi.Red,
    };
    const scope_prefix = @tagName(scope);
    const prefix = level_prefix ++ scope_prefix ++ ".";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n" ++ Ansi.Reset, args) catch return;
}
