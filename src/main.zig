const C = @import("constants.zig");
const E = @import("errors.zig");
const H = @import("helpers.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");

const print = std.debug.print;

fn is_quit(event: *c.SDL_Event) bool {
    return switch (event.type) {
        c.SDL_QUIT => true,
        c.SDL_KEYDOWN => event.key.keysym.sym == c.SDLK_q,
        else => false,
    };
}

fn handle_paddle_keyboard_events(keyboard: [*c]const u8, paddle: *H.Paddle) void {
    if (keyboard[c.SDL_SCANCODE_A] != 0) {
        paddle.update_position(-paddle.speed);
        return;
    }

    if (keyboard[c.SDL_SCANCODE_D] != 0) {
        paddle.update_position(paddle.speed);
        return;
    }
}

pub fn main() !void {
    const init = c.SDL_Init(c.SDL_INIT_VIDEO);
    defer c.SDL_Quit();

    if (init < 0) {
        print("SDL Init failed: {s}", .{c.SDL_GetError()});
        return E.SDLError.FailedInit;
    }

    const window = c.SDL_CreateWindow("Zigout", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, C.WIDTH, C.HEIGHT, c.SDL_WINDOW_SHOWN);
    defer c.SDL_DestroyWindow(window);

    if (window == null) {
        print("SDL Create window failed: {s}", .{c.SDL_GetError()});
        return E.SDLError.FailedCreatingWindow;
    }

    _ = c.SDL_UpdateWindowSurface(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_SOFTWARE);
    defer c.SDL_DestroyRenderer(renderer);

    c.SDL_PumpEvents();

    const keyboard = c.SDL_GetKeyboardState(null);

    var event: c.SDL_Event = undefined;

    var paddle = H.Paddle.create(C.WIDTH / 2 - 100, C.HEIGHT - 30);
    var ball = H.Ball.create(C.WIDTH / 2 - 5, C.HEIGHT / 2 - 5, 5);

    while (true) {
        _ = c.SDL_PollEvent(&event);

        if (is_quit(&event)) {
            break;
        }

        handle_paddle_keyboard_events(keyboard, &paddle);

        _ = ball.handle_collision(&paddle) catch |err| switch (err) {
            E.GameError.BallOutOfBounds => break,
        };

        ball.update_position();

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        // NOTE: Draw paddle
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderFillRect(renderer, &paddle.position.to_rect());

        // NOTE: Draw ball
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        _ = c.SDL_RenderFillRect(renderer, &ball.position.to_rect());

        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(1000 / 60);
    }
}
