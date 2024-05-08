const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");

const print = std.debug.print;

const WIDTH: i32 = 1280;
const HEIGHT: i32 = 800;

const SDLError = error{
    FailedInit,
    FailedCreatingWindow,
    FailedGettingEvent,
};

const Ball = struct {
    radius: i32 = 10,
    x: i32 = WIDTH / 2 + 5,
    y: i32 = HEIGHT / 2 + 5,

    pub fn to_rect(self: Ball) c.SDL_Rect {
        return c.SDL_Rect{ .w = self.radius, .h = self.radius, .x = self.x, .y = self.y };
    }
};

const Paddle = struct {
    width: i32 = 200,
    height: i32 = 20,
    x: i32 = WIDTH / 2 - 50,
    y: i32 = HEIGHT - 30,
    speed: i32 = 20,

    pub fn is_colliding(self: Paddle, ball: Ball) bool {
        const is_x_overlapping = self.x < ball.x and self.x + self.width > ball.x;
        const is_y_overlapping = self.y < ball.y and self.y + self.height > ball.y;

        return is_x_overlapping and is_y_overlapping;
    }

    pub fn update_position(self: *Paddle, delta_x: i32) void {
        if (self.x + self.width + delta_x > WIDTH) {
            self.x = WIDTH - self.width;
            return;
        }

        if (self.x + delta_x < 0) {
            self.x = 0;
            return;
        }

        self.x += delta_x;
    }

    pub fn to_rect(self: Paddle) c.SDL_Rect {
        return c.SDL_Rect{ .w = self.width, .h = self.height, .x = self.x, .y = self.y };
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

fn handle_paddle_keyboard_events(keyboard: [*c]const u8, paddle: *Paddle) void {
    if (keyboard[c.SDL_SCANCODE_A] != 0) {
        paddle.update_position(-paddle.speed);
        print("Paddle after: {any}\n", .{paddle});
        return;
    }

    if (keyboard[c.SDL_SCANCODE_D] != 0) {
        paddle.update_position(paddle.speed);
        print("Paddle after: {any}\n", .{paddle});
        return;
    }
}

pub fn main() !void {
    const init = c.SDL_Init(c.SDL_INIT_VIDEO);
    defer c.SDL_Quit();

    if (init < 0) {
        print("SDL Init failed: {s}", .{c.SDL_GetError()});
        return SDLError.FailedInit;
    }

    const window = c.SDL_CreateWindow("Zigout", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, c.SDL_WINDOW_SHOWN);
    defer c.SDL_DestroyWindow(window);

    if (window == null) {
        print("SLD Create window failed: {s}", .{c.SDL_GetError()});
        return SDLError.FailedCreatingWindow;
    }

    _ = c.SDL_UpdateWindowSurface(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_SOFTWARE);
    defer c.SDL_DestroyRenderer(renderer);

    c.SDL_PumpEvents();

    const keyboard = c.SDL_GetKeyboardState(null);

    var event: c.SDL_Event = undefined;

    var paddle = Paddle{};
    var ball = Ball{};

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

        handle_paddle_keyboard_events(keyboard, &paddle);

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        // NOTE: Draw paddle
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderFillRect(renderer, &paddle.to_rect());

        // NOTE: Draw ball
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        _ = c.SDL_RenderFillRect(renderer, &ball.to_rect());

        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(1000 / 60);
    }
}
