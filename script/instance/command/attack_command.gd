extends "res://script/instance/command/game_command.gd"

class_name AttackCommand

var target_cell = Vector2i.ZERO

func init(target_actor, cell):
	command_type = "attack"
	actor = target_actor
	target_cell = Vector2i(int(cell.x), int(cell.y))
	return self

func can_execute(context):
	var dungeon = context.get("dungeon", null)
	return dungeon != null and context.get("entity_grid", null) != null

func execute(context):
	var dungeon = context.get("dungeon", null)
	if dungeon == null:
		return { executed = false, consumes_turn = false, message = "" }
	var handled = dungeon.execute_attack_at(target_cell)
	return {
		executed = handled,
		consumes_turn = handled,
		message = ""
	}

func to_dict():
	return {
		command_type = command_type,
		target_cell = target_cell
	}
