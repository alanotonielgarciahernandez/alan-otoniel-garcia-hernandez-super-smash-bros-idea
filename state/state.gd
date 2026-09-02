# state.gd
# State base class.

class_name State;
extends Node;

## Node to control reference.
@onready var controlled_node: Node = self.owner;

## State machine reference.
var state_machine: StateMachine;

## Method used at the start of the state.
func start() -> void:
	pass;

## Method used at the end of the state.
func end() -> void:
	pass;

## Method used every frame.
func process( _delta: float ) -> void:
	pass;

## Method used every frame of physics.
func physics_process( _delta: float ) -> void:
	pass;

## Method used on every input event.
func handle_input( _event: InputEvent ) -> void:
	pass;
