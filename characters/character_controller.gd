class_name CharacterController;
extends CharacterBody2D;

## Walking Speed.
const WALK_SPEED: float = 200.0;

## Walking acceleration speed.
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0;

## Time allowed for the character to perform a ground jump after leaving the floor.
# TODO: This value is very generous.
const COYOTE_TIME: float = 0.25;

## Jump Velocity.
const JUMP_VELOCITY: float = -500.0;

## How long the player can hold the jump button to keep going up (seconds)
const JUMP_HOLD_TIME: float = 0.25;

## Multiplier applied when the jump button is released early
const JUMP_CUT_MULTIPLIER: float = 0.6;

## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY: float = 220.0;

## Double jump ability flag.
var double_jump_charged: bool = false;

## Timer that is consumed by the Jump state to stop jumping.
var jump_hold_timer: float = 0.0;

## Timer that keeps track of the amount of time character has been in air.
var falling_timer: float = 0.0;

func _physics_process( _delta: float ) -> void:
	# Falling timer resets if character hits the ground.
	if is_on_floor():
		falling_timer = 0.0;
	else:
		falling_timer += _delta;
