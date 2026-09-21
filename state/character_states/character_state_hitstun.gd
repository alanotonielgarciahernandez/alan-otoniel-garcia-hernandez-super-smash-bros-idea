# res://state/character_states/character_state_hitstun.gd
# Hitstun state after being hit.
#
# Character is locked for a fixed number of frames (set by apply_hit).
# Residual launch velocity is kept; gravity and air friction still apply.
# No input is accepted until the stun ends, then recovery chooses Idle / ground move / Fall.

extends CharacterState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Safety check if somehow hitstun_frames is already ≤ 0 when entering.
	if _character.hitstun_frames < 1:
		_character.hitstun_frames = 1;
	
	# Play hitstun animation.
	#_character.animator.play( 'hitstun' );

func physics_process( delta: float ) -> void:
	var friction: float = CharacterController.GROUND_FRICTION if _character.is_on_floor() else CharacterController.AIR_FRICTION * 0.5;
	
	# Apply residual friction.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		0.0,
		friction * delta
	);
	
	_character.apply_gravity( delta );
	_character.move_and_slide();
	
	# Count down stun.
	_character.hitstun_frames -= 1;
	
	if _character.hitstun_frames > 0:
		return;
	
	# Stun finished — choose recovery state.
	if _character.is_on_floor():
		var direction := _character.get_move_axis();
		if direction != 0.0:
			state_machine.transition_to( _character.get_ground_move_state( direction ) );
		else:
			state_machine.transition_to( 'CharacterStateIdle' );
	else:
		state_machine.transition_to( 'CharacterStateFall' );
