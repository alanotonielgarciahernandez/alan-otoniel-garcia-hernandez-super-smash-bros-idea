# res://state/state_machine.gd
# Character states main controller.
#
# It handles state transitions by child node name.
# It forwards process, physics, and input to the current state.

class_name StateMachine;
extends Node;

## Node to control reference.
@onready var controlled_node = self.owner;

## Default state.
@export var initial_state: State;

## Current state.
var current_state: State = null;

func _ready() -> void:
	# Start State Machine, set default state as the current state when child States are ready.
	call_deferred( '_state_default_start' );

## Set default state as the current state and setup new state.
func _state_default_start() -> void:
	current_state = initial_state;
	
	_state_start();

## Setup new state.
func _state_start() -> void:
	# Print state for debug.
	prints( 'StateMachine', controlled_node.name, 'start state', current_state.name );
	
	# Pass state machine reference to new state.
	current_state.state_machine = self;
	
	# Execute start method.
	current_state.start();

#region Self-executed methods.

func _process( delta: float ) -> void:
	if current_state:
		current_state.process( delta );

func _physics_process( delta: float ) -> void:
	if current_state:
		current_state.physics_process( delta )

func _unhandled_input( event: InputEvent ) -> void:
	if current_state:
		current_state.handle_input( event )

#endregion

## Executes current state end method and changes to new state.
func transition_to( new_state: String ) -> void:
	# Skip no-op transitions so we don't restart the current state's animation.
	if current_state and current_state.name == new_state:
		return;
	
	# End the current state before switching, if one is active.
	if current_state:
		current_state.end();
	
	# Look up and assign the new state node.
	current_state = get_node( new_state );
	
	# Run shared startup logic for the new state.
	_state_start();
