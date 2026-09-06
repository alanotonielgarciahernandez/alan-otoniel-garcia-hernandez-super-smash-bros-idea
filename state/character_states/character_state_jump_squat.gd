# res://state/character_states/character_state_jump_squat.gd
# Grounded jumpsquat (jump prepare).
#
# Lasts a few frames while still on the floor.
# At the end it chooses short hop or full hop based on whether
# the jump button is still held — true Smash behaviour.

extends CharacterState;

var jump_squat_timer: float = 0.0;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Optional: play a jumpsquat / crouch animation if you have one.
	# _character.animator.play( 'jump_squat' );
	
	# Start the jumpsquat timer.
	jump_squat_timer = CharacterController.JUMP_SQUAT_TIME;

func process( _delta: float ) -> void:
	# Safety: if we somehow leave the floor during squat, go to Fall.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;

func physics_process( delta: float ) -> void:
	# Count down the jumpsquat.
	jump_squat_timer -= delta;
	
	# Apply gravity and friction while still grounded.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		0.0,
		CharacterController.GROUND_FRICTION * delta
	);
	_character.apply_gravity( delta );
	_character.move_and_slide();
	
	# Jumpsquat finished — decide hop type and leave the ground.
	if jump_squat_timer <= 0.0:
		_finish_jumpsquat();

func _finish_jumpsquat() -> void:
	# Consume one jump charge (this is a grounded jump).
	_character.jumps_used += 1;
	
	# Decide short hop vs full hop.
	# If the button is still held at the end of squat → full hop.
	# If the player already released → short hop.
	if _character.is_jump_pressed():
		_character.velocity.y = CharacterController.JUMP_VELOCITY;
	else:
		_character.velocity.y = CharacterController.SHORT_HOP_VELOCITY;
	
	# Go to the rising Jump state.
	state_machine.transition_to( 'CharacterStateJump' );
