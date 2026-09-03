# res://characters/character_controller.gd
# Main character controller.
#
# It binds one input device to this character.
# It buffers jump input and stores shared movement timers.
# It exposes speeds, gravity, and the grounded movement-tier picker.

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

## Acceleration applied to all grounded movement tiers (units/sec²).
## Currently shared across Walk/Jog/Run — see earlier note about giving
## Run a snappier acceleration later to better match Smash's dash feel.
const ACCELERATION_SPEED: float = JOG_SPEED * 6.0;

## Speed applied when character is in air.
const AIR_SPEED: float = 200.0;

## Analog magnitude below which movement counts as Walk instead of Jog.
const WALK_MAGNITUDE_THRESHOLD: float = 0.5;

## Magnitude considered "full tilt" — required (plus a dash trigger) to enter Run.
const RUN_MAGNITUDE_THRESHOLD: float = 0.9;

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

## Device controlling this character. -1 = keyboard. 0+ = joypad index,
## matching Input.get_connected_joypads(). Assign per instance (editor
## inspector, or a spawner/character-select screen).
@export var device_id: int = -1;

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

## Device-specific input reader, created once in _ready() based on device_id.
## Never re-evaluated afterward — this character always listens to only this device.
var _input_reader: InputReader;

func _ready() -> void:
	# Assign the input reader matching this character's device, once.
	_input_reader = KeyboardInputReader.new() if device_id == -1 else JoypadInputReader.new( device_id );

func _physics_process( _delta: float ) -> void:
	# Falling timer resets if character is on floor.
	if is_on_floor():
		falling_timer = 0.0;
	else:
		falling_timer += _delta;
	
	# Refresh this character's input reader (just-pressed tracking, dash window).
	_input_reader.update();

func _unhandled_input( event: InputEvent ) -> void:
	# Buffer jump input the instant it's pressed on this character's device.
	if _input_reader.is_action_press_event( 'jump', event ):
		buffer_input( 'jump' );


## Whether jump was pressed this frame, from this character's assigned device only.
func is_jump_just_pressed() -> bool:
	return _input_reader.is_action_just_pressed( 'jump' );

## Whether jump is currently held, from this character's assigned device only.
func is_jump_pressed() -> bool:
	return _input_reader.is_action_pressed( 'jump' );

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

## Applies gravity to vertical velocity, clamped to terminal velocity.
func apply_gravity( delta: float ) -> void:
	velocity.y = minf( TERMINAL_VELOCITY, velocity.y + get_gravity().y * delta );
