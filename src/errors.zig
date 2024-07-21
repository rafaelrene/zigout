pub const SDLError = error{
    FailedInit,
    FailedCreatingWindow,
    FailedGettingEvent,
};

pub const GameError = error{
    BallOutOfBounds,
};
