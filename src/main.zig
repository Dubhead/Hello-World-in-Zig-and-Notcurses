// main.zig - notcurses test

const std = @import("std");

const notcurses = @import("notcurses.zig");

pub fn main() anyerror!void {
    var ncopt = notcurses.get_default_option();
    ncopt.flags |= @enumToInt(notcurses.Option.suppress_banners);
    const nc = try notcurses.core_init(&ncopt, notcurses.stdout());
    const plane = nc.stdplane();

    try plane.cursor_move_yx(2, 2);
    _ = plane.putstr("Hello world");
    try plane.cursor_move_yx(4, 2);
    _ = plane.putstr("Hit any key to exit.");
    try nc.render();

    var input = notcurses.get_default_input();
    _ = nc.get_blocking(&input);

    // std.time.sleep(2_000_000_000);
    try nc.stop();
}

// eof
