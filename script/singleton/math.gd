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
	var center_x = _grid_center.x if _grid_center != null else 0.0
	var center_y = _grid_center.y if _grid_center != null else 0.0
	var pixel_x = (x + center_x) * OD.Assets.CELL_PIXEL_WIDTH
	var pixel_y = (y + center_y) * OD.Assets.CELL_PIXEL_HEIGHT
	return Vector2(pixel_x, pixel_y)

func pixel_to_grid(pixel_x, pixel_y):
	var center_x = _grid_center.x if _grid_center != null else 0.0
	var center_y = _grid_center.y if _grid_center != null else 0.0
	var grid_x = floor((pixel_x + (OD.Assets.CELL_PIXEL_WIDTH / 2.0)) / OD.Assets.CELL_PIXEL_WIDTH) - center_x
	var grid_y = floor((pixel_y + (OD.Assets.CELL_PIXEL_HEIGHT / 2.0)) / OD.Assets.CELL_PIXEL_HEIGHT) - center_y
	return Vector2(grid_x, grid_y)
