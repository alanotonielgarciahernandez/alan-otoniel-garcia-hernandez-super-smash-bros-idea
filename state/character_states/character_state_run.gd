extends CharacterGroundMoveState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the run animation.
	_character.animator.play( 'run' );
	
	# Set this tier's target horizontal speed (used by the base class's physics_process).
	_speed = CharacterController.RUN_SPEED;

func process( delta: float ) -> void:
	var direction := _character.get_move_axis();
	
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	var magnitude := absf( direction );
	
	if magnitude < CharacterController.WALK_MAGNITUDE_THRESHOLD:
		state_machine.transition_to( 'CharacterStateWalk' );
		return;
	elif magnitude < CharacterController.RUN_MAGNITUDE_THRESHOLD:
		# Tilt eased off below full: drop back to Jog tier.
		state_machine.transition_to( 'CharacterStateJog' );
		return;
	
	super.process( delta );
