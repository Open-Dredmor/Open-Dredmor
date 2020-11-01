extends "res://script/instance/entity/entity.gd"

class_name TargetCursor

var entity_kind = "cursor"

var _target
var _selection
var _is_selecting = false

func init():
	_target = Load.animation(ODResource.paths.input.tile_target)
	add_child(_target)
	_selection = Load.animation(ODResource.paths.input.tile_selected)
	_selection.set_animation_id("player_target_cursor")
	_selection.stop()
	_selection.connect("animation_complete", self, "_on_selection_complete")

func _on_selection_complete(animation_id):
	if animation_id == "player_target_cursor":		
		_is_selecting = false
		_selection.stop()
		remove_child(_selection)
		add_child(_target)		
		_target.play()

func select(_grid_x, _grid_y):
	if not _is_selecting:
		_is_selecting = true
		add_child(_selection)
		_selection.play()
		remove_child(_target)
	
func is_selecting():
	return _is_selecting
