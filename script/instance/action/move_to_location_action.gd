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
	#print("From ", _entity.get_grid_position())
	#print("To ", _destination)
	#print("Diff ", diff)
	# TODO implement proper pathfinding and movement blocking
	if diff.x != 0 and abs(diff.x) > abs(diff.y):
		if diff.x < 0:
			#print("Move left")
			_entity.move_delta(1, 0)
		else:
			#print("Move right")
			_entity.move_delta(-1, 0)
	if diff.y != 0 and abs(diff.y) > abs(diff.x):
		if diff.y < 0:
			#print("Move down")
			_entity.move_delta(0, 1)
		else:
			#print("Move up")
			_entity.move_delta(0, -1)
	if diff.x == 0 and diff.y == 0:
		#print("Complete")
		_action_complete = true
	

func is_complete():
	return _action_complete
