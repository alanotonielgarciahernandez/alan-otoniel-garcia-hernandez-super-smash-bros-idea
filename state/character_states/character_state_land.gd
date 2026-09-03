# res://state/character_states/character_state_land.gd
# Landing recovery state.
#
# It recharges jumps and zeros horizontal velocity.
# It stays inactionable for land lag, but a buffered jump can cancel out.
# It then enters a ground move tier or Idle, or Fall if pushed off.

extends CharacterState

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play land animation.
	_character.animator.play( 'land' );
	
	# Recharge jumps.
	_character.recharge_jumps();
	
	# Set horizontal velocity to 0.
	_character.velocity.x = 0.0;
	
	# Reset land timer before start recovering.
	_character.land_timer = 0;

func process( _delta: float ) -> void:
	# Check for a buffered jump every frame during recovery, so an input
	# pressed at any point during landing lag isn't missed.
	if _character.consume_buffered_input( 'jump' ):
		# A jump was queued during recovery — go straight to Jump.
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	# Advance the recovery timer for this frame.
	_character.land_timer += _delta;
	
	# Still within the recovery window — stay in Land, don't check movement yet.
	if _character.land_timer < CharacterController.LAND_TIME:
		return;
	
	# Recovery finished — read input to decide where to go next.
	var direction := _character.get_move_axis();
	
	# Player is holding a direction — move straight into the matching ground tier.
	if direction != 0.0:
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
		return;
	
	# No input — settle into Idle.
	state_machine.transition_to( 'CharacterStateIdle' );

func physics_process( delta: float ) -> void:
	# Apply gravity.
	_character.apply_gravity( delta );
	
	_character.move_and_slide();
	
	# Safety: if we're no longer on the floor (e.g. pushed off a ledge during
	# landing recovery), fall instead of getting stuck in the land animation.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
