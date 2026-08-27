extends State;

## Character Object reference.
var _character: CharacterController;

## How many pixels left/right we are allowed to correct.
const CORNER_CORRECTION: float = 6.0;


func start() -> void:
	_character = controlled_node;
	
	# Play jump animation.
	_character.animator.play( 'jump' );
	
	# If we're past the Coyote Time window and haven't jumped yet, the free
	# ground jump chance is gone — this jump must consume the first charge.
	if not _character.is_on_floor() and _character.falling_timer >= CharacterController.COYOTE_TIME and _character.jumps_used == 0:
		_character.jumps_used = 1;
	
	# Consume a jump for this jump action.
	_character.jumps_used += 1;
	
	# Jump.
	_character.velocity.y = CharacterController.JUMP_VELOCITY;
	
	# Setup jump hold timer.
	_character.jump_hold_timer = CharacterController.JUMP_HOLD_TIME;

func physics_process( _delta: float ) -> void:
	# Get move direction.
	var direction := _character.get_move_axis();
	
	# Move.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * CharacterController.AIR_SPEED,
		CharacterController.ACCELERATION_SPEED * _delta
	);

	# Keep applying upward velocity while the button is held.
	# This makes the _character continue trying to go up even if it hits a ceiling.
	if _character.is_jump_pressed() and _character.jump_hold_timer > 0.0:
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

	# Landed.
	if _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateLand' );


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
