class_name InputReader;
extends RefCounted;

## Magnitude considered "full tilt" — required (plus a dash gesture) to enter Run.
const RUN_MAGNITUDE_THRESHOLD: float = 0.9;

## Time window to detect a dash gesture (flick or re-press).
const RUN_INPUT_WINDOW: float = 0.15;

## action_name -> binding value (Key for keyboard, JoyButton for joypad).
var _bindings: Dictionary = {};

## action_name -> whether it was held last physics frame, for just-pressed detection.
var _was_pressed: Dictionary = {};

## action_name -> whether it was pressed this physics frame (not last).
## Refreshed for every known binding each update().
var _just_pressed: Dictionary = {};

## Whether horizontal input was neutral (near-zero) last physics frame.
var _was_neutral: bool = true;

## Timestamp the dash window was armed.
var _neutral_since: float = 0.0;

## Whether a dash trigger is currently armed and awaiting full-tilt input.
var _dash_window_armed: bool = false;


## Returns horizontal input axis (-1.0 to 1.0). Overridden per device.
func get_move_axis() -> float:
	return 0.0;

## Returns horizontal input magnitude (0.0 to 1.0).
func get_move_magnitude() -> float:
	return absf( get_move_axis() );

## Whether 'action' is currently held. Overridden per device.
func is_action_pressed( _action: String ) -> bool:
	return false;

## Whether 'action' was pressed this physics frame (not last). Valid after update().
func is_action_just_pressed( action: String ) -> bool:
	return _just_pressed.get( action, false );

## Whether a raw input event is a press of 'action' on this specific device. Overridden per device.
func is_action_press_event( _action: String, _event: InputEvent ) -> bool:
	return false;

## Rebinds 'action' to a new binding value (Key or JoyButton depending on device).
func rebind( action: String, binding_value ) -> void:
	_bindings[ action ] = binding_value;

## Returns the current binding for 'action', or null if unbound.
func get_binding( action: String ):
	return _bindings.get( action, null );

## Whether this device arms the dash window on every pass through neutral
## (analog-style flick) or only on an explicit release -> press (digital-style
## double-tap). Overridden per device.
func _arms_dash_continuously() -> bool:
	return false;

## Call once per physics frame to refresh just-pressed / dash tracking.
func update() -> void:
	# Refresh just-pressed state for every bound action.
	for action in _bindings:
		var pressed := is_action_pressed( action );
		_just_pressed[ action ] = pressed and not _was_pressed.get( action, false );
		_was_pressed[ action ] = pressed;
	
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
