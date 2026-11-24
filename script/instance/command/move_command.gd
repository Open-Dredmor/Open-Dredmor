extends "res://script/instance/command/game_command.gd"

class_name MoveCommand

var delta = Vector2i.ZERO
var destination = null
var is_path = false
var debug_teleport = false

func init_step(target_actor, step_delta):
	command_type = "move"
	actor = target_actor
	delta = Vector2i(int(step_delta.x), int(step_delta.y))
	destination = null
	is_path = false
	debug_teleport = false
	return self

func init_path(target_actor, target_cell, use_debug_teleport = false):
	command_type = "move"
	actor = target_actor
	delta = Vector2i.ZERO
	destination = Vector2i(int(target_cell.x), int(target_cell.y))
	is_path = not use_debug_teleport
	debug_teleport = use_debug_teleport
	return self

func can_execute(context):
	var dungeon = context.get("dungeon", null)
	var entity_grid = context.get("entity_grid", null)
	var target_actor = actor if actor != null else context.get("player", null)
	if dungeon == null or entity_grid == null or target_actor == null or not is_instance_valid(target_actor):
		return false
	if debug_teleport and destination != null:
		return true
	if delta != Vector2i.ZERO:
		var current_pos = target_actor.get_grid_position()
		var next_cell = Vector2i(int(current_pos.x) + delta.x, int(current_pos.y) + delta.y)
		return entity_grid.is_walkable(next_cell.x, next_cell.y)
	if is_path and destination != null:
		return entity_grid.is_walkable(destination.x, destination.y)
	return false

func execute(context):
	var dungeon = context.get("dungeon", null)
	var entity_grid = context.get("entity_grid", null)
	var target_actor = actor if actor != null else context.get("player", null)
	var target_cursor = context.get("target_cursor", null)
	if dungeon == null or entity_grid == null or target_actor == null:
		return { executed = false, consumes_turn = false, message = "" }
	if debug_teleport and destination != null:
		dungeon.clear_pending_interaction()
		OD.ActionQueue.clear()
		if target_cursor != null:
			target_cursor.select(destination.x, destination.y)
		target_actor.move_to(destination.x, destination.y)
		target_actor.idle()
		entity_grid.on_player_step(target_actor.get_grid_position())
		var debug_stairs = entity_grid.get_stairs_at(destination.x, destination.y)
		if debug_stairs != null:
			dungeon.change_floor_to(debug_stairs.direction)
		return { executed = true, consumes_turn = false, message = "" }
	if delta != Vector2i.ZERO:
		var current_pos = target_actor.get_grid_position()
		var next_cell = Vector2i(int(current_pos.x) + delta.x, int(current_pos.y) + delta.y)
		if not entity_grid.is_walkable(next_cell.x, next_cell.y):
			return { executed = false, consumes_turn = false, message = "" }
		dungeon.clear_pending_interaction()
		OD.ActionQueue.clear()
		target_actor.move_delta(delta.x, delta.y)
		target_actor.idle()
		entity_grid.on_player_step(target_actor.get_grid_position())
		return { executed = true, consumes_turn = true, message = "" }
	if is_path and destination != null:
		if not entity_grid.is_walkable(destination.x, destination.y):
			return { executed = false, consumes_turn = false, message = "" }
		dungeon.clear_pending_interaction()
		if target_cursor != null:
			target_cursor.select(destination.x, destination.y)
		OD.ActionQueue.clear()
		var action = OD.Actions.MoveToLocation.new()
		action.init(target_actor, destination, entity_grid)
		OD.ActionQueue.add(action)
		return { executed = true, consumes_turn = true, message = "" }
	return { executed = false, consumes_turn = false, message = "" }

func to_dict():
	return {
		command_type = command_type,
		delta = delta,
		destination = destination,
		is_path = is_path,
		debug_teleport = debug_teleport
	}
