extends CharacterGroundMoveState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the walk animation.
	_character.animator.play( 'walk' );
	
	# Set this tier's target horizontal speed (used by the base class's physics_process).
	_speed = CharacterController.WALK_SPEED;

func process( delta: float ) -> void:
	var direction := _character.get_move_axis();
	
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	var magnitude := absf( direction );
	
	if magnitude >= CharacterController.WALK_MAGNITUDE_THRESHOLD:
		# Re-evaluate tier (may go to Jog or straight to Run on a dash).
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
		return;
	
	super.process( delta );
