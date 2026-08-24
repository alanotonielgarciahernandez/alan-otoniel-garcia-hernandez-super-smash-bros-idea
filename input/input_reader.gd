class_name InputReader;
extends RefCounted;

## Magnitude considered "full tilt" — required (plus a dash gesture) to enter Run.
const RUN_MAGNITUDE_THRESHOLD: float = 0.9;

## Time window to detect a dash gesture (flick or re-press).
const RUN_INPUT_WINDOW: float = 0.15;

## Whether horizontal input was neutral (near-zero) last physics frame.
var _was_neutral: bool = true;

## Timestamp the dash window was armed.
var _neutral_since: float = 0.0;

## Whether a dash trigger is currently armed and awaiting full-tilt input.
var _dash_window_armed: bool = false;

## Whether jump was held last physics frame, to detect just-pressed transitions.
var _was_jump_pressed: bool = false;

## Whether jump was pressed on this physics frame (not last). Valid after update().
var _jump_just_pressed: bool = false;


## Returns horizontal input axis (-1.0 to 1.0). Overridden per device.
func get_move_axis() -> float:
	return 0.0;

## Returns horizontal input magnitude (0.0 to 1.0).
func get_move_magnitude() -> float:
	return absf( get_move_axis() );

## Whether jump is currently held. Overridden per device.
func is_jump_pressed() -> bool:
	return false;

## Whether jump was pressed this frame (not last). Valid after update() runs.
func is_jump_just_pressed() -> bool:
	return _jump_just_pressed;

## Whether a raw input event is a jump press on this specific device. Overridden per device.
func is_jump_press_event( _event: InputEvent ) -> bool:
	return false;

## Whether this device arms the dash window on every pass through neutral
## (analog-style flick) or only on an explicit release -> press (digital-style
## double-tap). Overridden per device.
func _arms_dash_continuously() -> bool:
	return false;

## Call once per physics frame to refresh just-pressed / dash tracking.
func update() -> void:
	# Track jump just-pressed.
	var jump_pressed := is_jump_pressed();
	_jump_just_pressed = jump_pressed and not _was_jump_pressed;
	_was_jump_pressed = jump_pressed;
	
	# Track neutral <-> active transitions to arm the dash detection window.
	var is_neutral := get_move_magnitude() < 0.1;
	
	if _arms_dash_continuously():
		if is_neutral:
			_neutral_since = Time.get_ticks_msec() / 1000.0;
			_dash_window_armed = true;
	else:
		if is_neutral and not _was_neutral:
			_neutral_since = Time.get_ticks_msec() / 1000.0;
			_dash_window_armed = true;
	
	_was_neutral = is_neutral;

## Checks (and consumes) whether current input counts as a dash trigger into Run.
func consume_dash_trigger() -> bool:
	var magnitude := get_move_magnitude();
	
	if not _dash_window_armed or magnitude < RUN_MAGNITUDE_THRESHOLD:
		return false;
	
	var now := Time.get_ticks_msec() / 1000.0;
	var triggered: bool = ( now - _neutral_since ) <= RUN_INPUT_WINDOW;
	
	# Disarm regardless of outcome, so a stale window can't fire later.
	_dash_window_armed = false;
	
	return triggered;
