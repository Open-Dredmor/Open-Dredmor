extends "res://script/instance/entity/entity.gd"

class_name TargetCursor

var entity_kind = "cursor"

var _target
var _selection
var _is_selecting = false

func init():
	_target = OD.Load.animation(OD.Resources.paths.input.tile_target)
	add_child(_target)
	_selection = OD.Load.animation(OD.Resources.paths.input.tile_selected)
	_selection.visible = false
	_selection.stop()
	_selection.animation_complete.connect(_on_selection_complete)
	add_child(_selection)

func _on_selection_complete():
	_is_selecting = false
	_selection.stop()
	_selection.visible = false
	_target.visible = true
	_target.play()

func select(_grid_x, _grid_y):
	if not _is_selecting:
		_is_selecting = true				
		_target.stop()
		_target.visible = false
		_selection.visible = true
		_selection.play()
	
func is_selecting():
	return _is_selecting
