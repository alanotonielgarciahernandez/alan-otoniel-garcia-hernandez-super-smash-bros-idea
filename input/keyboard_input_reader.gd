# res://input/keyboard_input_reader.gd
# Keyboard input reader.
#
# It maps keys to move and jump actions.
# It arms dash only on an explicit release-then-press.

class_name KeyboardInputReader;
extends InputReader;

func _init() -> void:
	# TODO: Default bindings — overwritten later if a save file exists.
	_bindings = {
		'move_left': KEY_LEFT,
		'move_right': KEY_RIGHT,
		'jump': KEY_SPACE,
	};

func is_action_pressed( action: String ) -> bool:
	# Return false if action is not listed.
	if not _bindings.has( action ):
		return false;
	
	return Input.is_key_pressed( _bindings[ action ] );

func is_action_press_event( action: String, event: InputEvent ) -> bool:
	# Return false if action is not listed.
	if not _bindings.has( action ) or not event is InputEventKey:
		return false;
	
	return event.pressed and not event.echo and event.keycode == _bindings[ action ];

func get_move_axis() -> float:
	var left := 1.0 if is_action_pressed( 'move_left' ) else 0.0;
	var right := 1.0 if is_action_pressed( 'move_right' ) else 0.0;
	return right - left;

func _arms_dash_continuously() -> bool:
	# Digital: only counts as a dash on an explicit release -> press.
	return false;
