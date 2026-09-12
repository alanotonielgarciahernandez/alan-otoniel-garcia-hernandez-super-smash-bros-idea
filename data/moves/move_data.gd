# res://data/moves/move_data.gd
# Shared frame data for a single attack.
#

class_name MoveData;
extends Resource;

## Name used for debug / UI (optional).
@export var move_name: String = '';

## Frames before the hitbox turns on.
@export var startup_frames: int = 5;

## How many frames the hitbox stays active.
@export var active_frames: int = 3;

## Frames after the hitbox turns off before the state ends.
@export var endlag_frames: int = 9;

## Damage percent added to the target on hit.
@export var damage: float = 3.0;

## Base knockback (applied even at 0%).
@export var base_knockback: float = 20.0;

## Knockback growth (scales with target percent).
@export var knockback_growth: float = 40.0;

## Launch angle in degrees. 0 = forward, 90 = straight up.
@export var angle_degrees: float = 45.0;

## Hitlag (freeze) frames for both attacker and target on hit.
@export var hitlag_frames: int = 4;

## Animation to play on the character when this move starts.
@export var animation_name: String = 'idle';
