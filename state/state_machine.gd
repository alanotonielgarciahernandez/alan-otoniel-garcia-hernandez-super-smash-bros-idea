# res://state/state_machine.gd
# Character states main controller.
#
# It handles state transitions by child node name.
# It forwards process, physics, and input to the current state.
# Hitlag freezes those calls for the full hitlag_frames count.

class_name StateMachine;
extends Node;

## Node to control reference.
@onready var controlled_node = self.owner;

## Default state.
@export var initial_state: State;

## Current state.
var current_state: State = null;

## True while a transition is already swapping states.
## A nested transition_to() is queued until the outer one finishes.
var _changing_state: bool = false;

## State name requested by a nested transition_to(). Empty means nothing is queued.
var _queued_state: String = '';

## Force flag that belongs to _queued_state.
var _queued_force: bool = false;

## Animator speed_scale saved when hitlag began, restored when the freeze ends.
var _animation_speed_before_hitlag: float = 1.0;

## True after this machine has zeroed the animator for the current hitlag.
var _animation_frozen: bool = false;


func _ready() -> void:
	# Child state nodes are already ready, so the first frame can run the initial state.
	_state_default_start();

## Set default state as the current state and setup new state.
func _state_default_start() -> void:
	# An empty export would crash on the first start() call.
	if initial_state == null:
		push_error( 'StateMachine is missing an initial state.' );
		return;
	
	current_state = initial_state;
	
	_state_start();

## Setup new state.
func _state_start() -> void:
	# Pass state machine reference to new state.
	current_state.state_machine = self;
	
	# Execute start method.
	current_state.start();

#region Self-executed methods.

func _process( delta: float ) -> void:
	# Hold the sprite on the frame it had when the hit connected.
	_sync_hitlag_animation();
	
	# Skip the state while frozen. The press edge still has to expire below.
	if not _in_hitlag() and current_state:
		current_state.process( delta );
	
	# One idle frame may read a press. Later idle frames must not see it again.
	var character := _controlled_character();
	if character:
		character.expire_just_pressed();

func _physics_process( delta: float ) -> void:
	# Skip while the controlled character is in hitlag.
	# Hitstun and attack timers only count after the freeze ends.
	if _in_hitlag():
		# Count this frozen physics frame. The body used to decrement first,
		# so the machine woke up one frame before the move's hitlag value.
		( controlled_node as CharacterController ).hitlag_frames -= 1;
		return;
	
	if current_state:
		current_state.physics_process( delta );

func _unhandled_input( event: InputEvent ) -> void:
	# The character still buffers the press. The state itself must not act during the freeze.
	if _in_hitlag():
		return;
	
	if current_state:
		current_state.handle_input( event );

#endregion

## Executes current state end method and changes to new state.
func transition_to( new_state: String, force: bool = false ) -> void:
	# A start() or end() asked for another state. Run it after the outer swap finishes.
	if _changing_state:
		_queued_state = new_state;
		_queued_force = force;
		return;
	
	_changing_state = true;
	_apply_transition( new_state, force );
	
	# Drain states that start() requested, one at a time.
	while _queued_state != '':
		var next_state := _queued_state;
		var next_force := _queued_force;
		
		# Clear before applying so a further nest can queue again.
		_queued_state = '';
		_queued_force = false;
		
		_apply_transition( next_state, next_force );
	
	_changing_state = false;

## Swap to new_state unless this is a no-op or the node is missing.
func _apply_transition( new_state: String, force: bool ) -> void:
	# Skip no-op transitions if not forcing, so we don't restart the current state's animation.
	if current_state and current_state.name == new_state and not force:
		return;
	
	var next_state := get_node_or_null( new_state ) as State;
	
	# Keep the current state when the name is wrong.
	if next_state == null:
		push_error( 'StateMachine could not find state: ' + new_state );
		return;
	
	# End the current state before switching, if one is active.
	if current_state:
		current_state.end();
	
	# Assign the state node we already resolved.
	current_state = next_state;
	
	# Run shared startup logic for the new state.
	_state_start();

## Character this machine controls, or null when the owner is not a fighter.
func _controlled_character() -> CharacterController:
	return controlled_node as CharacterController;

## True while the fighter still has hitlag frames left this physics frame.
func _in_hitlag() -> bool:
	var character := _controlled_character();
	
	return character != null and character.hitlag_frames > 0;

## Freeze the character sprite for hitlag, then give it its previous speed back.
func _sync_hitlag_animation() -> void:
	var character := _controlled_character();
	
	if character == null or character.animator == null:
		return;
	
	if _in_hitlag():
		# Remember the speed once, so a later resume does not force 1.0 over a real scale.
		if not _animation_frozen:
			_animation_speed_before_hitlag = character.animator.speed_scale;
			character.animator.speed_scale = 0.0;
			_animation_frozen = true;
		return;
	
	# Freeze ended — put the animator back to the speed it had before the hit.
	if _animation_frozen:
		character.animator.speed_scale = _animation_speed_before_hitlag;
		_animation_frozen = false;
