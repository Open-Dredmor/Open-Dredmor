extends RefCounted

# https://docs.godotengine.org/en/3.2/tutorials/2d/using_tilemaps.html

class_name Tileset

var _texture = null
var _branch = null
var _tile_lookup = {}
var _animation_lookup = {}

func set_texture(texture):
	_texture = texture

func set_branch(branch_id):
	_branch = OD.Database.get_branch(branch_id)
	for tile in _branch.tile:
		if ! _tile_lookup.has(tile.name):
			_tile_lookup[tile.name] = []
		var entry = {
			start_x = int(tile.startx) * OD.Assets.CELL_PIXEL_WIDTH,
			start_y = int(tile.starty) * OD.Assets.CELL_PIXEL_HEIGHT,
			width = OD.Assets.CELL_PIXEL_WIDTH,
			height = OD.Assets.CELL_PIXEL_HEIGHT
		}
		if tile.has("endx"):
			entry.width = (int(tile.endx) - int(tile.startx) + 1) * OD.Assets.CELL_PIXEL_WIDTH
		if tile.has("endy"):
			entry.height = (int(tile.endy) - int(tile.starty) + 1) * OD.Assets.CELL_PIXEL_HEIGHT
		_tile_lookup[tile.name].append(entry)

func has_tile(tile_name):
	return _tile_lookup.has(tile_name) and not _tile_lookup[tile_name].is_empty()

func get_wall_tile_name(has_north, has_south, has_west, has_east):
	if not has_south:
		if not has_west and not has_east:
			return "wall_lr" if has_tile("wall_lr") else "wall"
		if not has_west:
			return "wall_l" if has_tile("wall_l") else "wall"
		if not has_east:
			return "wall_r" if has_tile("wall_r") else "wall"
		return "wall"
	if not has_north:
		if not has_west and not has_east:
			return "top_ud" if has_tile("top_ud") else "top_u"
		if not has_west:
			return "top_ul" if has_tile("top_ul") else "top_u"
		if not has_east:
			return "top_ur" if has_tile("top_ur") else "top_u"
		return "top_u"
	if not has_west and not has_east:
		return "top_lr" if has_tile("top_lr") else "top_c"
	if not has_west:
		return "top_l" if has_tile("top_l") else "top_c"
	if not has_east:
		return "top_r" if has_tile("top_r") else "top_c"
	return "top_c" if has_tile("top_c") else "wall"

func get_wall_tile(has_north, has_south, has_west, has_east):
	var tile_name = get_wall_tile_name(has_north, has_south, has_west, has_east)
	if not has_tile(tile_name):
		tile_name = "wall"
	return get_tile(tile_name)

func get_tile(tile_name):
	if not has_tile(tile_name):
		return Sprite2D.new()
	var options = _tile_lookup[tile_name]
	var tile = options[randi() % options.size()]
	var sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(tile.start_x, tile.start_y, tile.width, tile.height)
	sprite.texture = _texture
	if tile.height > OD.Assets.CELL_PIXEL_HEIGHT:
		sprite.offset.y = -float(tile.height - OD.Assets.CELL_PIXEL_HEIGHT) / 2.0
	return sprite

func set_animation(name, start_x, start_y, cell_count, frame_rate_milliseconds):
	_animation_lookup[name] = {
		start_x = start_x * OD.Assets.CELL_PIXEL_WIDTH,
		start_y = start_y * OD.Assets.CELL_PIXEL_HEIGHT,
		cell_count = cell_count,
		frame_rate_milliseconds = frame_rate_milliseconds
	}	
	
func get_animation(name):
	var definition = _animation_lookup[name]
	var result = OD.Animations.new()
	result.init()
	var delay_milliseconds = definition.frame_rate_milliseconds
	for ii in range(definition.cell_count):
		var frame_data = {
			region_rect = Rect2(ii * OD.Assets.CELL_PIXEL_WIDTH, definition.start_y, OD.Assets.CELL_PIXEL_WIDTH, OD.Assets.CELL_PIXEL_HEIGHT),
			texture = _texture
		}
		result.add_sprite_frame(frame_data, delay_milliseconds)
	return result
