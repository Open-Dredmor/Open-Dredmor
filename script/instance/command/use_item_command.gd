extends "res://script/instance/command/game_command.gd"

class_name UseItemCommand

var item_data = {}
var target_cell = Vector2i.ZERO

func init(target_actor, item_entry, cell = Vector2i.ZERO):
	command_type = "use_item"
	actor = target_actor
	item_data = item_entry if item_entry != null else {}
	target_cell = Vector2i(int(cell.x), int(cell.y))
	return self

func can_execute(context):
	return not item_data.is_empty() and context.get("dungeon", null) != null

func execute(context):
	var dungeon = context.get("dungeon", null)
	if dungeon == null:
		return { executed = false, consumes_turn = false, message = "" }
	var handled = dungeon.execute_use_item(item_data, target_cell)
	return {
		executed = handled,
		consumes_turn = handled,
		message = ""
	}

func to_dict():
	return {
		command_type = command_type,
		item_name = item_data.get("name", ""),
		target_cell = target_cell
	}
