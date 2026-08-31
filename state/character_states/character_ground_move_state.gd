class_name CharacterGroundMoveState;
extends CharacterState;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Consume a buffered jump input from just before entering jog.
	if _character.consume_buffered_input( 'jump' ):
		# A jump was queued — go straight to Jump instead of staying in Jog.
		state_machine.transition_to( 'CharacterStateJump' );
		return;

## Target horizontal speed for this tier — set by each subclass.
var _speed: float = 0.0;


func process( _delta: float ) -> void:
	# Jump was pressed this frame — switch to Jump.
	if _character.is_jump_just_pressed():
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	# No longer on the floor (e.g. walked off a ledge) — switch to Fall.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;

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
