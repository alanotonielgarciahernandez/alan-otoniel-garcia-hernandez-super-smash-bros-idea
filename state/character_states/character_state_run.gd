# res://state/character_states/character_state_run.gd
# Dash-triggered grounded run state.
#
# It uses Run speed while stick tilt stays at full.
# It drops to Jog, Walk, or Idle when magnitude falls.

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
