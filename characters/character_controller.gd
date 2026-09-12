# res://characters/character_controller.gd
# Main character controller.
#
# It binds one input device to this character.
# It buffers jump input and stores shared movement timers.
# It exposes speeds, gravity, and the grounded movement-tier picker.

class_name CharacterController;
extends CharacterBody2D;


## Frame window an input remains "buffered" before it's considered stale.
const INPUT_BUFFER_WINDOW: int = 9;

## Acceleration applied to all grounded movement tiers (units/sec²).
## Currently shared across Walk/Jog/Run — see earlier note about giving
## Run a snappier acceleration later to better match Smash's dash feel.
const ACCELERATION_SPEED: float = JOG_SPEED * 6.0;

## Analog magnitude below which movement counts as Walk instead of Jog.
const WALK_MAGNITUDE_THRESHOLD: float = 0.5;

## Walking speed (analog partial tilt only).
const WALK_SPEED: float = 100.0;

## Jogging speed (default tier — keyboard's only tier without dashing).
const JOG_SPEED: float = 200.0;

## Magnitude considered "full tilt" — required (plus a dash trigger) to enter Run.
const RUN_MAGNITUDE_THRESHOLD: float = 0.9;

## Extra horizontal speed applied once when entering Run from a dash.
## Makes the initial dash feel snappy.
const RUN_BURST_SPEED: float = 80.0;

## Running speed (reached via a dash trigger).
const RUN_SPEED: float = 320.0;

## Ground friction / traction (units per second²).
## Higher = stops faster.
const GROUND_FRICTION: float = 1800.0;

## Horizontal acceleration while airborne (units per second²).
## Lower than grounded acceleration so air drift feels less snappy than running.
## ~0.5× ground accel is a solid Smash-like starting point.
const AIR_ACCELERATION: float = ACCELERATION_SPEED * 0.5;

## Speed applied when character is in air.
const AIR_SPEED: float = 200.0;

## Air friction / traction (units per second²).
## Higher = stops faster
const AIR_FRICTION: float = 200.0;

## Frames allowed for the character to perform a ground jump after leaving the floor.
const COYOTE_TIME: int = 7;

## Frame duration of the grounded jumpsquat.
const JUMP_SQUAT_FRAMES: int = 3;

## Short hop vertical velocity.
## Roughly 0.55–0.6× full hop is a good Smash-like starting ratio.
const SHORT_HOP_VELOCITY: float = -280.0;

## Jump Velocity.
const JUMP_VELOCITY: float = -500.0;

## Maximum number of jumps allowed before touching the ground again
const MAX_JUMPS: int = 2;

## Maximum speed at which the player can normally fall.
const TERMINAL_VELOCITY: float = 220.0;

## Fast-fall maximum fall speed.
const FAST_FALL_SPEED: float = 360.0;

## Soft landing recovery (normal fall / short hop).
const LAND_FRAMES_SOFT: int = 4;

## Hard landing recovery (fast-fall or high fall speed).
const LAND_FRAMES_HARD: int = 11;

## Character Animator object reference.
@export var animator: AnimatedSprite2D;

## Device controlling this character. -1 = keyboard. 0+ = joypad index,
## matching Input.get_connected_joypads(). Assign per instance (editor
## inspector, or a spawner/character-select screen).
@export var device_id: int = -1;

## action_name -> remaining frames the buffer is still valid.
## 0 or missing = not buffered / expired.
var _buffered_inputs: Dictionary = {};

## Number of jumps performed since the character was last on the floor.
var jumps_used: int = 0;

## Frame count that keeps track of the amount of time character has been in air.
var falling_frames: int = 0;

## Whether the character is currently fast-falling.
var is_fast_falling: bool = false;

## Frame count that keeps track of the amount of time character has been recovering from falling.
var land_frames: int = 0;

## Current damage percent (Smash-style). Starts at 0.
var percent: float = 0.0;

## Device-specific input reader, created once in _ready() based on device_id.
## Never re-evaluated afterward — this character always listens to only this device.
var _input_reader: InputReader;

func _ready() -> void:
	# Assign the input reader matching this character's device, once.
	_input_reader = KeyboardInputReader.new() if device_id == -1 else JoypadInputReader.new( device_id );

func _physics_process( _delta: float ) -> void:
	# Falling frames reset if character is on floor.
	if is_on_floor():
		falling_frames = 0;
	else:
		falling_frames += 1;
	
	# Count down every active input buffer by one frame.
	_tick_input_buffers();
	
	# Refresh this character's input reader (just-pressed tracking, dash window).
	_input_reader.update();

func _unhandled_input( event: InputEvent ) -> void:
	# Buffer jump input the instant it's pressed on this character's device.
	if _input_reader.is_action_press_event( 'jump', event ):
		buffer_input( 'jump' );


## Whether the down direction is pressed past a threshold on this device.
func is_down_pressed() -> bool:
	return _input_reader.get_vertical_axis() > 0.5;

## Whether jump was pressed this frame, from this character's assigned device only.
func is_jump_just_pressed() -> bool:
	return _input_reader.is_action_just_pressed( 'jump' );

## Whether jump is currently held, from this character's assigned device only.
func is_jump_pressed() -> bool:
	return _input_reader.is_action_pressed( 'jump' );

## Whether attack was pressed this frame, from this character's assigned device only.
func is_attack_just_pressed() -> bool:
	return _input_reader.is_action_just_pressed( 'attack' );

## Whether attack is currently held, from this character's assigned device only.
func is_attack_pressed() -> bool:
	return _input_reader.is_action_pressed( 'attack' );

## Returns this character's horizontal input axis, from its assigned device only.
func get_move_axis() -> float:
	return _input_reader.get_move_axis();

## Returns the grounded movement state to enter for the given horizontal
## input — used when starting fresh movement (from Idle or on landing).
func get_ground_move_state( direction: float ) -> String:
	var magnitude := absf( direction );
	
	if magnitude == 0.0:
		return 'CharacterStateIdle';
	
	if _input_reader.consume_dash_trigger():
		return 'CharacterStateRun';
	
	if magnitude < WALK_MAGNITUDE_THRESHOLD:
		return 'CharacterStateWalk';
	
	return 'CharacterStateJog';

## Buffers an action so a state can consume it shortly after, even if pressed too early.
## Resets the window to the full duration every time the action is pressed.
func buffer_input( action: String ) -> void:
	# Store remaining frames for this action (overwrites any previous buffer).
	_buffered_inputs[ action ] = INPUT_BUFFER_WINDOW;


## Checks if an action is still buffered (remaining frames > 0) and consumes it if so.
## Always erases the entry so a stale buffer can never be read twice.
func consume_buffered_input( action: String ) -> bool:
	# No buffered entry for this action.
	if not _buffered_inputs.has( action ):
		return false;
	
	# How many frames are still left on this buffer.
	var remaining: int = _buffered_inputs[ action ];
	
	# Always consume (erase) on check to avoid stale reads later.
	_buffered_inputs.erase( action );
	
	# Valid only if at least one frame remained.
	return remaining > 0;


## Clears a specific buffered action without consuming it (e.g. on cancel conditions).
func clear_buffered_input( action: String ) -> void:
	_buffered_inputs.erase( action );


## Counts every active input buffer down by one frame.
## Call this once per physics frame from _physics_process.
func _tick_input_buffers() -> void:
	# Collect keys first so we can safely erase while iterating.
	var expired: Array[ String ] = [];
	
	for action in _buffered_inputs:
		_buffered_inputs[ action ] -= 1;
		
		# Mark for removal once the window has fully expired.
		if _buffered_inputs[ action ] <= 0:
			expired.append( action );
	
	# Erase expired buffers after the loop.
	for action in expired:
		_buffered_inputs.erase( action );

## Resets the jump counter. Called explicitly by states once a landing is confirmed.
func recharge_jumps() -> void:
	jumps_used = 0;

## Applies gravity to vertical velocity, clamped to the correct terminal speed.
func apply_gravity( delta: float ) -> void:
	var max_fall: float = FAST_FALL_SPEED if is_fast_falling else TERMINAL_VELOCITY;
	velocity.y = minf( max_fall, velocity.y + get_gravity().y * delta );
