extends Control

class_name MinimapOverlay

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const MIN_ZOOM = 1
const MAX_ZOOM = 4
const MAP_GRID_SIZE = 100
const FRAME_BORDER_PX = 5

const BG_PATHS = {
	1: "ui/gameplay/minimap_bg1x.png",
	2: "ui/gameplay/minimap_bg2x.png",
	3: "ui/gameplay/minimap_bg3x.png",
	4: "ui/gameplay/minimap_bg4x.png"
}

const ZOOM_SUFFIX = {
	1: "",
	2: "_2x",
	3: "_3x",
	4: "_4x"
}

const COLOR_UNEXPLORED = Color(0.0, 0.0, 0.0, 1.0)
const COLOR_FLOOR = Color(0.05, 0.05, 0.06, 1.0)
const COLOR_WALL = Color(0.72, 0.72, 0.74, 1.0)
const COLOR_DOOR_CLOSED = Color(0.60, 0.38, 0.16, 1.0)
const COLOR_DOOR_LOCKED = Color(0.78, 0.52, 0.18, 1.0)
const COLOR_DOOR_OPEN = Color(0.30, 0.20, 0.12, 1.0)
const COLOR_LAVA = Color(0.95, 0.30, 0.05, 1.0)
const COLOR_WATER = Color(0.18, 0.45, 0.85, 1.0)
const COLOR_ICE = Color(0.55, 0.82, 0.96, 1.0)
const COLOR_GOO = Color(0.35, 0.78, 0.25, 1.0)

signal zoom_changed(zoom_level)

var _dungeon = null
var _zoom_level = 1
var _frame_rect = null
var _map_canvas = null
var _floor_label = null
var _zoom_in_button = null
var _zoom_out_button = null
var _icon_cache = {}
var _terrain_image = null
var _terrain_texture = null

class MinimapCanvas extends Control:
	var owner_overlay = null

	func _draw():
		if owner_overlay != null:
			owner_overlay._draw_map_contents(self)

func init(dungeon, initial_zoom = 1):
	_dungeon = dungeon
	_zoom_level = clamp(int(initial_zoom), MIN_ZOOM, MAX_ZOOM)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	_apply_zoom_layout()
	refresh()
	return self

func _load_tex(path):
	return UiHelpers.load_texture(path, _icon_cache)

func _build_controls():
	_frame_rect = TextureRect.new()
	_frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_frame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_frame_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame_rect)

	_map_canvas = MinimapCanvas.new()
	_map_canvas.owner_overlay = self
	_map_canvas.clip_contents = true
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map_canvas)

	_floor_label = Label.new()
	UiHelpers.style_label(_floor_label, 11, Color(0.92, 0.92, 0.94), null, 2)
	_floor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_floor_label)

	_zoom_in_button = UiHelpers.make_texture_button({
		normal = "ui/gameplay/minimap_but_maximize0.png",
		hover = "ui/gameplay/minimap_but_maximize1.png",
		pressed = "ui/gameplay/minimap_but_maximize1.png"
	}, Vector2(14, 14), _icon_cache)
	_zoom_in_button.size = Vector2(14, 14)
	_zoom_in_button.tooltip_text = "Zoom In (+ / Tab)"
	_zoom_in_button.pressed.connect(zoom_in)
	add_child(_zoom_in_button)

	_zoom_out_button = UiHelpers.make_texture_button({
		normal = "ui/gameplay/minimap_but_minimize0.png",
		hover = "ui/gameplay/minimap_but_minimize1.png",
		pressed = "ui/gameplay/minimap_but_minimize1.png"
	}, Vector2(14, 14), _icon_cache)
	_zoom_out_button.size = Vector2(14, 14)
	_zoom_out_button.tooltip_text = "Zoom Out (-)"
	_zoom_out_button.pressed.connect(zoom_out)
	add_child(_zoom_out_button)

	_terrain_image = Image.create(MAP_GRID_SIZE, MAP_GRID_SIZE, false, Image.FORMAT_RGBA8)
	_terrain_texture = ImageTexture.create_from_image(_terrain_image)

func get_zoom_level():
	return _zoom_level

func set_zoom(level):
	var clamped = clamp(int(level), MIN_ZOOM, MAX_ZOOM)
	if clamped == _zoom_level:
		return
	_zoom_level = clamped
	_apply_zoom_layout()
	refresh()
	zoom_changed.emit(_zoom_level)

func zoom_in():
	set_zoom(_zoom_level + 1)

func zoom_out():
	set_zoom(_zoom_level - 1)

func cycle_zoom(reverse = false):
	if reverse:
		set_zoom(MAX_ZOOM if _zoom_level <= MIN_ZOOM else _zoom_level - 1)
	else:
		set_zoom(MIN_ZOOM if _zoom_level >= MAX_ZOOM else _zoom_level + 1)

func toggle_full_view():
	set_zoom(MIN_ZOOM if _zoom_level == MAX_ZOOM else MAX_ZOOM)

func get_frame_size():
	var inner = float(MAP_GRID_SIZE * _zoom_level)
	var total = inner + FRAME_BORDER_PX * 2.0
	return Vector2(total, total)

func _apply_zoom_layout():
	var frame_size = get_frame_size()
	var inner_size = Vector2(MAP_GRID_SIZE * _zoom_level, MAP_GRID_SIZE * _zoom_level)
	custom_minimum_size = frame_size
	size = frame_size

	if _frame_rect != null:
		_frame_rect.texture = _load_tex(BG_PATHS.get(_zoom_level, BG_PATHS[1]))
		_frame_rect.position = Vector2.ZERO
		_frame_rect.size = frame_size

	if _map_canvas != null:
		_map_canvas.position = Vector2(FRAME_BORDER_PX, FRAME_BORDER_PX)
		_map_canvas.size = inner_size

	if _floor_label != null:
		_floor_label.position = Vector2(FRAME_BORDER_PX + 4.0, FRAME_BORDER_PX + 1.0)
		_floor_label.size = Vector2(max(60.0, inner_size.x - 36.0), 16.0)

	if _zoom_in_button != null:
		_zoom_in_button.position = Vector2(frame_size.x - 31.0, 2.0)
		_zoom_in_button.disabled = _zoom_level >= MAX_ZOOM
		_zoom_in_button.modulate = Color(0.55, 0.55, 0.55, 0.7) if _zoom_level >= MAX_ZOOM else Color(1, 1, 1, 1)

	if _zoom_out_button != null:
		_zoom_out_button.position = Vector2(frame_size.x - 16.0, 2.0)
		_zoom_out_button.disabled = _zoom_level <= MIN_ZOOM
		_zoom_out_button.modulate = Color(0.55, 0.55, 0.55, 0.7) if _zoom_level <= MIN_ZOOM else Color(1, 1, 1, 1)

func refresh():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if _floor_label != null:
		_floor_label.text = "LEVEL " + str(_dungeon.get_floor_level())
	_rebuild_terrain_image()
	if _map_canvas != null:
		_map_canvas.queue_redraw()

func _compute_grid_offset(grid):
	var min_x = 0
	var min_y = 0
	var has_oob = false
	for cell in grid.fov.explored_cells.keys():
		if cell.x < 0 or cell.y < 0 or cell.x >= MAP_GRID_SIZE or cell.y >= MAP_GRID_SIZE:
			has_oob = true
			min_x = min(min_x, cell.x)
			min_y = min(min_y, cell.y)
	if not has_oob:
		return Vector2i.ZERO
	return Vector2i(-min_x, -min_y)

func _liquid_color(liquid_type):
	match str(liquid_type):
		"lava":
			return COLOR_LAVA
		"water":
			return COLOR_WATER
		"ice":
			return COLOR_ICE
		"goo":
			return COLOR_GOO
	return COLOR_FLOOR

func _rebuild_terrain_image():
	if _terrain_image == null or _dungeon == null or not is_instance_valid(_dungeon):
		return
	_terrain_image.fill(COLOR_UNEXPLORED)
	var grid = _dungeon.get_entity_grid()
	if grid == null:
		_terrain_texture.update(_terrain_image)
		return
	var offset = _compute_grid_offset(grid)

	for cell in grid.fov.explored_cells.keys():
		var px = cell.x + offset.x
		var py = cell.y + offset.y
		if px < 0 or py < 0 or px >= MAP_GRID_SIZE or py >= MAP_GRID_SIZE:
			continue
		var pixel_color = COLOR_UNEXPLORED
		if grid.has_wall(cell.x, cell.y):
			pixel_color = COLOR_WALL
		elif grid.has_liquid(cell.x, cell.y):
			var liquid_type = grid._liquid_cells.get(cell, "")
			pixel_color = _liquid_color(liquid_type)
		elif grid.has_floor(cell.x, cell.y):
			pixel_color = COLOR_FLOOR

		var door = grid.get_door_at(cell.x, cell.y)
		if door != null:
			if door.can_pass():
				pixel_color = COLOR_DOOR_OPEN
			elif door.is_locked:
				pixel_color = COLOR_DOOR_LOCKED
			else:
				pixel_color = COLOR_DOOR_CLOSED

		if pixel_color != COLOR_UNEXPLORED:
			_terrain_image.set_pixel(px, py, pixel_color)

	_terrain_texture.update(_terrain_image)

func _draw_icon_at_cell(canvas, icon_path, cell, offset):
	var texture = _load_tex(icon_path)
	if texture == null:
		return
	var px = (float(cell.x + offset.x) + 0.5) * float(_zoom_level) - float(texture.get_width()) * 0.5
	var py = (float(cell.y + offset.y) + 0.5) * float(_zoom_level) - float(texture.get_height()) * 0.5
	canvas.draw_texture(texture, Vector2(floor(px), floor(py)))

func _element_icon_path(element):
	var suffix = ZOOM_SUFFIX.get(_zoom_level, "")
	match str(element.element_type):
		"bookshelf":
			return "ui/icons/minimap_bookshelf" + ("_used" if element.used else "") + suffix + ".png"
		"anvil":
			return "ui/icons/minimap_krong" + ("_used" if element.used else "") + suffix + ".png"
		"lutefiskstatue":
			return "ui/icons/minimap_lutefisk" + ("_used" if element.used else "") + suffix + ".png"
		"queststatue":
			return "ui/icons/minimap_quest" + ("_used" if element.used else "") + suffix + ".png"
		"uberchest", "evilchest":
			return "ui/icons/minimap_uberchest" + ("_used" if element.used else "") + suffix + ".png"
		"dredmorstatue":
			return "ui/icons/minimap_dredmor" + suffix + ".png"
		"statue", "pedestal":
			return "ui/icons/minimap_monolith" + suffix + ".png"
	return ""

func _draw_map_contents(canvas):
	var inner_px = float(MAP_GRID_SIZE * _zoom_level)
	if _terrain_texture != null:
		canvas.draw_texture_rect(_terrain_texture, Rect2(Vector2.ZERO, Vector2(inner_px, inner_px)), false)
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var grid = _dungeon.get_entity_grid()
	if grid == null:
		return

	var offset = _compute_grid_offset(grid)
	var suffix = ZOOM_SUFFIX.get(_zoom_level, "")

	for element_cell in grid._elements_by_cell.keys():
		if not grid.is_cell_explored(element_cell.x, element_cell.y):
			continue
		var element = grid._elements_by_cell[element_cell]
		if element == null or not is_instance_valid(element) or element.is_broken:
			continue
		var icon_path = _element_icon_path(element)
		if icon_path != "":
			_draw_icon_at_cell(canvas, icon_path, element_cell, offset)

	for tp_cell in grid._teleporters_by_cell.keys():
		if grid.is_cell_explored(tp_cell.x, tp_cell.y):
			_draw_icon_at_cell(canvas, "ui/icons/minimap_teleport" + suffix + ".png", tp_cell, offset)

	for stair_cell in grid._stairs_by_cell.keys():
		if not grid.is_cell_explored(stair_cell.x, stair_cell.y):
			continue
		var stair_info = grid._stairs_by_cell[stair_cell]
		var stair_icon = "ui/icons/minimap_stairsup" + suffix + ".png" if str(stair_info.get("direction", "")) == "up" else "ui/icons/minimap_stairsdown" + suffix + ".png"
		_draw_icon_at_cell(canvas, stair_icon, stair_cell, offset)

	var player = _dungeon.get_player()
	if player != null and is_instance_valid(player):
		var player_position = player.get_grid_position()
		if player_position != null:
			var player_base = "ui/icons/minimap_fplayer" if str(player.hero_kind) == "heroine" else "ui/icons/minimap_player"
			_draw_icon_at_cell(canvas, player_base + suffix + ".png", Vector2i(int(player_position.x), int(player_position.y)), offset)
