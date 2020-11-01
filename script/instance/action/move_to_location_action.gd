extends Node

class_name MoveToLocationAction

var _entity
var _destination
var _action_complete = false

func init(entity, grid_destination):
	_entity = entity
	_destination = grid_destination
	
func update():
	var diff = _entity.get_grid_position() - _destination
	# TODO implement proper pathfinding and movement blocking
	if abs(diff.x) > abs(diff.y):
		if diff.x < 0:
			_entity.move_delta(1, 0)
		else:
			_entity.move_delta(-1, 0)
	else:
		if diff.y < 0:
			_entity.move_delta(0, 1)
		else:
			_entity.move_delta(0, -1)
	if diff.x == 0 and diff.y == 0:
		_action_complete = true
	

func is_complete():
	return _action_complete
