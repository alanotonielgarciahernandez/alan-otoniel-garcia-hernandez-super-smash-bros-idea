# joypad_input_reader.gd
# Overrides InputReader class variables and methods.

class_name JoypadInputReader;
extends InputReader;

## Deadzone applied to the raw analog stick axis.
const DEADZONE: float = 0.2;

## Index of the joypad this reader is exclusively bound to.
var device: int;

func _init( joypad_device: int ) -> void:
	device = joypad_device;
	_bindings = {
		'jump': JOY_BUTTON_A,
	};
	# Note: movement stays a fixed stick axis, not a rebindable button.

func is_action_pressed( action: String ) -> bool:
	# Return false if action is not listed.
	if not _bindings.has( action ):
		return false;
	
	return Input.is_joy_button_pressed( device, _bindings[ action ] );

func is_action_press_event( action: String, event: InputEvent ) -> bool:
	# Return false if action is not listed.
	if not _bindings.has( action ) or not event is InputEventJoypadButton:
		return false;
	
	return event.device == device and event.pressed and event.button_index == _bindings[ action ];

func get_move_axis() -> float:
	var raw := Input.get_joy_axis( device, JOY_AXIS_LEFT_X );
	return raw if absf( raw ) >= DEADZONE else 0.0;

func _arms_dash_continuously() -> bool:
	# Analog: keep re-arming while near neutral, so even a first quick
	# flick from a stand-still counts as a dash trigger.
	return true;
