# res://state/character_states/character_state_fall.gd
# Airborne fall state.
#
# It applies gravity and shared air movement.
# It allows an extra jump while charges remain.
# It transitions to Land once the floor is resolved.

extends CharacterAirState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the fall animation.
	_character.animator.play( 'fall' );

func physics_process( delta: float ) -> void:
	super.physics_process( delta );
	
	# Double/extra jump (Jump state will consume a charge).
	if _character.is_jump_just_pressed() and _character.jumps_used < CharacterController.MAX_JUMPS:
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	# Check for landing only after this frame's collision is resolved.
	_check_landed();
