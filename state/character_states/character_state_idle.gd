extends State;

## Character Object reference.
var _character: CharacterBody2D;

func start() -> void:
	_character = controlled_node;
	
	# TODO: Play idle animation.
	_character.velocity.x = 0.0;

func process( _delta: float ) -> void:
	var direction := Input.get_axis( 'move_left', 'move_right' );
	
	if direction != 0.0:
		state_machine.transition_to( 'CharacterStateRun' );
		return;
	
	if Input.is_action_just_pressed( 'jump' ):
		state_machine.transition_to( 'CharacterStateJump' );
		return;
	
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;

func physics_process( _delta: float ) -> void:
	# Gravity + terminal velocity
	_character.velocity.y = minf(
		CharacterController.TERMINAL_VELOCITY,
		_character.velocity.y + _character.get_gravity().y * _delta
	);
	
	_character.move_and_slide();
