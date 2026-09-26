# res://state/character_states/character_state_attack.gd
# Shared base for grounded attacks (jab, tilts, dash attack, etc.).
#
# Startup → enable hitbox → active → disable hitbox → endlag → Idle.
# Timing is counted in integer frames (design target 60 FPS).
# Hit detection, knockback, hitstun, and hitlag live on the victim / controller.

class_name CharacterStateAttack;
extends CharacterState;

## Frame data for this attack.
@export var move_data: MoveData;

## Hitbox used by this attack (assign the Area2D under Hitboxes).
@export var hitbox: Area2D;

## Phases of the attack.
enum Phase { STARTUP, ACTIVE, ENDLAG }

## Current phase of the attack.
var _phase: Phase = Phase.STARTUP;

## Remaining frames in the current phase.
var _frames_left: int = 0;


func start() -> void:
	# Run the base class's start() first to cache the character reference.
	super.start();
	
	# Safety: no data assigned — abort to Idle.
	if move_data == null:
		state_machine.transition_to( 'CharacterStateIdle' );
		return;
	
	# Play attack animation if it exists.
	if move_data.animation_name != '':
		_character.animator.play( move_data.animation_name );
	
	# Connect the hit signal once (safe to call repeatedly).
	if hitbox != null and not hitbox.area_entered.is_connected( _on_hitbox_area_entered ):
		hitbox.area_entered.connect( _on_hitbox_area_entered );
	
	# Start in startup with hitbox off.
	_phase = Phase.STARTUP;
	_frames_left = move_data.startup_frames;
	_set_hitbox_active( false );
	
	# Flip the hitbox to the character's current facing.
	_update_hitbox_facing();


func end() -> void:
	# Always turn the hitbox off when leaving this state.
	_set_hitbox_active( false );


func process( _delta: float ) -> void:
	# Optional: allow jump-cancel or other cancels later.
	pass;


func physics_process( delta: float ) -> void:
	# Keep grounded friction while attacking so residual momentum dies naturally.
	_character.velocity.x = move_toward(
		_character.velocity.x,
		0.0,
		CharacterController.GROUND_FRICTION * delta
	);
	
	# Apply gravity so the character stays planted / can fall off edges.
	_character.apply_gravity( delta );
	
	# Move the character.
	_character.move_and_slide();
	
	# Left the ground during the attack → transition to Fall.
	if not _character.is_on_floor():
		state_machine.transition_to( 'CharacterStateFall' );
		return;
	
	# Advance one design frame per physics tick.
	_frames_left -= 1;
	
	# Still frames left in this phase — nothing else to do.
	if _frames_left > 0:
		return;
	
	# Phase finished — advance to the next one.
	match _phase:
		Phase.STARTUP:
			# Startup over → enable hitbox and start active window.
			_phase = Phase.ACTIVE;
			_frames_left = move_data.active_frames;
			_set_hitbox_active( true );
			# Catch enemies already standing inside the hitbox.
			_hit_current_overlaps();
		Phase.ACTIVE:
			# Active over → disable hitbox and start endlag.
			_phase = Phase.ENDLAG;
			_frames_left = move_data.endlag_frames;
			_set_hitbox_active( false );
		Phase.ENDLAG:
			# Endlag over → return to Idle.
			state_machine.transition_to( 'CharacterStateIdle' );


## Enables or disables the attack hitbox (shape + monitoring).
func _set_hitbox_active( active: bool ) -> void:
	if hitbox == null:
		return;
	
	# Prefer disabling the shape so the Area2D stays easy to debug in the editor.
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.disabled = not active;
	
	# Also toggle monitoring so the area stops reporting when inactive.
	hitbox.monitoring = active;


## Flips the hitbox X position to match the character's current facing.
func _update_hitbox_facing() -> void:
	if hitbox == null:
		return;
	
	# Keep the absolute offset and apply facing sign.
	hitbox.position.x = absf( hitbox.position.x ) * _character.facing;


## Hits any Hurtbox already overlapping when the hitbox turns on.
## area_entered only fires on newly entering areas; this covers the rest.
func _hit_current_overlaps() -> void:
	if hitbox == null:
		return;
	
	for area in hitbox.get_overlapping_areas():
		_on_hitbox_area_entered( area );


## Called when the attack hitbox overlaps another Area2D.
func _on_hitbox_area_entered( area: Area2D ) -> void:
	# Only react to Hurtboxes.
	if area.name != 'Hurtbox':
		return;
	
	# Resolve the CharacterController that owns this hurtbox.
	var victim := area.get_parent() as CharacterController;
	
	# Ignore self-hits and non-character areas.
	if victim == null or victim == _character:
		return;
	
	# Apply the hit (damage + knockback + victim hitlag + hitstun).
	victim.apply_hit( move_data, _character.facing );
	
	# Freeze the attacker for the same hitlag window.
	_character.hitlag_frames = move_data.hitlag_frames;
