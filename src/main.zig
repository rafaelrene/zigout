const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");

const print = std.debug.print;

const WIDTH: u32 = 640;
const HEIGHT: u32 = 480;

pub fn main() !void {
    const init = c.SDL_Init(c.SDL_INIT_VIDEO);

    if (init < 0) {
        print("SDL Init failed: {s}", .{c.SDL_GetError()});
    }

    const window = c.SDL_CreateWindow("Zigout", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, c.SDL_WINDOW_SHOWN);
    defer c.SDL_DestroyWindow(window);

    if (window == null) {
        print("SLD Create window failed: {s}", .{c.SDL_GetError()});
    }

    _ = c.SDL_UpdateWindowSurface(window);
    c.SDL_PumpEvents();
    c.SDL_Delay(5000);

    print("Hello {s}! RES: {} / {}\n", .{ "World", WIDTH, HEIGHT });
    c.SDL_Quit();
}
