# res://input/input_reader.gd
# Base class for device-specific input readers.
#
# It tracks pressed and just-pressed actions for one device.
# It arms and consumes the dash-trigger window (flick or double-tap).
# It stores rebindable action bindings.

class_name InputReader;
extends RefCounted;

## Physics frames a flick or double-tap can still become a dash.
## Counted so consume_dash_trigger() can succeed on this many frames.
const RUN_INPUT_WINDOW: int = 9;

## Magnitude below this still counts as neutral for the dash window.
## Wider than the joypad deadzone, so a light tilt does not cancel a flick.
const DASH_NEUTRAL_THRESHOLD: float = 0.3;

## Analog frames the stick must rest before the dash window re-arms.
## A one-frame deadzone spike is not a new flick.
const DASH_NEUTRAL_SETTLE_FRAMES: int = 2;

## action_name -> binding value (Key for keyboard, JoyButton for joypad).
var _bindings: Dictionary = {};

## action_name -> whether it was held last physics frame, for just-pressed detection.
var _was_pressed: Dictionary = {};

## action_name -> unread press edge. Cleared on read and at the end of _process.
var _just_pressed: Dictionary = {};

## action_name -> press event arrived since the last update(), including a tap
## that was already released before the physics poll.
var _latched_press: Dictionary = {};

## Whether horizontal input was neutral last physics frame.
var _was_neutral: bool = true;

## How long the analog stick has rested. Starts settled so the first flick works.
var _neutral_settle_frames: int = DASH_NEUTRAL_SETTLE_FRAMES;

## Remaining frames the dash window stays armed. 0 = not armed.
var _dash_window_frames: int = 0;


## Returns horizontal input axis (-1.0 to 1.0). Overridden per device.
func get_move_axis() -> float:
	return 0.0;

## Returns vertical input axis (-1.0 to 1.0). Overridden per device.
func get_vertical_axis() -> float:
	return 0.0;

## Returns horizontal input magnitude (0.0 to 1.0).
func get_move_magnitude() -> float:
	return absf( get_move_axis() );

## Whether 'action' is currently held. Overridden per device.
func is_action_pressed( _action: String ) -> bool:
	return false;

## Whether 'action' has an unread press edge. The read clears it.
func is_action_just_pressed( action: String ) -> bool:
	var edge := bool( _just_pressed.get( action, false ) );
	
	# A second read this frame must not see the same tap.
	if edge:
		_just_pressed[ action ] = false;
	
	return edge;

## Whether a raw input event is a press of 'action' on this specific device. Overridden per device.
func is_action_press_event( _action: String, _event: InputEvent ) -> bool:
	return false;

## Records a raw event before the next axis read. Keyboard uses this for press order.
func note_input_event( event: InputEvent ) -> void:
	# A press between polls still counts, even if the key is up by update().
	for action in _bindings:
		if is_action_press_event( action, event ):
			_latched_press[ action ] = true;

## Drops press edges nobody read. Call once after this idle frame's states.
func expire_just_pressed() -> void:
	for action in _just_pressed:
		_just_pressed[ action ] = false;

## Treat keys already held at spawn as the baseline, not a new press.
func prime_held_actions() -> void:
	for action in _bindings:
		_was_pressed[ action ] = is_action_pressed( action );
		_just_pressed[ action ] = false;
		_latched_press[ action ] = false;

## Rebinds 'action' to a new binding value (Key or JoyButton depending on device).
func rebind( action: String, binding_value ) -> void:
	_bindings[ action ] = binding_value;
	
	# The new control's current hold is the baseline, so the swap itself is not a press.
	_was_pressed[ action ] = is_action_pressed( action );
	_just_pressed[ action ] = false;
	_latched_press[ action ] = false;

## Returns the current binding for 'action', or null if unbound.
func get_binding( action: String ):
	return _bindings.get( action, null );

## Whether this device keeps the dash window armed while resting (analog flick)
## or arms once on the release into neutral (keyboard double-tap).
func _arms_dash_continuously() -> bool:
	return false;

## Call once per physics frame to refresh just-pressed / dash tracking.
func update() -> void:
	# Refresh press edges. An unread edge stays until something reads it.
	for action in _bindings:
		var pressed := is_action_pressed( action );
		var was_held := bool( _was_pressed.get( action, false ) );
		var edge := ( pressed and not was_held ) or bool( _latched_press.get( action, false ) );
		
		if edge:
			_just_pressed[ action ] = true;
		
		# The latch has been folded into this sample.
		_latched_press[ action ] = false;
		_was_pressed[ action ] = pressed;
	
	var is_neutral := get_move_magnitude() < DASH_NEUTRAL_THRESHOLD;
	# First frame out of neutral still shows the full remaining window.
	var left_neutral := _was_neutral and not is_neutral;
	var armed := false;
	
	if _arms_dash_continuously():
		if is_neutral:
			# Count rest time, and stop at the cap so a long rest does not overflow.
			if _neutral_settle_frames < DASH_NEUTRAL_SETTLE_FRAMES:
				_neutral_settle_frames += 1;
			
			# Re-arm only after the stick has actually settled.
			if _neutral_settle_frames >= DASH_NEUTRAL_SETTLE_FRAMES:
				_dash_window_frames = RUN_INPUT_WINDOW;
				armed = true;
		else:
			_neutral_settle_frames = 0;
	elif is_neutral and not _was_neutral:
		# Keyboard: the window starts when the direction is released.
		_dash_window_frames = RUN_INPUT_WINDOW;
		armed = true;
	
	# Arming and the first frame out of neutral do not burn a frame.
	if not armed and not left_neutral and _dash_window_frames > 0:
		_dash_window_frames -= 1;
	
	_was_neutral = is_neutral;

## Consumes the dash window when it is open. Magnitude is the caller's decision.
func consume_dash_trigger() -> bool:
	if _dash_window_frames <= 0:
		return false;
	
	# One flick opens the window once.
	_dash_window_frames = 0;
	
	return true;
