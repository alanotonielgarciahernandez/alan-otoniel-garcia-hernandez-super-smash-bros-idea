# res://data/moves/move_data.gd
# Shared frame data for a single attack.
#
# Times are in seconds (consistent with the rest of the project).
# Knockback uses a simplified Smash-style formula on hit.

class_name MoveData;
extends Resource;

## Name used for debug / UI (optional).
@export var move_name: String = '';

## Time before the hitbox turns on.
@export var startup_time: float = 0.08;

## How long the hitbox stays active.
@export var active_time: float = 0.05;

## Time after the hitbox turns off before the state ends.
@export var endlag_time: float = 0.15;

## Damage percent added to the target on hit.
@export var damage: float = 3.0;

## Base knockback (applied even at 0%).
@export var base_knockback: float = 20.0;

## Knockback growth (scales with target percent).
@export var knockback_growth: float = 40.0;

## Launch angle in degrees. 0 = forward, 90 = straight up.
@export var angle_degrees: float = 45.0;

## Hitlag (freeze) duration for both attacker and target on hit.
@export var hitlag_time: float = 0.06;

## Animation to play on the character when this move starts.
@export var animation_name: String = 'jab';
