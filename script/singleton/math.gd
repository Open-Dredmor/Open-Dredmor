extends Node

var _succeed = null
var _grid_center

func fixed_chances(succeed):
	_succeed = succeed

func chance(text_value):
	if _succeed != null:
		return _succeed
	if text_value == null:
		return true
	var float_value = float(text_value) / float(100)
	var percent = randf()
	return percent <= float_value

func set_grid_center(grid_x, grid_y):
	_grid_center = Vector2(grid_x, grid_y)

func grid_to_pixel(x, y):
	var pixel_x = (x + _grid_center.x) * OD.Assets.CELL_PIXEL_WIDTH
	var pixel_y = (y + _grid_center.y) * OD.Assets.CELL_PIXEL_HEIGHT
	return Vector2(pixel_x, pixel_y)
	
func pixel_to_grid(_x, _y):
	pass
