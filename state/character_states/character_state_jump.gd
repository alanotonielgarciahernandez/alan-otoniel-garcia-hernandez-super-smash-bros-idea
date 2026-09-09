# res://state/character_states/character_state_jump.gd
# Rising jump state.
#
# It spends a jump charge, including coyote time after leaving the floor.
# It nudges around ceiling corners before move_and_slide.

extends CharacterAirState;

## How many pixels left/right we are allowed to correct.
const CORNER_CORRECTION: float = 6.0;

func start() -> void:
	super.start();
	
	# Any new jump cancels fast-fall.
	_character.is_fast_falling = false;
	
	_character.animator.play( 'jump' );
	
	# Only consume / set velocity when this is an aerial jump
	# (grounded jumps already did it in JumpSquat).
	if not _character.is_on_floor():
		# Coyote / double jump handling (keep your existing logic).
		if _character.falling_timer >= CharacterController.COYOTE_TIME and _character.jumps_used == 0:
			_character.jumps_used = 1;
		
		_character.jumps_used += 1;
		_character.velocity.y = CharacterController.JUMP_VELOCITY;

func physics_process( delta: float ) -> void:
	super.physics_process( delta );
	
	# Inside Jump.physics_process, after the hold/cut logic or near the top
	if _character.is_jump_just_pressed() and _character.jumps_used < CharacterController.MAX_JUMPS:
		state_machine.transition_to( 'CharacterStateJump', true );
		return;
	
	# Safety: if we somehow start falling while still in Jump, change state to Fall.
	if _character.velocity.y > 0.0:
		state_machine.transition_to( 'CharacterStateFall' );
		return;
	
	_try_corner_correction();
	
	# Check for landing only after this frame's collision is resolved.
	_check_landed();


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
