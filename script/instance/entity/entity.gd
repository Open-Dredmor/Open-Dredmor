extends Node2D

var _grid_position
var _move_tween = null
var _is_moving = false
var _continuous_walk = false

func get_grid_position():
	return _grid_position

func is_moving():
	return _is_moving

func set_continuous_walk(enabled):
	_continuous_walk = enabled

func update_position(smooth = false):
	var target_px = OD.Math.grid_to_pixel(_grid_position.x, _grid_position.y)
	if is_instance_valid(_move_tween):
		_move_tween.kill()
		_move_tween = null
	_is_moving = false
	if smooth and is_inside_tree():
		var game_speed = 1.0
		if OD.Settings != null and OD.Settings.has_method("get_game_speed"):
			game_speed = OD.Settings.get_game_speed()
		var base_turn = 0.5
		if OD.DungeonSettings != null and OD.DungeonSettings.get_settings() != null:
			base_turn = float(OD.DungeonSettings.get_settings().get("base_turn_seconds", 0.5))
		var duration = ((base_turn * 0.5) / max(0.01, game_speed)) * 0.85
		if duration > 0.01:
			_is_moving = true
			_move_tween = create_tween()
			_move_tween.tween_property(self, "position", target_px, duration)
			_move_tween.finished.connect(func():
				_is_moving = false
				if not _continuous_walk:
					idle()
			)
			return
	position = target_px
	if smooth and not _continuous_walk:
		idle()

func update_animation(delta_x, delta_y):
	pass

func idle():
	pass

func move_to(grid_x, grid_y):
	_grid_position = Vector2(grid_x, grid_y)
	update_position(false)

func move_delta(grid_x, grid_y):
	update_animation(grid_x, grid_y)
	_grid_position.x += grid_x
	_grid_position.y += grid_y
	update_position(true)
