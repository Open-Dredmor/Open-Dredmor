extends Node2D

var _grid_position

func get_grid_position():
	return _grid_position
	
func update_position():
	position = OD.Math.grid_to_pixel(_grid_position.x, _grid_position.y)

func update_animation(delta_x, delta_y):
	pass

func move_to(grid_x, grid_y):
	_grid_position = Vector2(grid_x, grid_y)
	update_position()
	
func move_delta(grid_x, grid_y):
	update_animation(grid_x, grid_y)
	_grid_position.x += grid_x
	_grid_position.y += grid_y	
	update_position()
