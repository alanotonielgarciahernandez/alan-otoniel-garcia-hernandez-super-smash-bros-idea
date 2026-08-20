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

func process( _delta: float ) -> void:
	# Count character landing recovery.
	if _character.land_timer < CharacterController.LAND_TIME:
		_character.land_timer += _delta;
		return;
	
	# Reset land timer after recovering.
	_character.land_timer = 0;
	
	# Consume a buffered jump input pressed just before landing.
	if _character.consume_buffered_input( 'jump' ):
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	if Input.get_axis( 'move_left', 'move_right' ) != 0.0:
		# Change state to Run if player keeps moving.
		state_machine.transition_to( 'CharacterStateRun' );
	else:
		state_machine.transition_to( 'CharacterStateIdle' );

func physics_process( _delta: float ) -> void:
	# Gravity + terminal velocity
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	_character.move_and_slide();
