extends CharacterGroundMoveState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the jog animation.
	_character.animator.play( 'jog' );
	
	# Set this tier's target horizontal speed (used by the base class's physics_process).
	_speed = CharacterController.JOG_SPEED;

func process( delta: float ) -> void:
	# Get horizontal input axis from the character's assigned device.
	var direction := _character.get_move_axis();
	
	# No input at all — drop to Idle.
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	# Get input magnitude regardless of direction sign.
	var magnitude := absf( direction );
	
	# Magnitude dropped below Jog's band — step down to Walk.
	if magnitude < CharacterController.WALK_MAGNITUDE_THRESHOLD:
		state_machine.transition_to( 'CharacterStateWalk' );
		return;
	
	# Still within Jog's magnitude band — check if this input counts as a dash.
	var target_state := _character.get_ground_move_state( direction );
	
	# Dash trigger fired — jump straight to Run.
	if target_state == 'CharacterStateRun':
		state_machine.transition_to( target_state );
		return;
	
	super.process( delta );
