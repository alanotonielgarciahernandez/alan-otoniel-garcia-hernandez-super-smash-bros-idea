class_name CharacterGroundMoveState;
extends State;

## Character Object reference.
var _character: CharacterController;

## Target horizontal speed for this tier — set by each subclass.
var _speed: float = 0.0;

func physics_process( _delta: float ) -> void:
	# Get horizontal input axis from the character's assigned device.
	var direction := _character.get_move_axis();
	
	# Flip sprite to face movement direction.
	if direction > 0.0:
		_character.animator.flip_h = false;
	elif direction < 0.0:
		_character.animator.flip_h = true;
	
	# Accelerate/decelerate horizontal velocity toward this tier's target speed.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		direction * _speed,
		CharacterController.ACCELERATION_SPEED * _delta
	);
	
	# Apply gravity for this frame.
	_character.apply_gravity( _delta );
	
	# Move the character and resolve collisions.
	_character.move_and_slide();
