extends "res://script/instance/command/game_command.gd"

class_name WaitCommand

func init(target_actor = null):
	command_type = "wait"
	actor = target_actor
	return self

func can_execute(context):
	var target_actor = actor if actor != null else context.get("player", null)
	return target_actor != null and is_instance_valid(target_actor) and context.get("entity_grid", null) != null

func execute(context):
	var entity_grid = context.get("entity_grid", null)
	var target_actor = actor if actor != null else context.get("player", null)
	if entity_grid == null or target_actor == null:
		return { executed = false, consumes_turn = false, message = "" }
	target_actor.idle()
	entity_grid.on_player_step(target_actor.get_grid_position())
	return {
		executed = true,
		consumes_turn = true,
		message = ""
	}
