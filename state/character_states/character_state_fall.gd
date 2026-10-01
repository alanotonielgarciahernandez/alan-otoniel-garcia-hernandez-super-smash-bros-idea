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
	# Aerial attack.
	if _character.is_attack_just_pressed():
		var direction: float = _character.get_move_axis();
		var facing: float = _character.facing;
		
		if signf( direction ) != facing and absf( direction ) > 0.5:
			state_machine.transition_to( 'CharacterStateBackwardAerial' );
		elif signf( direction ) == facing and absf( direction ) > 0.5:
			state_machine.transition_to( 'CharacterStateForwardAerial' );
		else:
			state_machine.transition_to( 'CharacterStateNeutralAerial' );
		return;
	
	super.physics_process( delta );
	
	# Fast-fall: only possible while already falling, press down to activate.
	# Once on, it stays on until landing.
	if not _character.is_fast_falling and _character.velocity.y > 0.0:
		if _character.is_down_pressed():
			_character.is_fast_falling = true;
			_character.velocity.y = CharacterController.FAST_FALL_SPEED;
	
	# Double/extra jump (Jump state will consume a charge).
	if _character.is_jump_just_pressed() and _character.jumps_used < CharacterController.MAX_JUMPS:
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	# Check for landing only after this frame's collision is resolved.
	_check_landed();
