// notcurses.zig - notcurses wrapper for Zig

// HINT: Add these lines to build.zig after `exe.install();`:
// exe.addIncludeDir("/usr/include");
// exe.linkLibC();
// exe.linkSystemLibrary("notcurses-core");

const n = @cImport({
    @cInclude("notcurses/notcurses.h");
});

pub const FILE = n.FILE;
pub const C_NULL = @intToPtr([*c]const u8, 0);
pub fn stdout() *n.FILE {
    return n.stdout;
}

// pub const Cell = n.nccell;
// pub const Plane = n.ncplane;
// pub const Notcurses = n.notcurses;
pub const Options = n.notcurses_options;
pub const Input = n.ncinput;

pub const Error = error {
    Failure,
};

pub const LogLevel = enum {
    silent,
    panic,
    fatal,
    error_,
    warning,
    info,
    verbose,
    debug,
    trace,
};

// bits for notcurses_options->flags
pub const Option = enum(u64) {
    inhibit_setlocale   = 0x0001,
    no_clear_bitmaps    = 0x0002,
    no_winch_sighandler = 0x0004,
    no_quit_sighandlers = 0x0008,
    preserve_cursor     = 0x0010,
    suppress_banners    = 0x0020,
    no_alternate_screen = 0x0040,
    no_font_changes     = 0x0080,
    drain_input         = 0x0100,
};

// ncinput->evtype
pub const InputEventType = enum {
    UNKNOWN,
    PRESS,
    REPEAT,
    RELEASE,
};

// `return Options { ... }` is avoided here,
// because the struct contains undocumented fields.
pub fn get_default_option() Options {
    var result: Options = undefined;
    result.termtype = C_NULL; // NULL == Use envvar TERM
    result.loglevel = @enumToInt(LogLevel.silent);
    result.margin_t = 0;
    result.margin_r = 0;
    result.margin_b = 0;
    result.margin_l = 0;
    result.flags = 0; // `Option.suppress_banners` to suppress stats
    return result;
}

pub fn get_default_input() Input {
    var result: Input = undefined;
    result.id = 0;
    result.y = 0;
    result.x = 0;
    result.alt = false;
    result.shift = false;
    result.ctrl = false;
    result.evtype = @enumToInt(InputEventType.UNKNOWN);
    result.ypx = 0;
    result.xpx = 0;
    return result;
}

pub fn core_init(options: *Options, fp: *FILE) !Notcurses {
    var nc = n.notcurses_core_init(options, fp)
        orelse return Error.Failure;
    return Notcurses {
        .nc = nc,
    };
}

// Wrapper for struct notcurses.
pub const Notcurses = struct {
    nc: *n.notcurses,

    pub fn render(self: *const Notcurses) !void {
        if (n.notcurses_render(self.nc) == 0) {
            return;
        }
        return Error.Failure;
    }

    pub fn stop(self: *const Notcurses) !void {
        if (n.notcurses_stop(self.nc) == 0) {
            return;
        }
        return Error.Failure;
    }

    pub fn stdplane(self: *const Notcurses) Plane {
        var plane: Plane = undefined;
        plane.p = n.notcurses_stdplane(self.nc) orelse unreachable;
        return plane;
    }

    pub fn get_blocking(self: *const Notcurses, input: *Input) u32 {
        return n.notcurses_getc_blocking(self.nc, input);
    }
};

// Wrapper for struct ncplane.
pub const Plane = struct {
    p: *n.ncplane,

    pub fn cursor_move_yx(self: *const Plane, y: isize, x: isize) !void {
        const result = n.ncplane_cursor_move_yx(
            self.p, @intCast(c_int, y), @intCast(c_int, x));
        if (result == -1) {
            return Error.Failure;
        }
    }

    pub fn putstr(self: *const Plane, str: [*]const u8) isize {
        const result = n.ncplane_putstr(self.p, str);
        return @intCast(isize, result);
    }
};

// eof
