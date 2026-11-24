extends RefCounted

class_name MoveToLocationAction

signal completed(reached_destination)

var _entity
var _destination
var _entity_grid = null
var _path = []
var _action_complete = false
var _started_with_visible_enemy = false
var interrupted_reason = ""

func init(entity, grid_destination, entity_grid = null):
	_entity = entity
	_destination = Vector2i(int(grid_destination.x), int(grid_destination.y))
	_entity_grid = entity_grid
	interrupted_reason = ""
	if _entity_grid != null and is_instance_valid(_entity):
		var start_pos = _entity.get_grid_position()
		if _entity.get("entity_kind") == "player" and start_pos != null:
			_started_with_visible_enemy = _entity_grid.has_visible_enemy(Vector2i(int(start_pos.x), int(start_pos.y)))
		_path = _entity_grid.find_path(start_pos, _destination, { avoid_hazards = true })
		if _path.is_empty():
			_action_complete = true
			completed.emit(false)

func update():
	if not is_instance_valid(_entity):
		_action_complete = true
		completed.emit(false)
		return
	if _entity_grid != null:
		if _path.is_empty():
			_entity.set_continuous_walk(false)
			if not _entity.is_moving():
				_entity.idle()
			_action_complete = true
			completed.emit(true)
			return
		var current_pos = _entity.get_grid_position()
		var current_cell = Vector2i(int(current_pos.x), int(current_pos.y))
		if _entity.get("entity_kind") == "player" and not _started_with_visible_enemy and _path.size() > 1 and _entity_grid.has_visible_enemy(current_cell):
			interrupted_reason = "enemy_spotted"
			_entity.set_continuous_walk(false)
			_entity.idle()
			_action_complete = true
			completed.emit(false)
			return
		var next_step = _path[0]
		if _entity_grid.has_enemy_at(next_step.x, next_step.y):
			interrupted_reason = "enemy"
			_entity.set_continuous_walk(false)
			_entity.idle()
			_action_complete = true
			completed.emit(false)
			return
		if _entity_grid.is_hazard(next_step.x, next_step.y):
			interrupted_reason = "hazard"
			_entity.set_continuous_walk(false)
			_entity.idle()
			_action_complete = true
			completed.emit(false)
			return
		if not _entity_grid.is_walkable(next_step.x, next_step.y):
			interrupted_reason = "blocked"
			_entity.set_continuous_walk(false)
			_entity.idle()
			_action_complete = true
			completed.emit(false)
			return
		_path.remove_at(0)
		_entity.set_continuous_walk(not _path.is_empty())
		_entity.move_delta(next_step.x - current_cell.x, next_step.y - current_cell.y)
		_entity_grid.move_entity(_entity, current_cell, _entity.get_grid_position())
		_entity_grid.on_player_step(_entity.get_grid_position())
		if _path.is_empty():
			if not _entity.is_moving():
				_entity.idle()
			_action_complete = true
			completed.emit(true)
		return
	var diff = _entity.get_grid_position() - Vector2(_destination.x, _destination.y)
	if diff.x != 0:
		if diff.x < 0:
			_entity.move_delta(1, 0)
		else:
			_entity.move_delta(-1, 0)
	elif diff.y != 0:
		if diff.y < 0:
			_entity.move_delta(0, 1)
		else:
			_entity.move_delta(0, -1)
	else:
		_entity.idle()
		_action_complete = true

func is_complete():
	return _action_complete
