extends State;

## Character Object reference.
var _character: CharacterController;

func start() -> void:
	_character = controlled_node;
	
	# Play walk animation.
	_character.animator.play( 'walk' );
	
	# Consume a buffered jump input from just before entering walk.
	if _character.consume_buffered_input( 'jump' ):
		state_machine.transition_to( 'CharacterStateJump' );
		return;

func process( _delta: float ) -> void:
	var direction := _character.get_move_axis();
	
	if direction == 0.0:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	var magnitude := absf( direction );
	
	if magnitude >= CharacterController.WALK_MAGNITUDE_THRESHOLD:
		# Re-evaluate tier (may go to Jog or straight to Run on a dash).
		state_machine.transition_to( _character.get_ground_move_state( direction ) );
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
	
	# Move — direction already scales speed continuously within Walk's magnitude band.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * CharacterController.WALK_SPEED,
		CharacterController.ACCELERATION_SPEED * _delta
	);
	
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	_character.move_and_slide();
