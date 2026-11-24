extends "res://script/instance/command/game_command.gd"

class_name CastSpellCommand

var spell_name = ""
var target_cell = Vector2i.ZERO

func init(target_actor, spell_id, cell = Vector2i.ZERO):
	command_type = "cast_spell"
	actor = target_actor
	spell_name = spell_id
	target_cell = Vector2i(int(cell.x), int(cell.y))
	return self

func can_execute(context):
	return spell_name != "" and context.get("dungeon", null) != null

func execute(context):
	var dungeon = context.get("dungeon", null)
	if dungeon == null:
		return { executed = false, consumes_turn = false, message = "" }
	var handled = dungeon.execute_cast_spell(spell_name, target_cell)
	return {
		executed = handled,
		consumes_turn = handled,
		message = ""
	}

func to_dict():
	return {
		command_type = command_type,
		spell_name = spell_name,
		target_cell = target_cell
	}
