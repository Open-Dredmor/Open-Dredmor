extends Node2D

class_name EntityGrid

const DoorScript = preload("res://script/instance/entity/door.gd")

var layers = {
	list = [],
	lookup = {}
}

var layer_names = [
	"liquid",
	"wall",
	"wall_decoration",
	"floor",
	"floor_decoration",
	"trap",
	"custom_blocker",
	"custom_breakable",
	"pedestal",
	"statue",
	"custom_engraving",
	"element",	
	"loot",
	"horde",
	"monster",
	"cursor",
	"player",
]

var xml_name_to_layer_name = {
	"customengraving": "custom_engraving",
	"customblocker": "custom_blocker",
	"lava": "liquid",
	"ice": "liquid",
	"goo": "liquid",
	"water": "liquid" 
}

var animated_tile_lookup = {
	water = true,
	lava = true,
	ice = true,
	goo = true
}

var _tilesets
var _grid_lookup = null
var _grid_center = null
var _wall_cells = {}
var _floor_cells = {}
var _destructible_cells = {}
var _blocker_cells = {}
var _doors_by_cell = {}

func init(branch_id = 0):
	_tilesets = OD.Assets.tileset_for_branch(branch_id)
	var layer_order = 0
	for layer_name in layer_names:
		layer_order += 1
		var layer = Node2D.new()
		layer.name = layer_name
		layer.z_index = layer_order
		layers.lookup[layer.name] = layer
		layers.list.append(layer)
		add_child(layer)

func resize(grid_width, grid_height):
	_grid_lookup = {}
	for ii in range(grid_width):
		_grid_lookup[ii] = {}
		for jj in range(grid_height):
			_grid_lookup[ii][jj] = {}
	_grid_center = Vector2(grid_width / 2, grid_height / 2)
	OD.Math.set_grid_center(_grid_center.x, _grid_center.y)
	position = Vector2(-_grid_center.x * OD.Assets.CELL_PIXEL_WIDTH, -_grid_center.y * OD.Assets.CELL_PIXEL_HEIGHT)

func insert(source_grid, offset_position):
	var offset_cell = Vector2i(int(offset_position.x), int(offset_position.y))
	for wall_cell in source_grid._wall_cells.keys():
		_wall_cells[wall_cell + offset_cell] = true
	for floor_cell in source_grid._floor_cells.keys():
		_floor_cells[floor_cell + offset_cell] = true
	for destructible_cell in source_grid._destructible_cells.keys():
		_destructible_cells[destructible_cell + offset_cell] = true
	for blocker_cell in source_grid._blocker_cells.keys():
		_blocker_cells[blocker_cell + offset_cell] = true
	for layer_key in source_grid.layers.lookup.keys():
		var source_layer = source_grid.layers.lookup[layer_key]
		var target_layer = layers.lookup[layer_key]
		for child in source_layer.get_children():
			child.get_parent().remove_child(child)
			child.position = OD.Math.grid_to_pixel(child.position.x + offset_position.x, child.position.y + offset_position.y)
			# Compensate for sprites greater than 1 tile height not being properly anchored.
			# Might be another root cause, but this fixes the graphical problem of 2+ tile high sprites being drawn slightly too low
			if child.has_method('is_tall'):				
				if child.is_tall():
					child.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2
			target_layer.add_child(child)
				
func get_layer(name):
	if xml_name_to_layer_name.has(name):
		return layers.lookup[xml_name_to_layer_name[name]]
	else:
		return layers.lookup[name]

func add_entity(grid_x, grid_y, entity):
	var layer = get_layer(entity.entity_kind)
	entity.position = OD.Math.grid_to_pixel(grid_x, grid_y)
	entity.move_to(grid_x, grid_y)
	layer.add_child(entity)

func add_animation(x, y, name, animation):
	var layer = get_layer(name)
	animation.position = Vector2(x, y)	
	layer.add_child(animation)

func add_tile(x, y, name, sprite_path = null):
	var layer = get_layer(name)
	var tile = null
	var cell_key = Vector2i(int(x), int(y))
	match name:
		"floor":
			_floor_cells[cell_key] = true
			tile = _tilesets.basic.get_tile(name)
		"wall":
			_wall_cells[cell_key] = true
			tile = _tilesets.basic.get_tile(name)
		"ice","lava","goo","water":
			tile = _tilesets.liquids.get_animation(name)			
		_:
			tile = OD.Load.animation(sprite_path)
	tile.position = Vector2(x, y)
	layer.add_child(tile)

func mark_destructible(grid_x, grid_y):
	_destructible_cells[Vector2i(int(grid_x), int(grid_y))] = true

func mark_blocker(grid_x, grid_y):
	_blocker_cells[Vector2i(int(grid_x), int(grid_y))] = true

func is_destructible(grid_x, grid_y):
	return _destructible_cells.has(Vector2i(int(grid_x), int(grid_y)))

func is_blocked(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _wall_cells.has(cell_key) or _blocker_cells.has(cell_key):
		return true
	if _doors_by_cell.has(cell_key):
		var door = _doors_by_cell[cell_key]
		if is_instance_valid(door) and not door.can_pass():
			return true
	return false

func is_walkable(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	return _floor_cells.has(cell_key) and not is_blocked(grid_x, grid_y)

func find_path(start_cell, goal_cell, max_visited = 4096):
	var start = Vector2i(int(start_cell.x), int(start_cell.y))
	var goal = Vector2i(int(goal_cell.x), int(goal_cell.y))
	if start == goal or not is_walkable(goal.x, goal.y):
		return []
	var frontier = [start]
	var came_from = {}
	came_from[start] = start
	var visited_count = 0
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var found = false
	var head = 0
	while head < frontier.size() and visited_count < max_visited:
		var current = frontier[head]
		head += 1
		visited_count += 1
		if current == goal:
			found = true
			break
		for dir in directions:
			var next_cell = current + dir
			if came_from.has(next_cell):
				continue
			if not is_walkable(next_cell.x, next_cell.y):
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)
	if not found:
		return []
	var path = []
	var step = goal
	while step != start:
		path.append(step)
		step = came_from[step]
	path.reverse()
	return path

func add_door(grid_x, grid_y, orientation = "ew", locked = false):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _doors_by_cell.has(cell_key):
		return _doors_by_cell[cell_key]
	var door = DoorScript.new()
	door.init(orientation, locked)
	add_entity(grid_x, grid_y, door)
	_doors_by_cell[cell_key] = door
	return door

func get_door_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _doors_by_cell.has(cell_key):
		var door = _doors_by_cell[cell_key]
		if is_instance_valid(door):
			return door
	return null

func auto_tile_walls():
	var wall_layer = layers.lookup["wall"]
	for child in wall_layer.get_children():
		wall_layer.remove_child(child)
		child.queue_free()
	for cell in _wall_cells.keys():
		var has_north = _wall_cells.has(cell + Vector2i(0, -1))
		var has_south = _wall_cells.has(cell + Vector2i(0, 1))
		var has_west = _wall_cells.has(cell + Vector2i(-1, 0))
		var has_east = _wall_cells.has(cell + Vector2i(1, 0))
		var tile = _tilesets.basic.get_wall_tile(has_north, has_south, has_west, has_east)
		tile.position = OD.Math.grid_to_pixel(cell.x, cell.y)
		wall_layer.add_child(tile)
	
func move(target_x, target_y, entity):
	entity.position = OD.Math.grid_to_pixel(target_x, target_y)
