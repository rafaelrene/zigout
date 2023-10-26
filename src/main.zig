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

    pub fn update_position(self: *Paddle, x: i32) void {
        if (x > WIDTH) {
            self.x = WIDTH - self.width;
        }

        if (x < 0) {
            self.x = 0;
        }

        self.x += x;

        print("Stuff", .{});
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

fn handle_paddle_events(event: *c.SDL_Event, paddle: *Paddle) void {
    _ = switch (event.type) {
        c.SDLK_LEFT => paddle.update_position(-1),
        c.SDL_SCANCODE_A => paddle.update_position(-1),
        else => null,
    };
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

        var paddle = Paddle{};

        handle_paddle_events(&event, &paddle);

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderFillRect(renderer, &paddle.to_rect());

        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(1000 / 60);
    }
}
