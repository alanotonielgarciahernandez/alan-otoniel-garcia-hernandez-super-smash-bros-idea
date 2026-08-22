extends State;

## Character Object reference.
var _character: CharacterController;

func start() -> void:
	_character = controlled_node;
	
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
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	var direction := Input.get_axis( 'move_left', 'move_right' );
	if direction != 0.0:
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
	else:
		state_machine.transition_to( 'CharacterStateIdle' );
	
	# Count character landing recovery.
	if _character.land_timer < CharacterController.LAND_TIME:
		_character.land_timer += _delta;
		return;
	
	state_machine.transition_to( 'CharacterStateIdle' );

func physics_process( _delta: float ) -> void:
	# Gravity + terminal velocity
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	_character.move_and_slide();
	
	# Safety: if we're no longer on the floor (e.g. pushed off a ledge during
	# landing recovery), fall instead of getting stuck in the land animation.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
