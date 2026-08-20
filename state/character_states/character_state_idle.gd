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
	var direction := Input.get_axis( 'move_left', 'move_right' );
	
	if direction != 0.0:
		state_machine.transition_to( 'CharacterStateRun' );
		return;
	
	if Input.is_action_just_pressed( 'jump' ):
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
