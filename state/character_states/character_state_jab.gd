# res://state/character_states/character_state_jab.gd
# Grounded jab attack.
#
# Startup → enable hitbox → active → disable hitbox → endlag → Idle.
# Hit detection and knockback will be wired once the hitbox reports a hit.

extends CharacterState;

## Frame data for this jab.
@export var move_data: MoveData;

## Hitbox used by this jab (assign the Area2D under Hitboxes).
@export var hitbox: Area2D;

## Phases of the attack.
enum Phase { STARTUP, ACTIVE, ENDLAG }

var _phase: Phase = Phase.STARTUP;
var _timer: float = 0.0;

func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Safety: no data assigned.
	if move_data == null:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	# Play attack animation if it exists.
	if move_data.animation_name != '':
		_character.animator.play( move_data.animation_name );
	
	# Start in startup with hitbox off.
	_phase = Phase.STARTUP;
	_timer = move_data.startup_time;
	_set_hitbox_active( false );

func end() -> void:
	# Always turn the hitbox off when leaving this state.
	_set_hitbox_active( false );

func process( _delta: float ) -> void:
	# Optional: allow jump-cancel later; keep empty for now.
	pass;

func physics_process( delta: float ) -> void:
	# Keep grounded friction / gravity while attacking.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		0.0,
		CharacterController.GROUND_FRICTION * delta
	);
	_character.apply_gravity( delta );
	_character.move_and_slide();
	
	# Left the ground during jab → fall.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;
	
	# Advance the current phase timer.
	_timer -= delta;
	
	if _timer > 0.0:
		return;
	
	# Phase finished — move to the next one.
	match _phase:
		Phase.STARTUP:
			_phase = Phase.ACTIVE;
			_timer = move_data.active_time;
			_set_hitbox_active( true );
		Phase.ACTIVE:
			_phase = Phase.ENDLAG;
			_timer = move_data.endlag_time;
			_set_hitbox_active( false );
		Phase.ENDLAG:
			state_machine.transition_to( 'CharacterStateIdle' );

func _set_hitbox_active( active: bool ) -> void:
	if hitbox == null:
		return;
	
	# Prefer disabling the shape so the Area2D stays easy to debug.
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.disabled = not active;
	
	hitbox.monitoring = active;
