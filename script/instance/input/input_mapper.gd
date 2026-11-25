extends RefCounted

class_name InputMapper

const MoveCmdScript = preload("res://script/instance/command/move_command.gd")
const AttackCmdScript = preload("res://script/instance/command/attack_command.gd")
const InteractCmdScript = preload("res://script/instance/command/interact_command.gd")
const WaitCmdScript = preload("res://script/instance/command/wait_command.gd")

var _key_bindings = {
	move_left = [KEY_A, KEY_LEFT, KEY_KP_4],
	move_right = [KEY_D, KEY_RIGHT, KEY_KP_6],
	move_up = [KEY_W, KEY_UP, KEY_KP_8],
	move_down = [KEY_S, KEY_DOWN, KEY_KP_2],
	wait = [KEY_SPACE, KEY_PERIOD, KEY_KP_5],
	pickup = [KEY_G, KEY_COMMA],
	restart_scene = [KEY_F5],
	center_camera = [KEY_C]
}

func bind_key(action_name, keycodes):
	if typeof(keycodes) == TYPE_ARRAY:
		_key_bindings[action_name] = keycodes.duplicate()
	else:
		_key_bindings[action_name] = [int(keycodes)]

func get_bindings():
	return _key_bindings.duplicate(true)

func is_action_key(action_name, keycode):
	if not _key_bindings.has(action_name):
		return false
	return keycode in _key_bindings[action_name]

func sync_from_settings():
	if OD.Settings == null or not OD.Settings.has_method("get_keybinds"):
		return
	var binds = OD.Settings.get_keybinds()
	for action_name in ["move_up", "move_down", "move_left", "move_right", "wait"]:
		if not binds.has(action_name):
			continue
		var primary = int(binds[action_name])
		var existing = _key_bindings.get(action_name, []).duplicate()
		if not (primary in existing):
			existing.insert(0, primary)
			_key_bindings[action_name] = existing

func translate_camera_input(ev):
	if ev is InputEventKey and ev.is_pressed():
		if ev.shift_pressed:
			if ev.keycode == KEY_LEFT:
				return { kind = "pan", delta = Vector2(1, 0) }
			if ev.keycode == KEY_RIGHT:
				return { kind = "pan", delta = Vector2(-1, 0) }
			if ev.keycode == KEY_UP:
				return { kind = "pan", delta = Vector2(0, 1) }
			if ev.keycode == KEY_DOWN:
				return { kind = "pan", delta = Vector2(0, -1) }
		if is_action_key("center_camera", ev.keycode) and not ev.echo:
			return { kind = "center_camera" }
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			return { kind = "drag", pressed = ev.pressed, position = ev.position }
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			return { kind = "zoom", factor = 1.15 } if ev.pressed else { kind = "ignore" }
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			return { kind = "zoom", factor = 1.0 / 1.15 } if ev.pressed else { kind = "ignore" }
		if ev.button_index == MOUSE_BUTTON_MIDDLE:
			return { kind = "reset_zoom" } if ev.pressed else { kind = "ignore" }
	if ev is InputEventMouseMotion:
		return { kind = "drag_motion", position = ev.position }
	return null

func _directional_delta(keycode):
	if is_action_key("move_left", keycode):
		return Vector2i(-1, 0)
	if is_action_key("move_right", keycode):
		return Vector2i(1, 0)
	if is_action_key("move_up", keycode):
		return Vector2i(0, -1)
	if is_action_key("move_down", keycode):
		return Vector2i(0, 1)
	return Vector2i.ZERO

func _bump_command_for_delta(player, entity_grid, delta):
	var player_pos = player.get_grid_position()
	if player_pos == null:
		return null
	var target_cell = Vector2i(int(player_pos.x) + delta.x, int(player_pos.y) + delta.y)
	if entity_grid.has_enemy_at(target_cell.x, target_cell.y):
		return AttackCmdScript.new().init(player, target_cell)
	var shopkeeper = entity_grid.shop_manager.get_shopkeeper_at(target_cell.x, target_cell.y)
	if shopkeeper != null:
		return InteractCmdScript.new().init(player, "shopkeeper", target_cell)
	var shop_pedestal = entity_grid.shop_manager.get_pedestal_at(target_cell.x, target_cell.y)
	if shop_pedestal != null:
		return InteractCmdScript.new().init(player, "shop_pedestal", target_cell)
	var door = entity_grid.get_door_at(target_cell.x, target_cell.y)
	if door != null and not door.can_pass():
		return InteractCmdScript.new().init(player, "door", target_cell)
	var element = entity_grid.get_element_at(target_cell.x, target_cell.y)
	if element != null and not element.is_broken:
		if element.element_type == "custom_breakable":
			return AttackCmdScript.new().init(player, target_cell)
		return InteractCmdScript.new().init(player, "element", target_cell)
	if entity_grid.is_walkable(target_cell.x, target_cell.y):
		return MoveCmdScript.new().init_step(player, delta)
	return null

func translate_dungeon_input(ev, context):
	var dungeon = context.get("dungeon", null)
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if dungeon == null or entity_grid == null or player == null:
		return null

	if ev is InputEventKey and ev.is_pressed():
		var move_delta = _directional_delta(ev.keycode)
		if move_delta != Vector2i.ZERO:
			return _bump_command_for_delta(player, entity_grid, move_delta)
		if not ev.echo and is_action_key("wait", ev.keycode):
			return WaitCmdScript.new().init(player)
		if not ev.echo and is_action_key("pickup", ev.keycode):
			var player_pos = player.get_grid_position()
			if player_pos != null:
				return InteractCmdScript.new().init(player, "pickup", Vector2i(int(player_pos.x), int(player_pos.y)))
		if not ev.echo and (ev.unicode == ord(">") or ev.unicode == ord("<")):
			var player_pos = player.get_grid_position()
			var stairs = entity_grid.get_stairs_at(player_pos.x, player_pos.y)
			if stairs != null:
				var wanted = "down" if ev.unicode == ord(">") else "up"
				if stairs.direction == wanted:
					return InteractCmdScript.new().init(player, "stairs", Vector2i(int(player_pos.x), int(player_pos.y)), wanted)

	if ev is InputEventMouseButton:
		var grid_coords = dungeon.global_coordinates_to_grid(ev.position.x, ev.position.y)
		var cell = Vector2i(int(grid_coords.x), int(grid_coords.y))
		var allow_debug_teleport = context.get("allow_debug_teleport", false)
		if ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed and allow_debug_teleport:
			return MoveCmdScript.new().init_path(player, cell, true)
		if ev.button_index != MOUSE_BUTTON_LEFT or ev.pressed:
			return null
		if not entity_grid.is_cell_explored(cell.x, cell.y):
			return null
		var shopkeeper = entity_grid.shop_manager.get_shopkeeper_at(cell.x, cell.y)
		if shopkeeper != null:
			return InteractCmdScript.new().init(player, "shopkeeper", cell)
		var shop_pedestal = entity_grid.shop_manager.get_pedestal_at(cell.x, cell.y)
		if shop_pedestal != null:
			return InteractCmdScript.new().init(player, "shop_pedestal", cell)
		var door = entity_grid.get_door_at(cell.x, cell.y)
		if door != null and not door.can_pass():
			return InteractCmdScript.new().init(player, "door", cell)
		var element = entity_grid.get_element_at(cell.x, cell.y)
		if element != null and not element.is_broken:
			return InteractCmdScript.new().init(player, "element", cell)
		var trap = entity_grid.get_trap_at(cell.x, cell.y)
		if trap != null and trap.is_discovered and not trap.is_disarmed:
			return InteractCmdScript.new().init(player, "trap", cell)
		var stairs = entity_grid.get_stairs_at(cell.x, cell.y)
		if stairs != null:
			return InteractCmdScript.new().init(player, "stairs", cell, stairs.direction)
		if entity_grid.is_walkable(cell.x, cell.y):
			return MoveCmdScript.new().init_path(player, cell, false)
	return null
