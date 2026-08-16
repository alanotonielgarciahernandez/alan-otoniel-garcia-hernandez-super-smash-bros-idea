class_name CharacterController;
extends CharacterBody2D;

## Walking Speed.
const WALK_SPEED: float = 200.0;

## Walking acceleration speed.
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0;

## Jump Velocity.
const JUMP_VELOCITY: float = -500.0;

## Maximum speed at which the player can fall.
const TERMINAL_VELOCITY: float = 220.0;

## Double jump availability indicator.
var _double_jump_charged: bool = false;


func _physics_process( delta: float ) -> void:
	if is_on_floor():
		# Recharge double jump when character is on floor.
		_double_jump_charged = true;
	if Input.is_action_just_pressed( 'jump' ):
		# Try jump.
		try_jump();
	elif Input.is_action_just_released( 'jump' ) and velocity.y < 0.0:
		# The player let go of jump early, reduce vertical momentum.
		velocity.y *= 0.6;
		
	# Fall.
	velocity.y = minf( TERMINAL_VELOCITY, velocity.y + get_gravity().y * delta )
	
	# Move.
	var direction := Input.get_axis( 'move_left', 'move_right' ) * WALK_SPEED
	velocity.x = move_toward(velocity.x, direction, ACCELERATION_SPEED * delta)
	
	move_and_slide()

func try_jump() -> void:
	if !is_on_floor():
		if _double_jump_charged:
			# Consume double jump.
			_double_jump_charged = false
		else:
			return;
	
	# Jump.
	velocity.y = JUMP_VELOCITY;
