extends Node2D

class_name EntityGrid

var layers = {
	list = [],
	lookup = {}
}

var layer_names = [
	"liquid",
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
	"wall",
	"wall_decoration",
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

func get_layer(name):
	if xml_name_to_layer_name.has(name):
		return layers.lookup[xml_name_to_layer_name[name]]
	else:
		return layers.lookup[name]

func add_animation(x, y, name, animation):
	var layer = get_layer(name)
	animation.position = Vector2(x * Assets.CELL_PIXEL_WIDTH, y * Assets.CELL_PIXEL_HEIGHT)
	layer.add_child(animation)
	if animation.has_method("play"):
		animation.play()

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
	if tile.has_method("play"):
		tile.play()
