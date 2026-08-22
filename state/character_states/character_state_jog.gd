extends State;

## Character Object reference.
var _character: CharacterController;

func start() -> void:
	_character = controlled_node;
	
	# Play jog animation.
	_character.animator.play( 'jog' );
	
	# Consume a buffered jump input from just before entering jog.
	if _character.consume_buffered_input( 'jump' ):
		state_machine.transition_to( 'CharacterStateJump' );
		return;

func process( _delta: float ) -> void:
	var direction := Input.get_axis( 'move_left', 'move_right' );
	
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	var magnitude := absf( direction );
	
	# Check for a dash trigger (analog flick, or keyboard double-tap re-press).
	if _character.consume_dash_trigger( magnitude ):
		state_machine.transition_to( 'CharacterStateRun' );
		return;
	
	if magnitude < CharacterController.WALK_MAGNITUDE_THRESHOLD:
		state_machine.transition_to( 'CharacterStateWalk' );
		return;
	
	if Input.is_action_just_pressed( 'jump' ):
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;

func physics_process( _delta: float ) -> void:
	var direction := Input.get_axis( 'move_left', 'move_right' );
	
	if direction > 0.0:
		_character.animator.flip_h = false;
	elif direction < 0.0:
		_character.animator.flip_h = true;
	
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * CharacterController.JOG_SPEED,
		CharacterController.ACCELERATION_SPEED * _delta
	);
	
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	_character.move_and_slide();
