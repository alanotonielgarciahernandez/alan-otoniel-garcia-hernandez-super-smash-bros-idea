class_name JoypadInputReader;
extends InputReader;

## Button used for jumping.
const JUMP_BUTTON: JoyButton = JOY_BUTTON_Y;

## Deadzone applied to the raw analog stick axis.
const DEADZONE: float = 0.2;

## Index of the joypad this reader is exclusively bound to.
var device: int;

func _init( joypad_device: int ) -> void:
	device = joypad_device;

func get_move_axis() -> float:
	# Read the left stick's X axis directly, bypassing the shared InputMap
	# so this reader never overlaps with keyboard or another joypad.
	var raw := Input.get_joy_axis( device, JOY_AXIS_LEFT_X );
	return raw if absf( raw ) >= DEADZONE else 0.0;

func is_jump_pressed() -> bool:
	return Input.is_joy_button_pressed( device, JUMP_BUTTON );

func is_jump_press_event( event: InputEvent ) -> bool:
	return event is InputEventJoypadButton and event.device == device and event.button_index == JUMP_BUTTON and event.pressed;

func _arms_dash_continuously() -> bool:
	# Analog: keep re-arming while near neutral, so even a first quick
	# flick from a stand-still counts as a dash trigger.
	return true;
