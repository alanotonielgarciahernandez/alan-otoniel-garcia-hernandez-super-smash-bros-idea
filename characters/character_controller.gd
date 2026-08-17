class_name CharacterController;
extends CharacterBody2D;

## Walking Speed.
const WALK_SPEED: float = 200.0;

## Walking acceleration speed.
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0;

## Jump Velocity.
const JUMP_VELOCITY: float = -500.0;

## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY: float = 220.0;

## How long the player can hold the jump button to keep going up (seconds)
const JUMP_HOLD_TIME: float = 0.25;

## Multiplier applied when the jump button is released early
const JUMP_CUT_MULTIPLIER: float = 0.6;

## Timer that is consumed by the Jump state to stop jumping.
var jump_hold_timer: float = 0.0;

## Double jump ability flag.
var double_jump_charged: bool = false;
