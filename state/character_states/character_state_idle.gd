extends State;

## Character Object reference.
var _character: CharacterController;

func start() -> void:
	_character = controlled_node;
	
	# Play idle animation.
	_character.animator.play( 'idle' );
	
	# Set horizontal velocity to 0.
	_character.velocity.x = 0.0;
	
	# Consume a buffered jump input from just before landing/entering idle.
	if _character.consume_buffered_input( 'jump' ):
		state_machine.transition_to( 'CharacterStateJump' );
		return;

func process( _delta: float ) -> void:
	var direction := _character.get_move_axis();
	
	if direction != 0.0:
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
		return;
	
	if _character.is_jump_just_pressed():
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;

func physics_process( _delta: float ) -> void:
	# Gravity + terminal velocity
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	_character.move_and_slide();
