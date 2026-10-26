# res://characters/character_controller.gd
# Main character controller.
#
# It binds one input device to this character.
# It buffers jump input and reads movement stats from CharacterData.
# It applies gravity and picks the grounded movement tier.

class_name CharacterController;
extends CharacterBody2D;

#region Input related constants.

## Frame window an input remains "buffered" before it's considered stale.
const INPUT_BUFFER_WINDOW: int = 9;

## Analog magnitude below which movement counts as Walk instead of Jog.
const WALK_MAGNITUDE_THRESHOLD: float = 0.5;

## Magnitude considered "full tilt" — required (plus a dash trigger) to enter Run.
const RUN_MAGNITUDE_THRESHOLD: float = 0.9;

## Stick tilt that counts as a direction for fast-fall, aerials, and tilts.
const STICK_TILT_THRESHOLD: float = 0.5;

#endregion

## Frames allowed to still ground-jump after leaving the floor.
const COYOTE_FRAMES: int = 7;

## Multiplier so knockback magnitudes match jump / run scale.
const KNOCKBACK_SCALE: float = 4.5;

## Hitstun frames added per point of Smash knockback, before pixel scaling.
const HITSTUN_PER_KNOCKBACK: float = 0.54;

## Hitstun frames every hit starts with, before knockback adds more.
const HITSTUN_BASE_FRAMES: int = 8;

## Damage percent cap. Matches the usual Smash display limit.
const MAX_PERCENT: float = 999.0;


## Device controlling this character. -1 = keyboard. 0+ = joypad index,
## matching Input.get_connected_joypads().
@export var device_id: int = -1;

## Per-fighter speeds, traction, and action frame data.
@export var character_data: CharacterData;

## Character State Machine object reference.
@export var state_machine: StateMachine;

## Character Animator object reference.
@export var animator: AnimatedSprite2D;

## Character Hitbox container object reference.
@export var hitbox_container: Node2D;

## Percent label above the character.
@export var percent_label: Label;


## Device-specific input reader, created once in _ready() based on device_id.
## Never re-evaluated afterward — this character always listens to only this device.
var _input_reader: InputReader;

#region Control variables.

## action_name -> remaining frames the buffer is still valid.
## 0 or missing = not buffered / expired.
var _buffered_inputs: Dictionary = {};

## Actions buffered since the last tick. Those skip one countdown so the
## press frame still counts as part of INPUT_BUFFER_WINDOW.
var _fresh_buffers: Dictionary = {};

## Number of jumps performed since the character was last on the floor.
var jumps_used: int = 0;

## Frame count that keeps track of the amount of how long character has been in air.
var falling_frames: int = 0;

## Whether the character is currently fast-falling.
var is_fast_falling: bool = false;

## Frame count that keeps track of the amount of how long character has been recovering from falling.
var land_frames: int = 0;

## Current damage percent. Starts at 0.
var percent: float = 0.0;

## Frames of hitstun remaining after being hit. Read by CharacterStateHitstun.
var hitstun_frames: int = 0;

## Frames of hitlag remaining. While > 0 the character is frozen.
var hitlag_frames: int = 0;

## Frames of respawn invulnerability remaining.
## While > 0 this character cannot be KO'd by leaving the safe zone.
var invuln_frames: int = 0;

## Horizontal facing. +1 = right, -1 = left.
## Source of truth for hitboxes, launch direction, and sprite flip.
var facing: float = 1.0;

#endregion


func _ready() -> void:
	@warning_ignore( 'incompatible_ternary' )
	# Assign the input reader matching this character's device, once.
	_input_reader = KeyboardInputReader.new() if device_id == -1 else JoypadInputReader.new( device_id );
	
	# A key held as the match starts is not a just-pressed.
	_input_reader.prime_held_actions();
	
	# Scale the hitbox container to the facing direction.
	if hitbox_container:
		hitbox_container.scale.x = facing;
	
	# Movement reads this resource every frame, so a missing assignment should fail here.
	if character_data == null:
		push_error( 'CharacterController is missing a CharacterData resource.' );
	
	_update_percent_label();

func _physics_process( _delta: float ) -> void:
	# Count down respawn invulnerability every physics frame (including during hitlag).
	if invuln_frames > 0:
		invuln_frames -= 1;
	
	# Keep recording input during hitlag. States stay frozen, but a tap still lands in the buffer.
	_tick_input_buffers();
	_input_reader.update();
	
	# Hitlag freeze — skip movement clocks while frozen.
	# The state machine counts the frames down after it has skipped that frame.
	if hitlag_frames > 0:
		return;
	
	# Falling frames reset if character is on floor.
	if is_on_floor():
		falling_frames = 0;
	else:
		falling_frames += 1;

func _unhandled_input( event: InputEvent ) -> void:
	# Press order has to land before the axis is read, including during hitlag.
	_input_reader.note_input_event( event );
	
	# Buffer jump the instant it's pressed, including during hitlag.
	if _input_reader.is_action_press_event( 'jump', event ):
		buffer_input( 'jump' );
		# This event arrives before the physics tick, so that tick must not consume the press frame.
		_fresh_buffers[ 'jump' ] = true;
	
	# Buffer attack the same way, so a tap inside hitlag is still there when the character can act.
	if _input_reader.is_action_press_event( 'attack', event ):
		buffer_input( 'attack' );
		_fresh_buffers[ 'attack' ] = true;

#region Input related functions.

## Whether the down direction is pressed past a threshold on this device.
func is_down_pressed() -> bool:
	return _input_reader.get_vertical_axis() > STICK_TILT_THRESHOLD;

## Whether jump was pressed this frame, from this character's assigned device only.
func is_jump_just_pressed() -> bool:
	return _input_reader.is_action_just_pressed( 'jump' );

## Whether jump is currently held, from this character's assigned device only.
func is_jump_pressed() -> bool:
	return _input_reader.is_action_pressed( 'jump' );

## Whether attack was pressed this frame, from this character's assigned device only.
func is_attack_just_pressed() -> bool:
	return _input_reader.is_action_just_pressed( 'attack' );

## Whether attack is currently held, from this character's assigned device only.
func is_attack_pressed() -> bool:
	return _input_reader.is_action_pressed( 'attack' );

## True once when attack was just pressed or is still sitting in the buffer.
## Clears the buffer either way so the same press cannot start two attacks.
func consume_attack_input() -> bool:
	var pressed := is_attack_just_pressed();
	
	# Drop a stored press so a later state does not fire it again.
	var buffered := consume_buffered_input( 'attack' );
	
	return pressed or buffered;

## Returns this character's horizontal input axis, from its assigned device only.
func get_move_axis() -> float:
	return _input_reader.get_move_axis();

## Returns this character's vertical input axis, from its assigned device only.
func get_vertical_axis() -> float:
	return _input_reader.get_vertical_axis();

## Drops press edges the states did not read this idle frame.
func expire_just_pressed() -> void:
	_input_reader.expire_just_pressed();

## Returns the grounded movement state to enter for the given horizontal
## input — used when starting fresh movement (from Idle or on landing).
func get_ground_move_state( direction: float ) -> String:
	var magnitude := absf( direction );
	
	if magnitude == 0.0:
		return 'CharacterStateIdle';
	
	# Full tilt inside an open dash window. The reader only times the window.
	if magnitude >= RUN_MAGNITUDE_THRESHOLD and _input_reader.consume_dash_trigger():
		return 'CharacterStateRun';
	
	if magnitude < WALK_MAGNITUDE_THRESHOLD:
		return 'CharacterStateWalk';
	
	return 'CharacterStateJog';

## Buffers an action so a state can consume it shortly after, even if pressed too early.
## Resets the window to the full duration every time the action is pressed.
func buffer_input( action: String ) -> void:
	# Store remaining frames for this action (overwrites any previous buffer).
	_buffered_inputs[ action ] = INPUT_BUFFER_WINDOW;

## Checks if an action is still buffered (remaining frames > 0) and consumes it if so.
## Always erases the entry so a stale buffer can never be read twice.
func consume_buffered_input( action: String ) -> bool:
	# No buffered entry for this action.
	if not _buffered_inputs.has( action ):
		return false;
	
	# How many frames are still left on this buffer.
	var remaining: int = _buffered_inputs[ action ];
	
	# Always consume (erase) on check to avoid stale reads later.
	_buffered_inputs.erase( action );
	_fresh_buffers.erase( action );
	
	# Valid only if at least one frame remained.
	return remaining > 0;

## Clears a specific buffered action without consuming it (e.g. on cancel conditions).
func clear_buffered_input( action: String ) -> void:
	_buffered_inputs.erase( action );
	_fresh_buffers.erase( action );

## Counts every active input buffer down by one frame.
## Call this once per physics frame from _physics_process.
func _tick_input_buffers() -> void:
	# Collect keys first so we can safely erase while iterating.
	var expired: Array[ String ] = [];
	
	for action in _buffered_inputs:
		# Leave a same-frame press at the full window so 9 means 9 readable frames.
		if _fresh_buffers.has( action ):
			continue;
		
		_buffered_inputs[ action ] -= 1;
		
		# Mark for removal once the window has fully expired.
		if _buffered_inputs[ action ] <= 0:
			expired.append( action );
	
	# Fresh flags only protect the frame they were set.
	_fresh_buffers.clear();
	
	# Erase expired buffers after the loop.
	for action in expired:
		_buffered_inputs.erase( action );

#endregion

#region Movement related functions.

## Resets the jump counter. Called explicitly by states once a landing is confirmed.
func recharge_jumps() -> void:
	jumps_used = 0;

## Applies gravity to vertical velocity.
## Controllable falls clamp to terminal or fast-fall speed. Hitstun does not.
func apply_gravity( delta: float ) -> void:
	# No stats assigned — skip rather than crash on the next physics frame.
	if character_data == null:
		return;
	
	var gravity_step := get_gravity().y * delta;
	
	# Hitstun keeps the launch. The fall cap is only for a controllable fall.
	if hitstun_frames > 0:
		velocity.y += gravity_step;
		return;
	
	var max_fall: float = character_data.FAST_FALL_SPEED if is_fast_falling else character_data.TERMINAL_SPEED;
	velocity.y = minf( max_fall, velocity.y + gravity_step );

## Sets facing from a horizontal input or explicit sign.
## Also syncs the animator so the sprite matches.
func set_facing( direction: float ) -> void:
	# Ignore neutral — keep current facing.
	if direction == 0.0:
		return;
	
	# Store sign only (+1 or -1).
	facing = signf( direction );
	
	# flip_h true = looking left.
	if animator:
		animator.flip_h = facing < 0.0;
	
	if hitbox_container:
		hitbox_container.scale.x = facing;

#endregion

func get_aerial_attack_state() -> String:
	var h_direction := get_move_axis();
	var v_direction := get_vertical_axis();
	
	if v_direction < -STICK_TILT_THRESHOLD:
		return 'CharacterStateUpAerial';
	elif v_direction > STICK_TILT_THRESHOLD:
		return 'CharacterStateDownAerial';
	elif absf( h_direction ) > STICK_TILT_THRESHOLD:
		if signf( h_direction ) == facing:
			return 'CharacterStateForwardAerial';
		return 'CharacterStateBackwardAerial';
	return 'CharacterStateNeutralAerial';

## Applies a hit from a MoveData resource.
## Adds percent, calculates simplified knockback, and launches the character.
## attacker_facing: +1 = right, -1 = left.
func apply_hit( move: MoveData, attacker_facing: float = 1.0 ) -> void:
	# Safety.
	if move == null:
		return;
	
	# Respawn invulnerability blocks damage the same way it blocks blastzone KOs.
	if is_invulnerable():
		return;
	
	# Add damage percent, capped at the Smash display limit.
	percent = minf( percent + move.damage, MAX_PERCENT );
	
	_update_percent_label();
	
	# Smash knockback amount, then the pixel-speed conversion.
	var smash_kb: float = move.base_knockback + ( percent * move.knockback_growth * 0.01 );
	var kb: float = smash_kb * KNOCKBACK_SCALE;
	
	# Launch direction from angle (0° = forward, 90° = straight up).
	var rad: float = deg_to_rad( move.angle_degrees );
	var launch_facing: float = attacker_facing * move.knockback_direction;
	var dir := Vector2( cos( rad ) * launch_facing, -sin( rad ) );
	
	# Apply launch velocity (overwrite current velocity — classic early fighter behaviour).
	velocity = dir * kb;
	
	# Cancel fast-fall on hit.
	is_fast_falling = false;
	
	# Stun follows the Smash knockback amount, so the pixel scale does not change it.
	hitstun_frames = HITSTUN_BASE_FRAMES + int( smash_kb * HITSTUN_PER_KNOCKBACK );
	
	# Freeze this character (the victim) for the move's hitlag window.
	hitlag_frames = move.hitlag_frames;
	
	# Force the character into Hitstun so they cannot act immediately.
	if state_machine:
		state_machine.transition_to( 'CharacterStateHitstun' );
	
	# TODO next:
	# - Spawn hit spark / SFX

## True while respawn invulnerability is active.
func is_invulnerable() -> bool:
	# Any positive frame count means the character cannot be KO'd.
	return invuln_frames > 0;


## Clears combat state and returns the character to Idle after a KO / respawn.
## MatchController teleports the body and sets invuln_frames after calling this.
func reset_for_respawn() -> void:
	# Wipe damage so the next life starts clean.
	percent = 0.0;
	
	# Stop all motion.
	velocity = Vector2.ZERO;
	
	# Clear hit reactions.
	hitstun_frames = 0;
	hitlag_frames = 0;
	
	# Clear movement helpers that would otherwise carry over.
	is_fast_falling = false;
	falling_frames = 0;
	land_frames = 0;
	jumps_used = 0;
	
	# Drop any buffered inputs so nothing fires on the first frame of the new life.
	_buffered_inputs.clear();
	_fresh_buffers.clear();
	
	# Refresh the percent UI.
	_update_percent_label();
	
	# Force Idle so the state machine is not stuck in Hitstun / Fall / Attack.
	if state_machine:
		state_machine.transition_to( 'CharacterStateIdle', true );


## Refreshes the on-character percent text.
func _update_percent_label() -> void:
	if percent_label == null:
		return;
	
	# Whole number, matching the Smash percent display.
	percent_label.text = str( int( percent ) ) + '%';
