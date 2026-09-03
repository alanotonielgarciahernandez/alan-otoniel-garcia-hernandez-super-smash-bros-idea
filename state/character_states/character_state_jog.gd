# res://state/character_states/character_state_jog.gd
# Default grounded movement state.
#
# It uses Jog speed for full tilt without a dash.
# It steps down to Walk, up to Run on a dash trigger, or back to Idle.

extends CharacterGroundMoveState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the jog animation.
	_character.animator.play( 'jog' );
	
	# Set this tier's target horizontal speed (used by the base class's physics_process).
	_speed = CharacterController.JOG_SPEED;

func process( delta: float ) -> void:
	var direction := _character.get_move_axis();
	var magnitude := absf( direction );
	
	# Stick eased below walk threshold → Walk.
	if magnitude < CharacterController.WALK_MAGNITUDE_THRESHOLD:
		state_machine.transition_to( 'CharacterStateWalk' );
		return;
	
	# Check for a fresh dash trigger → Run.
	var target := _character.get_ground_move_state( direction );
	if target == 'CharacterStateRun':
		state_machine.transition_to( target );
		return;
	
	super.process( delta );
