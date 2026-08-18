extends State;

## Character Object reference.
var _character: CharacterController;

## How many pixels left/right we are allowed to correct (Smash-style is usually 4–8 px)
const CORNER_CORRECTION: float = 6.0;


func start() -> void:
	_character = controlled_node;
	
	# TODO: Play jump animation.
	
	# Consume double jump if we are in the air and coyote time has passed.
	if not _character.is_on_floor() and _character.falling_timer >= CharacterController.COYOTE_TIME:
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
		
	_try_corner_correction();
	
	_character.move_and_slide();

	# Landed (rare, but possible with very short jumps)
	if _character.is_on_floor():
		_land();


func _try_corner_correction() -> void:
	# Only when we are still trying to go up
	if _character.velocity.y >= 0.0:
		return;

	var delta := get_physics_process_delta_time();
	var motion := Vector2( 0.0, _character.velocity.y * delta );

	# If we would not hit a ceiling, nothing to do
	if not _character.test_move( _character.global_transform, motion ):
		return;

	# Try small horizontal offsets
	for i in range( 1, int( CORNER_CORRECTION ) + 1 ):
		for direction in [ -1.0, 1.0 ]:
			var offset := Vector2( i * direction, 0.0 );
			var test_transform := _character.global_transform.translated( offset );

			# If this offset lets us move upward freely → apply it
			if not _character.test_move( test_transform, motion ):
				_character.global_position += offset;
				return;

func _land() -> void:
	# Recharge double jump.
	_character.double_jump_charged = true;
	
	if Input.get_axis( 'move_left', 'move_right' ) != 0.0:
		# Change state to Run if player keeps moving.
		state_machine.transition_to( 'CharacterStateRun' );
	else:
		state_machine.transition_to( 'CharacterStateIdle' );
