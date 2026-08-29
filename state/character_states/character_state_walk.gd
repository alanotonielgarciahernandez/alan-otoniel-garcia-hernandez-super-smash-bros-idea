extends CharacterGroundMoveState;

func start() -> void:
	# Cache the controlled character reference for this state's lifetime.
	_character = controlled_node;
	
	# Set this tier's target horizontal speed (used by the base class's physics_process).
	_speed = CharacterController.WALK_SPEED;
	
	# Play the walk animation.
	_character.animator.play( 'walk' );
	
	# Consume a buffered jump input from just before entering walk.
	if _character.consume_buffered_input( 'jump' ):
		# A jump was queued — go straight to Jump instead of staying in Jog.
		state_machine.transition_to( 'CharacterStateJump' );
		return;

func process( _delta: float ) -> void:
	var direction := _character.get_move_axis();
	
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	var magnitude := absf( direction );
	
	if magnitude >= CharacterController.WALK_MAGNITUDE_THRESHOLD:
		# Re-evaluate tier (may go to Jog or straight to Run on a dash).
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
		return;
	
	if _character.is_jump_just_pressed():
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;
