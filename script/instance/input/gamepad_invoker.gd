extends "res://script/instance/input/command_invoker.gd"

class_name GamepadInvoker

const STICK_DEADZONE = 0.45
const CAMERA_STICK_DEADZONE = 0.25
const TRIGGER_DEADZONE = 0.25
const REPEAT_INITIAL_DELAY = 0.24
const REPEAT_INTERVAL = 0.13
const CAMERA_PAN_SPEED = 420.0
const TRIGGER_ZOOM_RATE = 1.6

var _active_device = 0
var _next_repeat_time_ms = 0
var _right_stick = Vector2.ZERO
var _left_trigger = 0.0
var _right_trigger = 0.0
var _stick_direction = Vector2i.ZERO
var _active_axis_binds = {}
var _button_bindings = {
	move_up = JOY_BUTTON_DPAD_UP,
	move_down = JOY_BUTTON_DPAD_DOWN,
	move_left = JOY_BUTTON_DPAD_LEFT,
	move_right = JOY_BUTTON_DPAD_RIGHT,
	wait = JOY_BUTTON_X,
	interact = JOY_BUTTON_A,
	cancel = JOY_BUTTON_B,
	menu = JOY_BUTTON_START,
	inventory = JOY_BUTTON_Y,
	character = JOY_BUTTON_BACK,
	skills = JOY_BUTTON_LEFT_SHOULDER,
	crafting = JOY_BUTTON_RIGHT_SHOULDER
}

func sync_from_settings():
	if OD.Settings == null or not OD.Settings.has_method("get_gamepad_binds"):
		return
	var binds = OD.Settings.get_gamepad_binds()
	for action_name in binds.keys():
		var bind_value = binds[action_name]
		if bind_value is String:
			_button_bindings[action_name] = bind_value
		else:
			_button_bindings[action_name] = int(bind_value)

func _parse_axis_bind(bind_value):
	if not (bind_value is String):
		return null
	if not bind_value.begins_with("axis:"):
		return null
	var parts = bind_value.split(":")
	if parts.size() != 3:
		return null
	return {
		"axis": int(parts[1]),
		"direction": int(parts[2])
	}

func _is_axis_bind_pressed(bind_value, event):
	if not (event is InputEventJoypadMotion):
		return false
	var axis_info = _parse_axis_bind(bind_value)
	if axis_info == null or event.axis != axis_info.axis:
		return false
	var threshold = STICK_DEADZONE
	var is_active = (event.axis_value >= threshold) if axis_info.direction > 0 else (event.axis_value <= -threshold)
	var axis_key = str(bind_value)
	var was_active = _active_axis_binds.get(axis_key, false)
	_active_axis_binds[axis_key] = is_active
	return is_active and not was_active

func _matches_binding(bind_value, event):
	if bind_value is String:
		return _is_axis_bind_pressed(bind_value, event)
	return event is InputEventJoypadButton and event.pressed and event.button_index == int(bind_value)

func _dpad_delta(button_index):
	if _button_bindings.move_up is int and button_index == _button_bindings.move_up:
		return Vector2i(0, -1)
	if _button_bindings.move_down is int and button_index == _button_bindings.move_down:
		return Vector2i(0, 1)
	if _button_bindings.move_left is int and button_index == _button_bindings.move_left:
		return Vector2i(-1, 0)
	if _button_bindings.move_right is int and button_index == _button_bindings.move_right:
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _bound_axis_move_delta(event):
	if _is_axis_bind_pressed(_button_bindings.move_up, event):
		return Vector2i(0, -1)
	if _is_axis_bind_pressed(_button_bindings.move_down, event):
		return Vector2i(0, 1)
	if _is_axis_bind_pressed(_button_bindings.move_left, event):
		return Vector2i(-1, 0)
	if _is_axis_bind_pressed(_button_bindings.move_right, event):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _axis_to_cardinal(axis_x, axis_y):
	var abs_x = abs(axis_x)
	var abs_y = abs(axis_y)
	if abs_x < STICK_DEADZONE and abs_y < STICK_DEADZONE:
		return Vector2i.ZERO
	if abs_x >= abs_y:
		return Vector2i(1 if axis_x > 0.0 else -1, 0)
	return Vector2i(0, 1 if axis_y > 0.0 else -1)

func _update_stick_state(event):
	if not (event is InputEventJoypadMotion):
		return Vector2i.ZERO
	if event.axis == JOY_AXIS_RIGHT_X:
		_right_stick.x = event.axis_value if abs(event.axis_value) >= CAMERA_STICK_DEADZONE else 0.0
		return Vector2i.ZERO
	if event.axis == JOY_AXIS_RIGHT_Y:
		_right_stick.y = event.axis_value if abs(event.axis_value) >= CAMERA_STICK_DEADZONE else 0.0
		return Vector2i.ZERO
	if event.axis == JOY_AXIS_TRIGGER_LEFT:
		_left_trigger = event.axis_value if event.axis_value >= TRIGGER_DEADZONE else 0.0
		return Vector2i.ZERO
	if event.axis == JOY_AXIS_TRIGGER_RIGHT:
		_right_trigger = event.axis_value if event.axis_value >= TRIGGER_DEADZONE else 0.0
		return Vector2i.ZERO
	if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
		var device = event.device
		var axis_x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var axis_y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		if event.axis == JOY_AXIS_LEFT_X:
			axis_x = event.axis_value
		else:
			axis_y = event.axis_value
		var next_direction = _axis_to_cardinal(axis_x, axis_y)
		if next_direction != _stick_direction:
			_stick_direction = next_direction
			return next_direction
	return Vector2i.ZERO

func get_continuous_camera_pan(delta):
	if _right_stick == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2(-_right_stick.x, -_right_stick.y) * CAMERA_PAN_SPEED * delta

func get_continuous_camera_zoom(delta):
	var net_trigger = _right_trigger - _left_trigger
	if abs(net_trigger) < 0.01:
		return 1.0
	return pow(TRIGGER_ZOOM_RATE, net_trigger * delta)

func translate_camera_input(event):
	if event is InputEventJoypadMotion:
		_update_stick_state(event)
		return null
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_STICK:
			return { kind = "center_camera" }
	return null

func translate_ui_action(event):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_active_device = event.device
	if _matches_binding(_button_bindings.menu, event):
		return { kind = "open_menu_selector" }
	if _matches_binding(_button_bindings.inventory, event):
		return { kind = "toggle_inventory" }
	if _matches_binding(_button_bindings.character, event):
		return { kind = "toggle_character" }
	if _matches_binding(_button_bindings.skills, event):
		return { kind = "toggle_skill_tree" }
	if _matches_binding(_button_bindings.crafting, event):
		return { kind = "toggle_crafting" }
	if _matches_binding(_button_bindings.cancel, event):
		return { kind = "cancel" }
	if not (event is InputEventJoypadButton) or not event.pressed:
		return null
	match event.button_index:
		JOY_BUTTON_RIGHT_STICK:
			return { kind = "cycle_minimap_zoom" }
	return null

func translate_targeting_input(event):
	if event is InputEventJoypadButton and event.pressed:
		var dpad = _dpad_delta(event.button_index)
		if dpad != Vector2i.ZERO:
			return { kind = "move_cursor", delta = dpad }
		if _matches_binding(_button_bindings.interact, event):
			return { kind = "confirm_target" }
		if _matches_binding(_button_bindings.cancel, event):
			return { kind = "cancel_target" }
	if event is InputEventJoypadMotion:
		if _matches_binding(_button_bindings.interact, event):
			return { kind = "confirm_target" }
		if _matches_binding(_button_bindings.cancel, event):
			return { kind = "cancel_target" }
		var bound_delta = _bound_axis_move_delta(event)
		if bound_delta != Vector2i.ZERO:
			return { kind = "move_cursor", delta = bound_delta }
		var stick_delta = _update_stick_state(event)
		if stick_delta != Vector2i.ZERO:
			return { kind = "move_cursor", delta = stick_delta }
	return null

func _context_confirm_command(player, entity_grid):
	var player_position = player.get_grid_position()
	if player_position == null:
		return null
	var cell = Vector2i(int(player_position.x), int(player_position.y))
	var stairs = entity_grid.get_stairs_at(cell.x, cell.y)
	if stairs != null:
		return InteractCmdScript.new().init(player, "stairs", cell, stairs.direction)
	if not entity_grid.get_loot_list_at(cell.x, cell.y).is_empty():
		return InteractCmdScript.new().init(player, "pickup", cell)
	return WaitCmdScript.new().init(player)

func _is_binding_currently_held(bind_value, device):
	var axis_info = _parse_axis_bind(bind_value)
	if axis_info != null:
		var axis_value = Input.get_joy_axis(device, axis_info.axis)
		return (axis_value >= STICK_DEADZONE) if axis_info.direction > 0 else (axis_value <= -STICK_DEADZONE)
	if (bind_value is int or bind_value is float) and int(bind_value) >= 0:
		return Input.is_joy_button_pressed(device, int(bind_value))
	return false

func _poll_held_direction():
	var connected = Input.get_connected_joypads()
	if connected.is_empty():
		return Vector2i.ZERO
	var device = _active_device if _active_device in connected else int(connected[0])
	var move_x = 0
	var move_y = 0
	if _is_binding_currently_held(_button_bindings.move_left, device):
		move_x -= 1
	if _is_binding_currently_held(_button_bindings.move_right, device):
		move_x += 1
	if _is_binding_currently_held(_button_bindings.move_up, device):
		move_y -= 1
	if _is_binding_currently_held(_button_bindings.move_down, device):
		move_y += 1
	if move_x != 0 or move_y != 0:
		if abs(move_x) >= abs(move_y) and move_x != 0:
			return Vector2i(move_x, 0)
		return Vector2i(0, move_y)
	var axis_x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var axis_y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	return _axis_to_cardinal(axis_x, axis_y)

func _arm_repeat_delay():
	_next_repeat_time_ms = Time.get_ticks_msec() + int(REPEAT_INITIAL_DELAY * 1000.0)

func translate_dungeon_input(event, context):
	var dungeon = context.get("dungeon", null)
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if dungeon == null or entity_grid == null or player == null:
		return null

	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_active_device = event.device

	if event is InputEventJoypadButton:
		var dpad = _dpad_delta(event.button_index)
		if dpad != Vector2i.ZERO:
			if event.pressed:
				_arm_repeat_delay()
				return _bump_command_for_delta(player, entity_grid, dpad)
			_next_repeat_time_ms = 0
			return null
		if event.pressed:
			if _matches_binding(_button_bindings.interact, event):
				return _context_confirm_command(player, entity_grid)
			if _matches_binding(_button_bindings.wait, event):
				return WaitCmdScript.new().init(player)

	if event is InputEventJoypadMotion:
		if _matches_binding(_button_bindings.interact, event):
			return _context_confirm_command(player, entity_grid)
		if _matches_binding(_button_bindings.wait, event):
			return WaitCmdScript.new().init(player)
		var bound_delta = _bound_axis_move_delta(event)
		if bound_delta != Vector2i.ZERO:
			_arm_repeat_delay()
			return _bump_command_for_delta(player, entity_grid, bound_delta)
		var stick_delta = _update_stick_state(event)
		if stick_delta != Vector2i.ZERO:
			_arm_repeat_delay()
			return _bump_command_for_delta(player, entity_grid, stick_delta)
		elif _stick_direction == Vector2i.ZERO and (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y):
			_next_repeat_time_ms = 0
	return null

func process_continuous_input(_delta, context):
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if entity_grid == null or player == null:
		return null
	var live_direction = _poll_held_direction()
	if live_direction == Vector2i.ZERO:
		_next_repeat_time_ms = 0
		return null
	var now_ms = Time.get_ticks_msec()
	if _next_repeat_time_ms > 0 and now_ms < _next_repeat_time_ms:
		return null
	_next_repeat_time_ms = now_ms + int(REPEAT_INTERVAL * 1000.0)
	return _bump_command_for_delta(player, entity_grid, live_direction)
