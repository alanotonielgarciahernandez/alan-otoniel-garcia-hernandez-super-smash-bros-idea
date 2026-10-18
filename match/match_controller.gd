# res://match/match_controller.gd
# Owns stocks, KO detection, respawn, and match-end checks.
#
# SafeZone only detects exits; this node decides whether a body is KO'd.
# Characters own their own combat body and reset_for_respawn() helper.

class_name MatchController;
extends Node;

#region Match constants (tune later).

## Stocks each player starts with.
const DEFAULT_STOCKS: int = 3;

## Frames of invulnerability granted on respawn (~1.5 s at 60 FPS).
const RESPAWN_INVULN_FRAMES: int = 90;

#endregion

## Area that defines the playable bounds. Leaving it triggers a KO check.
@export var safe_zone: Area2D;

## World position used when a character respawns after a KO.
@export var respawn_point: Node2D;

## Fighters participating in this match (order is cosmetic only).
@export var players: Array[ CharacterController ] = [];

## character instance_id -> remaining stocks.
var _stocks: Dictionary = {};

## Characters that have been eliminated (stocks reached 0).
var _eliminated: Dictionary = {};

## True after the match has already printed / handled a winner.
var _match_over: bool = false;


func _ready() -> void:
	# Seed stock counts for every registered fighter.
	for player in players:
		# Skip null slots that may appear in the export array.
		if player == null:
			continue;
		# instance_id is stable for the lifetime of the node.
		_stocks[ player.get_instance_id() ] = DEFAULT_STOCKS;
		_eliminated[ player.get_instance_id() ] = false;
		# Debug so we can confirm wiring in the editor run.
		print( 'MatchController: registered ', player.name, ' with ', DEFAULT_STOCKS, ' stocks' );
	
	# Wire SafeZone exit detection once the tree is ready.
	if safe_zone:
		# body_exited fires when a PhysicsBody2D leaves the Area2D shape.
		safe_zone.body_exited.connect( _on_safe_zone_body_exited );
		# Ensure monitoring is on so the signal can fire.
		safe_zone.monitoring = true;
		print( 'MatchController: SafeZone connected' );
	else:
		push_warning( 'MatchController: safe_zone is not assigned' );


## SafeZone callback — a PhysicsBody2D left the playable area.
func _on_safe_zone_body_exited( body: Node2D ) -> void:
	# Only fighters participate in stock / KO logic.
	if not ( body is CharacterController ):
		return;
	
	var character: CharacterController = body as CharacterController;
	
	# Ignore bodies we never registered.
	var id: int = character.get_instance_id();
	if not _stocks.has( id ):
		return;
	
	# Already out of the match — ignore further exits.
	if _eliminated.get( id, false ):
		return;
	
	# Respawn invulnerability blocks KO (and prevents double-KO on the same exit).
	if character.is_invulnerable():
		return;
	
	# Perform the KO sequence for this fighter.
	_handle_ko( character );


## Decrement stock, respawn or eliminate, then check for match end.
func _handle_ko( character: CharacterController ) -> void:
	var id: int = character.get_instance_id();
	
	# Spend one stock.
	_stocks[ id ] = int( _stocks[ id ] ) - 1;
	var remaining: int = int( _stocks[ id ] );
	
	print( 'KO: ', character.name, ' — stocks left: ', remaining );
	
	# No stocks left → eliminate and do not respawn.
	if remaining <= 0:
		_eliminate( character );
		_check_match_over();
		return;
	
	# Still alive → reset combat state, teleport, grant invuln.
	character.reset_for_respawn();
	
	# Place the body at the stage respawn marker.
	if respawn_point:
		character.global_position = respawn_point.global_position;
	else:
		push_warning( 'MatchController: respawn_point is not assigned' );
	
	# Grant post-respawn invulnerability so the fighter is not instantly KO'd again.
	character.invuln_frames = RESPAWN_INVULN_FRAMES;
	
	# Zero velocity again after teleport (reset already did this; keep explicit).
	character.velocity = Vector2.ZERO;


## Hide / disable an eliminated fighter so they no longer interact.
func _eliminate( character: CharacterController ) -> void:
	var id: int = character.get_instance_id();
	_eliminated[ id ] = true;
	
	# Clear combat state so they are not stuck mid-attack off-screen.
	character.reset_for_respawn();
	
	# Remove from play — simple hide + freeze for this pass (no elimination UI yet).
	character.visible = false;
	character.set_physics_process( false );
	character.set_process( false );
	character.set_process_unhandled_input( false );
	# Also stop the state machine processing if present.
	if character.state_machine:
		character.state_machine.set_physics_process( false );
		character.state_machine.set_process( false );
	
	print( 'Eliminated: ', character.name );


## If one or fewer fighters remain, the match is over.
func _check_match_over() -> void:
	# Already handled — avoid spam.
	if _match_over:
		return;
	
	var alive_count: int = 0;
	var last_alive: CharacterController = null;
	
	for player in players:
		if player == null:
			continue;
		var id: int = player.get_instance_id();
		# Count anyone still holding stocks.
		if int( _stocks.get( id, 0 ) ) > 0:
			alive_count += 1;
			last_alive = player;
	
	# More than one fighter still in — keep playing.
	if alive_count > 1:
		return;
	
	_match_over = true;
	
	if alive_count == 1 and last_alive:
		print( 'Match over — winner: ', last_alive.name );
	else:
		print( 'Match over — no survivors' );


## Debug / HUD helper — remaining stocks for a fighter.
func get_stocks( character: CharacterController ) -> int:
	if character == null:
		return 0;
	return int( _stocks.get( character.get_instance_id(), 0 ) );
