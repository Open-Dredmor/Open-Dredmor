extends "res://script/instance/input/command_invoker.gd"

class_name GamepadInvoker

const STICK_DEADZONE = 0.45
const CAMERA_STICK_DEADZONE = 0.25
const TRIGGER_DEADZONE = 0.25
const REPEAT_INITIAL_DELAY = 0.24
const REPEAT_INTERVAL = 0.13
const CAMERA_PAN_SPEED = 420.0
const TRIGGER_ZOOM_RATE = 1.6

var _held_direction = Vector2i.ZERO
var _repeat_timer = 0.0
var _right_stick = Vector2.ZERO
var _left_trigger = 0.0
var _right_trigger = 0.0
var _stick_direction = Vector2i.ZERO
var _button_bindings = {
	move_up = JOY_BUTTON_DPAD_UP,
	move_down = JOY_BUTTON_DPAD_DOWN,
	move_left = JOY_BUTTON_DPAD_LEFT,
	move_right = JOY_BUTTON_DPAD_RIGHT,
	wait = JOY_BUTTON_X,
	interact = JOY_BUTTON_A,
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
		_button_bindings[action_name] = int(binds[action_name])

func _dpad_delta(button_index):
	if button_index == _button_bindings.move_up:
		return Vector2i(0, -1)
	if button_index == _button_bindings.move_down:
		return Vector2i(0, 1)
	if button_index == _button_bindings.move_left:
		return Vector2i(-1, 0)
	if button_index == _button_bindings.move_right:
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
	if not (event is InputEventJoypadButton) or not event.pressed:
		return null
	if event.button_index == _button_bindings.inventory:
		return { kind = "toggle_inventory" }
	if event.button_index == _button_bindings.character:
		return { kind = "toggle_character" }
	if event.button_index == _button_bindings.skills:
		return { kind = "toggle_skill_tree" }
	if event.button_index == _button_bindings.crafting:
		return { kind = "toggle_crafting" }
	match event.button_index:
		JOY_BUTTON_START:
			return { kind = "toggle_pause" }
		JOY_BUTTON_B:
			return { kind = "cancel" }
		JOY_BUTTON_RIGHT_STICK:
			return { kind = "cycle_minimap_zoom" }
	return null

func translate_targeting_input(event):
	if event is InputEventJoypadButton and event.pressed:
		var dpad = _dpad_delta(event.button_index)
		if dpad != Vector2i.ZERO:
			return { kind = "move_cursor", delta = dpad }
		if event.button_index == _button_bindings.interact:
			return { kind = "confirm_target" }
		if event.button_index == JOY_BUTTON_B:
			return { kind = "cancel_target" }
	if event is InputEventJoypadMotion:
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

func translate_dungeon_input(event, context):
	var dungeon = context.get("dungeon", null)
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if dungeon == null or entity_grid == null or player == null:
		return null

	if event is InputEventJoypadButton:
		var dpad = _dpad_delta(event.button_index)
		if dpad != Vector2i.ZERO:
			if event.pressed:
				_held_direction = dpad
				_repeat_timer = REPEAT_INITIAL_DELAY
				return _bump_command_for_delta(player, entity_grid, dpad)
			elif _held_direction == dpad:
				_held_direction = Vector2i.ZERO
			return null
		if event.pressed:
			if event.button_index == _button_bindings.interact:
				return _context_confirm_command(player, entity_grid)
			if event.button_index == _button_bindings.wait:
				return WaitCmdScript.new().init(player)

	if event is InputEventJoypadMotion:
		var stick_delta = _update_stick_state(event)
		if stick_delta != Vector2i.ZERO:
			_held_direction = stick_delta
			_repeat_timer = REPEAT_INITIAL_DELAY
			return _bump_command_for_delta(player, entity_grid, stick_delta)
		elif _stick_direction == Vector2i.ZERO and (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y):
			_held_direction = Vector2i.ZERO
	return null

func process_continuous_input(delta, context):
	if _held_direction == Vector2i.ZERO:
		return null
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if entity_grid == null or player == null:
		return null
	_repeat_timer -= delta
	if _repeat_timer <= 0.0:
		_repeat_timer = REPEAT_INTERVAL
		return _bump_command_for_delta(player, entity_grid, _held_direction)
	return null
