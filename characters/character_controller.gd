class_name CharacterController;
extends CharacterBody2D;


## Time window (seconds) an input remains "buffered" before it's considered stale.
const INPUT_BUFFER_WINDOW: float = 0.1;

## Walking Speed.
const WALK_SPEED: float = 200.0;

## Walking acceleration speed.
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0;

## Time allowed for the character to perform a ground jump after leaving the floor.
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

## Stores buffered actions and the time (in seconds, engine ticks) after which they expire.
var _buffered_inputs: Dictionary = {};

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

func _unhandled_input( event: InputEvent ) -> void:
	# Buffer jump input the instant it's pressed, regardless of current state.
	if event.is_action_pressed( 'jump' ):
		buffer_input( 'jump' );


## Buffers an action so a state can consume it shortly after, even if pressed too early.
func buffer_input( action: String ) -> void:
	# Store expiration time for this action.
	_buffered_inputs[ action ] = Time.get_ticks_msec() / 1000.0 + INPUT_BUFFER_WINDOW;

## Checks if an action is still buffered (within its window) and consumes it if so.
func consume_buffered_input( action: String ) -> bool:
	# No buffered entry for this action.
	if not _buffered_inputs.has( action ):
		return false;
	
	# Get expiration time for this action.
	var expires_at: float = _buffered_inputs[ action ];
	
	# Buffered input is always consumed on check, valid or not, to avoid stale reads later.
	_buffered_inputs.erase( action );
	
	# Return whether it was still within its window.
	return Time.get_ticks_msec() / 1000.0 <= expires_at;

## Clears a specific buffered action without consuming it (e.g. on cancel conditions).
func clear_buffered_input( action: String ) -> void:
	_buffered_inputs.erase( action );

## Resets the jump counter. Called explicitly by states once a landing is confirmed.
func recharge_jumps() -> void:
	jumps_used = 0;
