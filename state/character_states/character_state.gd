# character_state.gd
# Base class for character states.

class_name CharacterState;
extends State;

## Character Object reference, typed for character-driven states.
var _character: CharacterController;

func start() -> void:
	# Cache the controlled character reference for this state's lifetime.
	_character = controlled_node;
