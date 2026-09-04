# res://state/character_states/character_air_state.gd
# Base class for airborne character states.
#
# It applies shared horizontal air movement.
# It checks for landing after move_and_slide has resolved collisions.

class_name CharacterAirState;
extends CharacterState;

func physics_process( delta: float ) -> void:
	# Get horizontal input axis from the character's assigned device.
	var direction := _character.get_move_axis();
	
	# Decide target velocity for this frame.
	var target_velocity_x: float = direction * CharacterController.AIR_SPEED;
	
	if absf( direction ) > 0.01:
		# Player is holding a direction — accelerate toward the tier speed.
		_character.velocity.x = move_toward(
			_character.velocity.x,
			target_velocity_x,
			CharacterController.ACCELERATION_SPEED * delta
		);
	else:
		# No meaningful input — apply air friction / traction.
		_character.velocity.x = move_toward(
			_character.velocity.x,
			0.0,
			CharacterController.AIR_FRICTION * delta
		);
	
	# Apply gravity for this frame.
	_character.apply_gravity( delta );
	
	# Move the character and resolve collisions.
	_character.move_and_slide();

## Checks whether the character has landed. Call this AFTER move_and_slide()
## each frame, once this frame's floor collision is actually resolved.
func _check_landed() -> void:
	if _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateLand' );
