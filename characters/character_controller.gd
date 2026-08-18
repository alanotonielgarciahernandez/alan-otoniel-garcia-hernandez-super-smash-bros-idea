class_name CharacterController;
extends CharacterBody2D;

## Walking Speed.
const WALK_SPEED: float = 200.0;

## Walking acceleration speed.
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0;

## Time allowed for the character to perform a ground jump after leaving the floor.
# TODO: This value is very generous.
const COYOTE_TIME: float = 0.12;

## Jump Velocity.
const JUMP_VELOCITY: float = -500.0;

## Maximum number of jumps allowed before touching the ground again
const MAX_JUMPS: int = 2;

## How long the player can hold the jump button to keep going up (seconds)
const JUMP_HOLD_TIME: float = 0.25;

## Multiplier applied when the jump button is released early
const JUMP_CUT_MULTIPLIER: float = 0.6;

## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY: float = 220.0;

## Number of jumps performed since the character was last on the floor.
var jumps_used: int = 0;

## Timer that is consumed by the Jump state to stop jumping.
var jump_hold_timer: float = 0.0;

## Timer that keeps track of the amount of time character has been in air.
var falling_timer: float = 0.0;


func _physics_process( _delta: float ) -> void:
	# Falling timer resets if character is on floor.
	if is_on_floor():
		falling_timer = 0.0;
	else:
		falling_timer += _delta;


## Resets the jump counter. Called explicitly by states once a landing is confirmed.
func recharge_jumps() -> void:
	jumps_used = 0;
