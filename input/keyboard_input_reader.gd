class_name KeyboardInputReader;
extends InputReader;

## Reads exclusively from keyboard, via the shared move/jump actions
## (these actions must only have keyboard events bound to them in the
## InputMap — joypads read through JoypadInputReader instead).

func get_move_axis() -> float:
	return Input.get_axis( 'move_left', 'move_right' );

func is_jump_pressed() -> bool:
	return Input.is_action_pressed( 'jump' );

func is_jump_press_event( event: InputEvent ) -> bool:
	return event is InputEventKey and event.is_action_pressed( 'jump' );

func _arms_dash_continuously() -> bool:
	# Digital: only counts as a dash on an explicit release -> press.
	return false;
