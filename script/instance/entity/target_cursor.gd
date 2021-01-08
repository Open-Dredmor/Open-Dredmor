extends "res://script/instance/entity/entity.gd"

class_name TargetCursor

var entity_kind = "cursor"

var _target
var _selection
var _is_selecting = false

func init():
	_target = OD.Load.animation(OD.Resource.paths.input.tile_target)
	add_child(_target)
	_selection = OD.Load.animation(OD.Resource.paths.input.tile_selected)
	_selection.stop()
	_selection.connect("animation_complete", self, "_on_selection_complete")

func _on_selection_complete():
	print("Selection animation complete")
	_is_selecting = false
	_selection.stop()
	remove_child(_selection)
	add_child(_target)		
	_target.play()

func select(_grid_x, _grid_y):
	if not _is_selecting:
		print("Selecting "+str(_grid_x)+" X and "+str(_grid_y)+" Y")
		_is_selecting = true				
		_target.stop()
		remove_child(_target)
		add_child(_selection)
		_selection.play()
	
func is_selecting():
	return _is_selecting
