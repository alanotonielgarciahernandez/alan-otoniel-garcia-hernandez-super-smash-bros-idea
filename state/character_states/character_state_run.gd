# res://state/character_states/character_state_run.gd
# Dash-triggered grounded run state.
#
# It uses Run speed while stick tilt stays at full.
# It drops to Jog, Walk, or Idle when magnitude falls.

extends CharacterGroundMoveState;

func start() -> void:
	super.start();
	
	# Play the run animation.
	_character.animator.play( 'run' );
	
	# Set this tier's target horizontal speed.
	_speed = CharacterController.RUN_SPEED;
	
	# One-time dash burst in the current facing / input direction.
	var direction := _character.get_move_axis();
	if direction != 0.0:
		# Add burst on top of current velocity, clamped so it doesn't become extreme.
		_character.velocity.x += signf( direction ) * CharacterController.RUN_BURST_SPEED;

func process( delta: float ) -> void:
	var direction := _character.get_move_axis();
	var magnitude := absf( direction );
	
	# Stick eased below full tilt → drop to Jog (or Walk if almost neutral).
	if magnitude < CharacterController.RUN_MAGNITUDE_THRESHOLD:
		if magnitude < CharacterController.WALK_MAGNITUDE_THRESHOLD:
			state_machine.transition_to( 'CharacterStateWalk' );
		else:
			state_machine.transition_to( 'CharacterStateJog' );
		return;
	
	# Still fully tilted — stay in Run.
	super.process( delta );
