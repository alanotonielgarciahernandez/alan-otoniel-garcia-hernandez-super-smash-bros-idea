# res://characters/character_data.gd
# Per-fighter movement stats. One resource per character.
# Stick thresholds, the input buffer, coyote time, and knockback scale
# stay on CharacterController because every fighter shares them.

class_name CharacterData;
extends Resource;

#region Speeds.

## Walking speed (analog partial tilt only).
@export var WALK_SPEED: float = 100.0;

## Jogging speed (default tier — keyboard's only tier without dashing).
@export var JOG_SPEED: float = 200.0;

## Running speed (reached via a dash trigger).
@export var RUN_SPEED: float = 320.0;

## Horizontal speed cap while airborne.
@export var AIR_SPEED: float = 200.0;

## Extra horizontal speed applied once when entering Run from a dash.
@export var RUN_BURST_SPEED: float = 80.0;

## Short hop vertical velocity.
@export var SHORT_HOP_SPEED: float = -280.0;

## Full hop vertical velocity.
@export var JUMP_SPEED: float = -500.0;

## Maximum speed at which the player can normally fall.
@export var TERMINAL_SPEED: float = 220.0;

## Fast-fall maximum fall speed.
@export var FAST_FALL_SPEED: float = 360.0;

#endregion

#region Acceleration and traction.

## Acceleration applied to all grounded movement tiers (units/sec²).
## Current shared tune is the old JOG_SPEED * 6. Stored on its own so a
## slower jog does not silently weaken traction.
@export var ACCELERATION_SPEED: float = 1200.0;

## Horizontal acceleration while airborne (units per second²).
## Current shared tune is half of grounded acceleration.
@export var AIR_ACCELERATION: float = 600.0;

## Ground friction / traction (units per second²). Higher = stops faster.
@export var GROUND_FRICTION: float = 1800.0;

## Air friction / traction (units per second²). Higher = stops faster.
@export var AIR_FRICTION: float = 200.0;

#endregion

#region Action frame data.

## Frame duration of the grounded jumpsquat.
@export var JUMP_SQUAT_FRAMES: int = 3;

## Soft landing recovery (normal fall / short hop).
@export var LAND_FRAMES_SOFT: int = 4;

## Hard landing recovery (fast-fall or high fall speed).
@export var LAND_FRAMES_HARD: int = 11;

## Maximum number of jumps allowed before touching the ground again.
@export var MAX_JUMPS: int = 2;

#endregion
