const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");

const print = std.debug.print;

const WIDTH: u32 = 1280;
const HEIGHT: u32 = 800;

const SDLError = error{
    FailedInit,
    FailedCreatingWindow,
    FailedGettingEvent,
    FailedDraw,
    FailedScreenUpdate,
};

const Ball = struct {
    width: i32,
    height: i32,
    x: i32,
    y: i32,
};

const Paddle = struct {
    width: i32 = 50,
    height: i32 = 10,
    x: i32 = WIDTH / 2 - 25,
    y: i32 = HEIGHT - 20,

    pub fn is_colliding(self: Paddle, ball: Ball) bool {
        const is_x_overlapping = self.x < ball.x and self.x + self.width > ball.x;
        const is_y_overlapping = self.y < ball.y and self.y + self.height > ball.y;

        return is_x_overlapping and is_y_overlapping;
    }
};

const Brick = struct {
    width: i32,
    height: i32,
    x: i32,
    y: i32,

    pub fn is_colliding(self: Brick, ball: Ball) bool {
        const is_x_overlapping = self.x < ball.x and self.x + self.width > ball.x;
        const is_y_overlapping = self.y < ball.y and self.y + self.height > ball.y;

        return is_x_overlapping and is_y_overlapping;
    }
};

fn is_quit(event: *c.SDL_Event) bool {
    return switch (event.type) {
        c.SDL_QUIT => true,
        c.SDL_KEYDOWN => event.key.keysym.sym == c.SDLK_q,
        else => false,
    };
}

fn handle_event_loop() !void {
    var event: c.SDL_Event = undefined;

    while (true) {
        if (c.SDL_WaitEvent(&event) == 0) {
            print(
                "Getting next event failed: {s}\n",
                .{c.SDL_GetError()},
            );

            return SDLError.FailedGettingEvent;
        }

        if (is_quit(&event)) {
            break;
        }
    }
}

fn draw_paddle(renderer: *c.SDL_Renderer) Paddle {
    const paddle = Paddle{};
    const rect = c.SDL_Rect{ .w = paddle.width, .h = paddle.height, .x = paddle.x, .y = paddle.y };

    _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    _ = c.SDL_RenderFillRect(renderer, rect);

    return paddle;
}

pub fn main() !void {
    const init = c.SDL_Init(c.SDL_INIT_VIDEO);
    errdefer c.SDL_Quit();

    if (init < 0) {
        print("SDL Init failed: {s}", .{c.SDL_GetError()});
    }

    const window = c.SDL_CreateWindow("Zigout", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, c.SDL_WINDOW_SHOWN);
    defer c.SDL_DestroyWindow(window);

    if (window == null) {
        print("SLD Create window failed: {s}", .{c.SDL_GetError()});
    }

    _ = c.SDL_UpdateWindowSurface(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_SOFTWARE);
    defer c.SDL_DestroyRenderer(renderer);

    c.SDL_PumpEvents();

    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);

    const paddle = Paddle{};
    const rect = c.SDL_Rect{ .w = paddle.width, .h = paddle.height, .x = paddle.x, .y = paddle.y };

    _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    _ = c.SDL_RenderFillRect(renderer, &rect);

    c.SDL_RenderPresent(renderer);

    try handle_event_loop();
}
