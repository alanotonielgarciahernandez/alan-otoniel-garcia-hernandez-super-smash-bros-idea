extends State;

## Character Object reference.
var _character: CharacterBody2D;

func start() -> void:
	_character = controlled_node;
	
	# TODO: Play fall animation.

func physics_process( _delta: float ) -> void:
	# Get move direction.
	var direction := Input.get_axis( 'move_left', 'move_right' );
	
	# Move.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * CharacterController.WALK_SPEED,
		CharacterController.ACCELERATION_SPEED * _delta
	);
	
	# Gravity + terminal velocity.
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	# Double jump (Jump state will consume flag).
	if Input.is_action_just_pressed( 'jump' ) and _character.double_jump_charged:
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	_character.move_and_slide();
	
	# Landed.
	if _character.is_on_floor():
		# Recharge double jump.
		_character.double_jump_charged = true;
		
		if direction != 0.0:
			# Change state to Run if player keeps moving.
			state_machine.transition_to( 'CharacterStateRun' );
		else:
			state_machine.transition_to( 'CharacterStateIdle' );
