extends State;

## Character Object reference.
var _character: CharacterController;

func start() -> void:
	_character = controlled_node;
	
	# Play fall animation.
	_character.animator.play( 'fall' );

func physics_process( _delta: float ) -> void:
	# Get move direction.
	var direction := _character.get_move_axis();
	
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
	
	# Double/extra jump (Jump state will consume a charge).
	if _character.is_jump_pressed() and _character.jumps_used < CharacterController.MAX_JUMPS:
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	_character.move_and_slide();
	
	# Landed.
	if _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateLand' );
