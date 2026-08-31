class_name CharacterAirState;
extends CharacterState;

func physics_process( delta: float ) -> void:
	# Get move direction.
	var direction := _character.get_move_axis();
	
	# Move.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * CharacterController.AIR_SPEED,
		CharacterController.ACCELERATION_SPEED * delta
	);

## Checks whether the character has landed. Call this AFTER move_and_slide()
## each frame, once this frame's floor collision is actually resolved.
func _check_landed() -> void:
	if _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateLand' );
