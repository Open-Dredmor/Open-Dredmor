extends Node2D

class_name Dungeon

var floors = []
# TODO Use ID instead of name
var _branch_name = "The Dungeon"
var _floor_level = 1
var _entity_grid
var _target_cursor
var _player

var FLOOR_STRATEGY = {
	CONNECT_DOORS = "connect_doors",
	DEBUG_ROOMS = "debug_rooms",
	ALL_ROOMS = "all_rooms",
	CENTER_PACK = "center_pack"
}

func global_coordinates_to_grid(x, y):
	var grid_x = floor((x - get_global_transform_with_canvas().origin.x + (Assets.CELL_PIXEL_WIDTH / 2)) / Assets.CELL_PIXEL_WIDTH)
	var grid_y = floor((y - get_global_transform_with_canvas().origin.y + (Assets.CELL_PIXEL_HEIGHT / 2)) / Assets.CELL_PIXEL_HEIGHT)
	return Vector2(grid_x, grid_y)
func init():	
	call_deferred("_build_ui")

func _input(ev):
	if ev is InputEventKey and ev.is_pressed():
		if ev.scancode == KEY_SPACE and not ev.echo:
			Scenes.goto(Scenes.GAME)
	if ev is InputEventMouseMotion:
		if _target_cursor != null and _entity_grid != null and ! _target_cursor.is_selecting():
			var grid_coords = global_coordinates_to_grid(ev.position.x, ev.position.y)
			_entity_grid.move(grid_coords.x, grid_coords.y, _target_cursor)
	if ev is InputEventMouseButton and ev.pressed and _target_cursor != null:
		var grid_coords = global_coordinates_to_grid(ev.position.x, ev.position.y)
		_target_cursor.select(grid_coords.x, grid_coords.y)
		var action = OD.Actions.MoveToLocation.new()
		action.init(_player, grid_coords)
		OD.ActionQueue.add(action)

func _build_ui():
	var strategy = FLOOR_STRATEGY.DEBUG_ROOMS	
	_player = PlayerCharacter.new()	
	_player.init()
	var settings = DungeonSettings.get_settings()
	_entity_grid = load("res://script/instance/room_placement/" + strategy + "_strategy.gd").generate(_branch_name, _floor_level)
	_entity_grid.name = "EntityGrid-"+strategy+"_strategy"
	_entity_grid.add_entity(settings.player_start_x, settings.player_start_y, _player)
	add_child(_entity_grid)
	_target_cursor = TargetCursor.new()
	_target_cursor.init()
	_entity_grid.add_entity(0, 0, _target_cursor)
		
