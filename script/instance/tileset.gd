extends Node

class_name Tileset

var _texture = null
var _branch = null
var _tile_lookup = {}
var _animation_lookup = {}
var cell_width = 32
var cell_height = 32

func set_texture(texture):
	_texture = texture

func set_branch(branch_id):
	_branch = Database.get_branch(branch_id)
	for tile in _branch.tile:
		if ! _tile_lookup.has(tile.name):
			_tile_lookup[tile.name] = []
		var entry = {
			start_x = int(tile.startx) * cell_width,
			start_y = int(tile.starty) * cell_height,
			width = cell_width,
			height = cell_height
		}
		if tile.has("endx"):
			entry.width = (int(tile.endx) - int(tile.startx)) * cell_width
		if tile.has("endy"):
			entry.height = (int(tile.endy) - int(tile.starty)) * cell_height
		_tile_lookup[tile.name].append(entry)

func get_tile(tile_name):
	_tile_lookup[tile_name].shuffle()
	var tile = _tile_lookup[tile_name][0]
	var sprite = Sprite.new()
	sprite.region_enabled = true
	sprite.region_rect = Rect2(tile.start_x, tile.start_y, tile.width, tile.height)
	sprite.texture = _texture
	return sprite

func set_animation(name, start_x, start_y, cell_count, frame_rate_milliseconds):
	_animation_lookup[name] = {
		start_x = start_x * cell_width,
		start_y = start_y * cell_height,
		cell_count = cell_count,
		frame_rate_milliseconds = frame_rate_milliseconds
	}	
	
func get_animation(name):
	var definition = _animation_lookup[name]
	var result = ODAnimation.new()
	result.init()
	var delay_milliseconds = definition.frame_rate_milliseconds
	for ii in range(definition.cell_count):
		var sprite = Sprite.new()
		sprite.region_enabled = true
		sprite.region_rect = Rect2(ii * cell_width, definition.start_y, cell_width, cell_height)
		sprite.texture = _texture
		result.add_sprite_frame(sprite, delay_milliseconds)
	return result
