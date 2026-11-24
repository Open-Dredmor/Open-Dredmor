extends RefCounted

class_name MoveToLocationAction

var _entity
var _destination
var _entity_grid = null
var _path = []
var _action_complete = false

func init(entity, grid_destination, entity_grid = null):
	_entity = entity
	_destination = grid_destination
	_entity_grid = entity_grid
	if _entity_grid != null and is_instance_valid(_entity):
		var start_pos = _entity.get_grid_position()
		_path = _entity_grid.find_path(start_pos, grid_destination)
		if _path.is_empty():
			_action_complete = true

func update():
	if not is_instance_valid(_entity):
		_action_complete = true
		return
	if _entity_grid != null:
		if _path.is_empty():
			_entity.idle()
			_action_complete = true
			return
		var next_step = _path[0]
		if not _entity_grid.is_walkable(next_step.x, next_step.y):
			_entity.idle()
			_action_complete = true
			return
		_path.remove_at(0)
		var current_pos = _entity.get_grid_position()
		_entity.move_delta(next_step.x - int(current_pos.x), next_step.y - int(current_pos.y))
		_entity_grid.evaluate_scripts(_entity.get_grid_position())
		if _path.is_empty():
			_entity.idle()
			_action_complete = true
		return
	var diff = _entity.get_grid_position() - _destination
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
