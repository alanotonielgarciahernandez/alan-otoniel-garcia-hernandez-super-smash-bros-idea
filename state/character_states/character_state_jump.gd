extends State;

## Character Object reference.
var _character: CharacterBody2D;

func start() -> void:
	_character = controlled_node;
	
	# TODO: Play jump animation.
	
	# Consume double jump if we are in the air.
	if not _character.is_on_floor():
		_character.double_jump_charged = false;
	
	# Jump.
	_character.velocity.y = CharacterController.JUMP_VELOCITY;
	
	# Setup jump hold timer.
	_character.jump_hold_timer = CharacterController.JUMP_HOLD_TIME;

func physics_process( _delta: float ) -> void:
	# Get move direction.
	var direction := Input.get_axis( 'move_left', 'move_right' );
	
	# Move.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * CharacterController.WALK_SPEED,
		CharacterController.ACCELERATION_SPEED * _delta
	);

	# Keep applying upward velocity while the button is held.
	# This makes the _character continue trying to go up even if it hits a ceiling.
	if Input.is_action_pressed( 'jump' ) and _character.jump_hold_timer > 0.0:
		# Jump.
		_character.velocity.y = CharacterController.JUMP_VELOCITY;
		
		# Consume jump hold timer.
		_character.jump_hold_timer -= _delta;
	else:
		# Button released early → cut vertical momentum.
		if _character.velocity.y < 0.0:
			_character.velocity.y *= CharacterController.JUMP_CUT_MULTIPLIER;
		
		# Change state to Fall.
		state_machine.transition_to( 'CharacterStateFall' );
		return;

	# Safety: if we somehow start falling while still in Jump, change state to Fall.
	if _character.velocity.y > 0.0:
		state_machine.transition_to( 'CharacterStateFall' );
		return;
	
	_character.move_and_slide();

	# Landed (rare, but possible with very short jumps)
	if _character.is_on_floor():
		_land();

func _land() -> void:
	# Recharge double jump.
	_character.double_jump_charged = true;
	
	if Input.get_axis( 'move_left', 'move_right' ) != 0.0:
		# Change state to Run if player keeps moving.
		state_machine.transition_to( 'CharacterStateRun' );
	else:
		state_machine.transition_to( 'CharacterStateIdle' );
