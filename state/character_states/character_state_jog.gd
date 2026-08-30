extends CharacterGroundMoveState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the jog animation.
	_character.animator.play( 'jog' );
	
	# Set this tier's target horizontal speed (used by the base class's physics_process).
	_speed = CharacterController.JOG_SPEED;
	
	# Consume a buffered jump input from just before entering jog.
	if _character.consume_buffered_input( 'jump' ):
		# A jump was queued — go straight to Jump instead of staying in Jog.
		state_machine.transition_to( 'CharacterStateJump' );
		return;

func process( _delta: float ) -> void:
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
	
	# Jump was pressed this frame — switch to Jump.
	if _character.is_jump_just_pressed():
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	# No longer on the floor (e.g. walked off a ledge) — switch to Fall.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;
