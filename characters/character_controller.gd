class_name CharacterController;
extends CharacterBody2D;


## Time window (seconds) an input remains "buffered" before it's considered stale.
const INPUT_BUFFER_WINDOW: float = 0.15;

## Walking speed (analog partial tilt only).
const WALK_SPEED: float = 100.0;

## Jogging speed (default tier — keyboard's only tier without dashing).
const JOG_SPEED: float = 200.0;

## Running speed (reached via a dash trigger).
const RUN_SPEED: float = 320.0;

## Walking acceleration speed, based on the default Jog tier.
const ACCELERATION_SPEED: float = JOG_SPEED * 6.0;

## Analog magnitude below which movement counts as Walk instead of Jog.
const WALK_MAGNITUDE_THRESHOLD: float = 0.5;

## Magnitude considered "full tilt" — required (plus a dash trigger) to enter Run.
const RUN_MAGNITUDE_THRESHOLD: float = 0.9;

## Time window to detect a flick (analog) or re-press (digital) that triggers Run.
const RUN_INPUT_WINDOW: float = 0.15;

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

## How long the player will recover from falling.
const LAND_TIME: float = 0.12;

## Character Animator object reference.
@export var animator: AnimatedSprite2D;

## Stores buffered actions and the time (in seconds, engine ticks) after which they expire.
var _buffered_inputs: Dictionary = {};

## Number of jumps performed since the character was last on the floor.
var jumps_used: int = 0;

## Timer that is consumed by the Jump state to stop jumping.
var jump_hold_timer: float = 0.0;

## Timer that keeps track of the amount of time character has been in air.
var falling_timer: float = 0.0;

## Timer that keeps track of the amount of time character has been recovering from falling.
var land_timer: float = 0.0;


## Whether the most recent horizontal input came from an analog device (joypad).
var _last_input_was_analog: bool = false;

## Whether horizontal input was neutral (near-zero) last frame.
var _was_neutral: bool = true;

## Timestamp the dash window was armed.
var _neutral_since: float = 0.0;

## Whether a dash trigger is currently armed and awaiting full-tilt input.
var _dash_window_armed: bool = false;

## Returns the current horizontal input magnitude (0.0 - 1.0), ignoring direction.
func get_move_magnitude() -> float:
	return maxf( Input.get_action_strength( 'move_left' ), Input.get_action_strength( 'move_right' ) );

## Tracks neutral <-> active input transitions each physics frame, arming the
## dash detection window differently depending on the input device.
func _update_dash_tracking( magnitude: float ) -> void:
	var is_neutral := magnitude < 0.1;
	
	if _last_input_was_analog:
		# Analog: keep re-arming while near neutral, so even a first quick
		# flick from a stand-still counts as a dash trigger.
		if is_neutral:
			_neutral_since = Time.get_ticks_msec() / 1000.0;
			_dash_window_armed = true;
	else:
		# Digital (keyboard): only arm on the exact frame input drops from
		# active to neutral, so a dash requires a real release + re-press.
		if is_neutral and not _was_neutral:
			_neutral_since = Time.get_ticks_msec() / 1000.0;
			_dash_window_armed = true;
	
	_was_neutral = is_neutral;

## Checks (and consumes) whether the current input counts as a dash trigger
## into Run. Safe to call every frame; only fires once per armed window.
func consume_dash_trigger( magnitude: float ) -> bool:
	if not _dash_window_armed or magnitude < RUN_MAGNITUDE_THRESHOLD:
		return false;
	
	var now := Time.get_ticks_msec() / 1000.0;
	var triggered: bool = ( now - _neutral_since ) <= RUN_INPUT_WINDOW;
	
	# Disarm regardless of outcome, so a stale window can't fire later.
	_dash_window_armed = false;
	
	return triggered;

## Returns the grounded movement state to enter for the given horizontal
## input — used when starting fresh movement (from Idle or on landing).
func get_ground_move_state( direction: float ) -> String:
	var magnitude := absf( direction );
	
	if magnitude == 0.0:
		return 'CharacterStateIdle';
	
	if consume_dash_trigger( magnitude ):
		return 'CharacterStateRun';
	
	if magnitude < WALK_MAGNITUDE_THRESHOLD:
		return 'CharacterStateWalk';
	
	return 'CharacterStateJog';


func _physics_process( _delta: float ) -> void:
	# Falling timer resets if character is on floor.
	if is_on_floor():
		falling_timer = 0.0;
	else:
		falling_timer += _delta;
	
	# Track neutral/active input transitions for dash (Run) detection.
	_update_dash_tracking( get_move_magnitude() );

func _unhandled_input( event: InputEvent ) -> void:
	# Buffer jump input the instant it's pressed, regardless of current state.
	if event.is_action_pressed( 'jump' ):
		buffer_input( 'jump' );
	
	# Track whether horizontal input is currently coming from an analog device.
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		_last_input_was_analog = true;
	elif event is InputEventKey and event.pressed:
		_last_input_was_analog = false;


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
