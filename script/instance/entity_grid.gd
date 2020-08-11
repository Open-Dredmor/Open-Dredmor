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
	"custom_blocker",
	"statue",
	"custom_engraving",
	"element",	
	"loot",
	"horde",
	"monster",
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

func recenter(x, y):
	_grid_center = Vector2(x, y)

func insert(source_grid, position):
	for layer_key in source_grid.layers.lookup.keys():
		var source_layer = source_grid.layers.lookup[layer_key]
		var target_layer = layers.lookup[layer_key]
		for child in source_layer.get_children():
			child.get_parent().remove_child(child)
			child.position = Vector2(child.position.x + position.x + _grid_center.x, child.position.y + position.y + _grid_center.y)
			target_layer.add_child(child)
				
func get_layer(name):
	if xml_name_to_layer_name.has(name):
		return layers.lookup[xml_name_to_layer_name[name]]
	else:
		return layers.lookup[name]

func add_animation(x, y, name, animation):
	var layer = get_layer(name)
	animation.position = Vector2(x * Assets.CELL_PIXEL_WIDTH, y * Assets.CELL_PIXEL_HEIGHT)
	layer.add_child(animation)

func add_tile(x, y, name, sprite_path = null):
	var layer = get_layer(name)
	var tile = null
	match name:
		"floor","wall":
			tile = _tilesets.basic.get_tile(name)
		"ice","lava","goo","water":
			tile = _tilesets.liquids.get_animation(name)
		"wall_decoration","floor_decoration":
			tile = Load.animation(sprite_path)
		_:
			pass
	tile.position = Vector2(x * Assets.CELL_PIXEL_WIDTH, y * Assets.CELL_PIXEL_HEIGHT)
	layer.add_child(tile)
