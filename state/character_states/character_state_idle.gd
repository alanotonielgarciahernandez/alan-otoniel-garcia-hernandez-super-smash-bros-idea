extends CharacterState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Play the idle animation.
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

func physics_process( delta: float ) -> void:
	# Apply gravity.
	_character.apply_gravity( delta );
	
	_character.move_and_slide();
