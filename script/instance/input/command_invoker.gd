extends RefCounted

class_name CommandInvoker

const MoveCmdScript = preload("res://script/instance/command/move_command.gd")
const AttackCmdScript = preload("res://script/instance/command/attack_command.gd")
const InteractCmdScript = preload("res://script/instance/command/interact_command.gd")
const WaitCmdScript = preload("res://script/instance/command/wait_command.gd")

func translate_dungeon_input(_event, _context):
	return null

func translate_camera_input(_event):
	return null

func translate_ui_action(_event):
	return null

func process_continuous_input(_delta, _context):
	return null

func get_continuous_camera_pan(_delta):
	return Vector2.ZERO

func get_continuous_camera_zoom(_delta):
	return 1.0

func _bump_command_for_delta(player, entity_grid, delta):
	var player_position = player.get_grid_position()
	if player_position == null:
		return null
	var target_cell = Vector2i(int(player_position.x) + delta.x, int(player_position.y) + delta.y)
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
