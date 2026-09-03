# res://state/character_states/character_state_walk.gd
# Slow analog walk state.
#
# It uses Walk speed for partial stick tilt.
# It steps up to Jog or Run when magnitude leaves the walk band.

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
	var magnitude := absf( direction );
	
	# Stick pushed past walk threshold → re-evaluate (may become Jog or Run).
	if magnitude >= CharacterController.WALK_MAGNITUDE_THRESHOLD:
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
		return;
	
	super.process( delta );
