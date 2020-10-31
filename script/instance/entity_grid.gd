extends Node2D

class_name EntityGrid

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

func init():
	_tilesets = Assets.tilesets()	
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
	position = Vector2(-_grid_center.x * Assets.CELL_PIXEL_WIDTH, -_grid_center.y * Assets.CELL_PIXEL_HEIGHT)

func get_pixel_position(grid_x, grid_y):
	var x = (grid_x + _grid_center.x) * Assets.CELL_PIXEL_WIDTH
	var y = (grid_y + _grid_center.y) * Assets.CELL_PIXEL_HEIGHT
	return Vector2(x, y)

func insert(source_grid, offset_position):
	for layer_key in source_grid.layers.lookup.keys():
		var source_layer = source_grid.layers.lookup[layer_key]
		var target_layer = layers.lookup[layer_key]
		for child in source_layer.get_children():
			child.get_parent().remove_child(child)
			child.position = get_pixel_position(child.position.x + offset_position.x, child.position.y + offset_position.y)
			# Compensate for sprites greater than 1 tile height not being properly anchored.
			# Might be another root cause, but this fixes the graphical problem of 2+ tile high sprites being drawn slightly too low
			if child.has_method('is_tall'):				
				if child.is_tall():
					child.position.y -= Assets.CELL_PIXEL_HEIGHT / 2
			target_layer.add_child(child)
				
func get_layer(name):
	if xml_name_to_layer_name.has(name):
		return layers.lookup[xml_name_to_layer_name[name]]
	else:
		return layers.lookup[name]

func add_entity(grid_x, grid_y, entity):
	var layer = get_layer(entity.entity_kind)
	entity.position = get_pixel_position(grid_x, grid_y)
	layer.add_child(entity)

func add_animation(x, y, name, animation):
	var layer = get_layer(name)
	animation.position = Vector2(x, y)	
	layer.add_child(animation)

func add_tile(x, y, name, sprite_path = null):
	var layer = get_layer(name)
	var tile = null
	match name:
		"floor","wall":
			tile = _tilesets.basic.get_tile(name)
		"ice","lava","goo","water":
			tile = _tilesets.liquids.get_animation(name)			
		_:
			tile = Load.animation(sprite_path)
	tile.position = Vector2(x, y)
	layer.add_child(tile)
	
func move(target_x, target_y, entity):
	entity.position = get_pixel_position(target_x, target_y)
