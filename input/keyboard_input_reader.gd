# res://input/keyboard_input_reader.gd
# Keyboard input reader.
#
# It maps keys to move and jump actions.
# Opposite directions use the later press.
# It arms dash only on an explicit release-then-press.

class_name KeyboardInputReader;
extends InputReader;

## Most recent horizontal press. -1 = left, +1 = right, 0 = none yet.
var _latest_horizontal: int = 0;

## Most recent vertical press. -1 = up, +1 = down, 0 = none yet.
var _latest_vertical: int = 0;

## Direction already seen held, so a later poll does not overwrite event order.
var _left_held: bool = false;
var _right_held: bool = false;
var _up_held: bool = false;
var _down_held: bool = false;

## Physics sample id. A tap is tagged for the next sample, then dropped.
var _move_sample: int = 0;
var _latched_move_sample: int = -1;
var _latched_vertical_sample: int = -1;
var _latched_move_axis: float = 0.0;
var _latched_vertical_axis: float = 0.0;

func _init() -> void:
	# TODO: Default bindings — overwritten later if a save file exists.
	_bindings = {
		'move_up': KEY_UP,
		'move_down': KEY_DOWN,
		'move_left': KEY_LEFT,
		'move_right': KEY_RIGHT,
		'jump': KEY_SPACE,
		'attack': KEY_E,
	};

func is_action_pressed( action: String ) -> bool:
	# Return false if action is not listed.
	if not _bindings.has( action ):
		return false;
	
	return Input.is_key_pressed( _bindings[ action ] );

func is_action_press_event( action: String, event: InputEvent ) -> bool:
	# Return false if action is not listed.
	if not _bindings.has( action ) or not event is InputEventKey:
		return false;
	
	return event.pressed and not event.echo and event.keycode == _bindings[ action ];

## Stores which opposite key was pressed last, before the axis is sampled.
func note_input_event( event: InputEvent ) -> void:
	# Button edges, including a tap that is already up before the next poll.
	super.note_input_event( event );
	
	# Repeats are not new presses, and other devices have no key order to store.
	if not event is InputEventKey or event.echo:
		return;
	
	var key: int = event.keycode;
	
	# Horizontal pair. The later press wins while both stay down.
	if key == _bindings.get( 'move_left' ):
		_left_held = event.pressed;
		if event.pressed:
			_latest_horizontal = -1;
			# Keep the tap if the key is up again before update().
			_latched_move_axis = -1.0;
			_latched_move_sample = _move_sample + 1;
	elif key == _bindings.get( 'move_right' ):
		_right_held = event.pressed;
		if event.pressed:
			_latest_horizontal = 1;
			_latched_move_axis = 1.0;
			_latched_move_sample = _move_sample + 1;
	# Vertical pair. Down is positive, matching get_vertical_axis().
	elif key == _bindings.get( 'move_up' ):
		_up_held = event.pressed;
		if event.pressed:
			_latest_vertical = -1;
			_latched_vertical_axis = -1.0;
			_latched_vertical_sample = _move_sample + 1;
	elif key == _bindings.get( 'move_down' ):
		_down_held = event.pressed;
		if event.pressed:
			_latest_vertical = 1;
			_latched_vertical_axis = 1.0;
			_latched_vertical_sample = _move_sample + 1;

func prime_held_actions() -> void:
	super.prime_held_actions();
	
	# Match the keys that are already down so spawn does not look like a new press.
	_left_held = is_action_pressed( 'move_left' );
	_right_held = is_action_pressed( 'move_right' );
	_up_held = is_action_pressed( 'move_up' );
	_down_held = is_action_pressed( 'move_down' );
	
	# Both already held: right / down is the stable tie.
	if _right_held:
		_latest_horizontal = 1;
	elif _left_held:
		_latest_horizontal = -1;
	
	if _down_held:
		_latest_vertical = 1;
	elif _up_held:
		_latest_vertical = -1;

func rebind( action: String, binding_value ) -> void:
	super.rebind( action, binding_value );
	
	# Forget the old key's hold so the new binding can take the axis.
	if action == 'move_left':
		_left_held = false;
	elif action == 'move_right':
		_right_held = false;
	elif action == 'move_up':
		_up_held = false;
	elif action == 'move_down':
		_down_held = false;
	
	_latched_move_sample = -1;
	_latched_vertical_sample = -1;

func expire_just_pressed() -> void:
	super.expire_just_pressed();
	
	# The state already sampled this frame's tap.
	_latched_move_sample = -1;
	_latched_vertical_sample = -1;

func update() -> void:
	# Events tagged the tap for this upcoming sample.
	_move_sample += 1;
	super.update();

func get_move_axis() -> float:
	var left := is_action_pressed( 'move_left' );
	var right := is_action_pressed( 'move_right' );
	
	# A key already down at spawn never produced an event. Count that as its press.
	if left and not _left_held:
		_latest_horizontal = -1;
	if right and not _right_held:
		_latest_horizontal = 1;
	
	# Sync so the next sample only reacts to a new edge.
	_left_held = left;
	_right_held = right;
	
	# Both held: keep the direction that was pressed more recently.
	if left and right:
		return 1.0 if _latest_horizontal > 0 else -1.0;
	
	if right:
		return 1.0;
	
	if left:
		return -1.0;
	
	# Press and release landed between polls. Hold that direction for this sample.
	if _latched_move_sample == _move_sample:
		return _latched_move_axis;
	
	return 0.0;

func get_vertical_axis() -> float:
	var up := is_action_pressed( 'move_up' );
	var down := is_action_pressed( 'move_down' );
	
	# Same last-press rule as horizontal, for up held into down and the reverse.
	if up and not _up_held:
		_latest_vertical = -1;
	if down and not _down_held:
		_latest_vertical = 1;
	
	_up_held = up;
	_down_held = down;
	
	# Both held: most recent vertical press wins. Down is positive.
	if up and down:
		return 1.0 if _latest_vertical > 0 else -1.0;
	
	if down:
		return 1.0;
	
	if up:
		return -1.0;
	
	# Same one-sample tap as horizontal, for a down or up key that is already released.
	if _latched_vertical_sample == _move_sample:
		return _latched_vertical_axis;
	
	return 0.0;

func _arms_dash_continuously() -> bool:
	# Arm when a direction is released back to neutral, then re-pressed.
	return false;
