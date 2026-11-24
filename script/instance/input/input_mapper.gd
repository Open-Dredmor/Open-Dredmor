extends RefCounted

class_name InputMapper

const MoveCmdScript = preload("res://script/instance/command/move_command.gd")
const AttackCmdScript = preload("res://script/instance/command/attack_command.gd")
const InteractCmdScript = preload("res://script/instance/command/interact_command.gd")
const WaitCmdScript = preload("res://script/instance/command/wait_command.gd")

var _key_bindings = {
	wait = [KEY_PERIOD, KEY_KP_5],
	restart_scene = [KEY_SPACE],
	pan_left = [KEY_LEFT],
	pan_right = [KEY_RIGHT],
	pan_up = [KEY_UP],
	pan_down = [KEY_DOWN],
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

func translate_camera_input(ev):
	if ev is InputEventKey and ev.is_pressed():
		if is_action_key("pan_left", ev.keycode):
			return { kind = "pan", delta = Vector2(1, 0) }
		if is_action_key("pan_right", ev.keycode):
			return { kind = "pan", delta = Vector2(-1, 0) }
		if is_action_key("pan_up", ev.keycode):
			return { kind = "pan", delta = Vector2(0, 1) }
		if is_action_key("pan_down", ev.keycode):
			return { kind = "pan", delta = Vector2(0, -1) }
		if is_action_key("center_camera", ev.keycode) and not ev.echo:
			return { kind = "center_camera" }
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			return { kind = "drag", pressed = ev.pressed, position = ev.position }
		if ev.pressed and ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			return { kind = "zoom", factor = 1.15 }
		if ev.pressed and ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			return { kind = "zoom", factor = 1.0 / 1.15 }
		if ev.pressed and ev.button_index == MOUSE_BUTTON_MIDDLE:
			return { kind = "reset_zoom" }
	if ev is InputEventMouseMotion:
		return { kind = "drag_motion", position = ev.position }
	return null

func translate_dungeon_input(ev, context):
	var dungeon = context.get("dungeon", null)
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if dungeon == null or entity_grid == null or player == null:
		return null

	if ev is InputEventKey and ev.is_pressed() and not ev.echo:
		if is_action_key("wait", ev.keycode):
			return WaitCmdScript.new().init(player)
		if ev.unicode == ord(">") or ev.unicode == ord("<"):
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
