# res://state/character_states/character_state.gd
# Base class for character-driven states.
#
# It caches a typed CharacterController reference on start.

class_name CharacterState;
extends State;

## Character Object reference, typed for character-driven states.
var _character: CharacterController;

func start() -> void:
	# Cache the controlled character reference for this state's lifetime.
	_character = controlled_node;
