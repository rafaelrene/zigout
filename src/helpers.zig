const C = @import("constants.zig");
const E = @import("errors.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");

const print = std.debug.print;

const Position = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    t: i32,
    r: i32,
    b: i32,
    l: i32,

    pub fn create(x: i32, y: i32, w: i32, h: i32) Position {
        return .{
            .x = x,
            .y = y,
            .w = w,
            .h = h,

            .t = y,
            .r = x + w,
            .b = y + h,
            .l = x,
        };
    }

    pub fn update(self: *Position, x: ?i32, y: ?i32) void {
        if (x != null) {
            self.x = x.?;
        }

        if (y != null) {
            self.y = y.?;
        }

        if (self.x <= 0) {
            self.x = 0;
        }

        if (self.x + self.w >= C.WIDTH) {
            self.x = C.WIDTH - self.w;
        }

        self.t = self.y;
        self.r = self.x + self.w;
        self.b = self.y + self.h;
        self.l = self.x;
    }

    pub fn to_rect(self: *Position) c.SDL_Rect {
        return c.SDL_Rect{ .w = self.w, .h = self.h, .x = self.x, .y = self.y };
    }

    pub fn is_overlapping(self: *Position, other: Position) bool {
        const is_x_overlapping = (self.r >= other.l and self.r <= other.r) or (self.l <= other.r and self.l >= other.l) or (self.r >= other.r and self.l <= other.l);
        const is_y_overlapping = (self.b >= other.t and self.b <= other.b) or (self.t <= other.b and self.t >= other.t) or (self.b >= other.b and self.t <= other.t);

        return is_x_overlapping and is_y_overlapping;
    }
};

pub const Ball = struct {
    position: Position,
    old_position: Position,

    dx: i32,
    dy: i32,

    pub fn create(x: i32, y: i32, speed: i32) Ball {
        const position = Position.create(x, y, 10, 10);
        const old_position = Position.create(x, y, 10, 10);

        return .{ .position = position, .old_position = old_position, .dx = speed, .dy = speed };
    }

    pub fn update_position(self: *Ball) void {
        self.old_position = self.position;

        self.position.update(self.position.x + self.dx, self.position.y + self.dy);
    }

    pub fn handle_collision(self: *Ball, paddle: *Paddle) E.GameError!void {
        var change_dx = false;
        var change_dy = false;

        if (self.position.l <= 0) {
            self.position.update(0, null);
            change_dx = true;
        }

        if (self.position.r >= C.WIDTH) {
            self.position.update(C.WIDTH - self.position.w, null);
            change_dx = true;
        }

        if (self.position.t <= 0) {
            self.position.update(null, 0);
            change_dy = true;
        }

        if (self.position.b >= C.HEIGHT) {
            print("GAME OVER!", .{});
            return E.GameError.BallOutOfBounds;
        }

        const is_overlapping = self.position.is_overlapping(paddle.position);

        if (is_overlapping == false) {
            if (change_dx) {
                self.dx *= -1;
            }

            if (change_dy) {
                self.dy *= -1;
            }

            return;
        }

        const is_from_left = self.position.r >= paddle.position.l and self.old_position.r <= paddle.old_position.l;
        if (is_from_left) {
            self.position.update(paddle.position.l, null);
            change_dx = true;
        }

        const is_from_right = self.position.l <= paddle.position.r and self.old_position.l >= paddle.old_position.r;
        if (is_from_right) {
            self.position.update(paddle.position.r, null);
            change_dx = true;
        }

        const is_from_top = self.position.b >= paddle.position.t and self.old_position.b <= paddle.old_position.t;
        if (is_from_top) {
            self.position.update(null, paddle.position.t);
            change_dy = true;
        }

        const is_from_bottom = self.position.t <= paddle.position.b and self.old_position.t >= paddle.old_position.b;
        if (is_from_bottom) {
            self.position.update(null, paddle.position.b);
            change_dy = true;
        }

        if (change_dx) {
            self.dx *= -1;
        }

        if (change_dy) {
            self.dy *= -1;
        }
    }
};

pub const Paddle = struct {
    position: Position,
    old_position: Position,

    speed: i32,

    pub fn create(x: i32, y: i32) Paddle {
        const position = Position.create(x, y, 200, 20);
        const old_position = Position.create(x, y, 200, 20);

        return .{ .position = position, .old_position = old_position, .speed = 20 };
    }

    pub fn update_position(self: *Paddle, speed: i32) void {
        self.old_position = self.position;

        self.position.update(self.position.x + speed, null);
    }
};
