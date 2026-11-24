extends RefCounted

# https://docs.godotengine.org/en/3.2/tutorials/2d/using_tilemaps.html

class_name Tileset

var _texture = null
var _source_image = null
var _branch = null
var _tile_lookup = {}
var _tile_texture_cache = {}
var _animation_lookup = {}

func set_texture(texture):
	_tile_texture_cache.clear()
	if texture == null:
		_texture = null
		_source_image = null
		return
	var img = texture.get_image()
	if img == null:
		_texture = texture
		_source_image = null
		return
	var converted = img.duplicate()
	if converted.get_format() != Image.FORMAT_RGBA8:
		converted.convert(Image.FORMAT_RGBA8)
	var width = converted.get_width()
	var height = converted.get_height()
	for py in range(height):
		for px in range(width):
			var col = converted.get_pixel(px, py)
			if col.r8 == 0 and col.g8 == 255 and col.b8 == 0:
				converted.set_pixel(px, py, Color(0, 0, 0, 0))
	_source_image = converted
	converted.generate_mipmaps()
	_texture = ImageTexture.create_from_image(converted)

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

func get_liquid_edge_tile_name(has_n, has_s, has_w, has_e, has_nw, has_ne, has_sw, has_se):
	if not has_n and not has_s and not has_w and not has_e:
		return "water_vert_cap_t" if has_tile("water_vert_cap_t") else "water_u"
	if not has_n and not has_s:
		if not has_w:
			return "water_horiz_cap_l"
		if not has_e:
			return "water_horiz_cap_r"
		return "water_horiz"
	if not has_w and not has_e:
		if not has_n:
			return "water_vert_cap_t"
		if not has_s:
			return "water_vert_cap_b"
		return "water_vert"
	if not has_n and not has_w:
		return "water_ul"
	if not has_n and not has_e:
		return "water_ur"
	if not has_s and not has_w:
		return "water_dl"
	if not has_s and not has_e:
		return "water_dr"
	if not has_n:
		return "water_u"
	if not has_s:
		return "water_d"
	if not has_w:
		return "water_l"
	if not has_e:
		return "water_r"
	if not has_nw and not has_ne:
		return "water_corner_ul_ur"
	if not has_sw and not has_se:
		return "water_corner_dl_dr"
	if not has_nw and not has_sw:
		return "water_corner_ul_dl"
	if not has_ne and not has_se:
		return "water_corner_ur_dr"
	if not has_nw:
		return "water_corner_ul"
	if not has_ne:
		return "water_corner_ur"
	if not has_sw:
		return "water_corner_dl"
	if not has_se:
		return "water_corner_dr"
	return "water"

func get_liquid_edge_tile(has_n, has_s, has_w, has_e, has_nw, has_ne, has_sw, has_se):
	var tile_name = get_liquid_edge_tile_name(has_n, has_s, has_w, has_e, has_nw, has_ne, has_sw, has_se)
	if tile_name == "water" or not has_tile(tile_name):
		return null
	return get_tile(tile_name)

func _get_tile_texture(tile):
	if _source_image == null:
		return null
	var region_key = Vector4i(tile.start_x, tile.start_y, tile.width, tile.height)
	if _tile_texture_cache.has(region_key):
		return _tile_texture_cache[region_key]
	var tile_img = _source_image.get_region(Rect2i(tile.start_x, tile.start_y, tile.width, tile.height))
	tile_img.generate_mipmaps()
	var tex = ImageTexture.create_from_image(tile_img)
	_tile_texture_cache[region_key] = tex
	return tex

func get_tile(tile_name):
	if not has_tile(tile_name):
		return Sprite2D.new()
	var options = _tile_lookup[tile_name]
	var tile = options[randi() % options.size()]
	var sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var tile_tex = _get_tile_texture(tile)
	if tile_tex != null:
		sprite.texture = tile_tex
	else:
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
