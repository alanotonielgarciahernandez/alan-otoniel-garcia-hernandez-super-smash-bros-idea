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
	var direction := _character.get_move_axis();
	
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	var magnitude := absf( direction );
	
	if magnitude < CharacterController.WALK_MAGNITUDE_THRESHOLD:
		state_machine.transition_to( 'CharacterStateWalk' );
		return;
	
	# Still within Jog's magnitude band — check if this input counts as a dash.
	var target_state := _character.get_ground_move_state( direction );
	if target_state == 'CharacterStateRun':
		state_machine.transition_to( target_state );
		return;
	
	if _character.is_jump_just_pressed():
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;

func physics_process( _delta: float ) -> void:
	var direction := _character.get_move_axis();
	
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
