extends "res://script/instance/command/game_command.gd"

class_name InteractCommand

var interaction_kind = ""
var target_cell = Vector2i.ZERO
var direction = ""

func init(target_actor, kind, cell, stair_direction = ""):
	command_type = "interact"
	actor = target_actor
	interaction_kind = kind
	target_cell = Vector2i(int(cell.x), int(cell.y))
	direction = stair_direction
	return self

func can_execute(context):
	var dungeon = context.get("dungeon", null)
	return dungeon != null and context.get("entity_grid", null) != null

func execute(context):
	var dungeon = context.get("dungeon", null)
	if dungeon == null:
		return { executed = false, consumes_turn = false, message = "" }
	var handled = dungeon.execute_interact_command(self)
	return {
		executed = handled,
		consumes_turn = handled,
		message = ""
	}

func to_dict():
	return {
		command_type = command_type,
		interaction_kind = interaction_kind,
		target_cell = target_cell,
		direction = direction
	}
