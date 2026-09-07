# res://state/character_states/character_state_land.gd
# Landing recovery state.
#
# Soft vs hard lag is chosen from fall speed / fast-fall.
# Horizontal momentum is kept and slowed by ground friction (Smash-like).
# Buffered jump can cancel the recovery at any time.

extends CharacterState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play land animation.
	_character.animator.play( 'land' );
	
	# Recharge jumps.
	_character.recharge_jumps();
	
	# Decide soft vs hard lag BEFORE clearing the fast-fall flag.
	# Fast-fall is the most reliable signal for a hard landing in Smash.
	var is_hard_land: bool = _character.is_fast_falling;
	
	# Also treat near-terminal fall speed as hard (in case fast-fall flag was missed).
	# Note: velocity.y is often already reduced by move_and_slide, so this is only a backup.
	if _character.velocity.y >= CharacterController.TERMINAL_VELOCITY * 0.85:
		is_hard_land = true;
	
	if is_hard_land:
		_character.land_timer = CharacterController.LAND_TIME_HARD;
	else:
		_character.land_timer = CharacterController.LAND_TIME_SOFT;
	
	# Now it is safe to clear the flag.
	_character.is_fast_falling = false;

func process( _delta: float ) -> void:
	# Buffered jump can cancel landing lag at any time.
	if _character.consume_buffered_input( 'jump' ):
		state_machine.transition_to( 'CharacterStateJumpSquat' );
		return;
	
	# Count down remaining recovery.
	_character.land_timer -= _delta;
	
	# Still recovering — stay in Land.
	if _character.land_timer > 0.0:
		return;
	
	# Recovery finished — choose next grounded state.
	var direction := _character.get_move_axis();
	
	if direction != 0.0:
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
		return;
	
	state_machine.transition_to( 'CharacterStateIdle' );

func physics_process( delta: float ) -> void:
	# Apply ground friction so residual horizontal speed fades naturally.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		0.0,
		CharacterController.GROUND_FRICTION * delta
	);
	
	# Apply gravity (safety while grounded).
	_character.apply_gravity( delta );
	
	_character.move_and_slide();
	
	# Safety: pushed off a ledge during recovery → Fall.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
