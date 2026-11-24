extends RefCounted

class_name FieldOfView

const FOG_MODULATE = Color(0.38, 0.38, 0.45, 1.0)
const LIT_MODULATE = Color(1.0, 1.0, 1.0, 1.0)

const STATIC_LAYERS = [
	"liquid",
	"wall",
	"wall_decoration",
	"floor",
	"floor_decoration",
	"custom_blocker",
	"custom_breakable",
	"pedestal",
	"statue",
	"custom_engraving",
	"element"
]

const OCTANT_TRANSFORMS = [
	[1, 0, 0, 1],
	[0, 1, 1, 0],
	[0, -1, 1, 0],
	[-1, 0, 0, 1],
	[-1, 0, 0, -1],
	[0, -1, -1, 0],
	[0, 1, -1, 0],
	[1, 0, 0, -1]
]

var visible_cells = {}
var explored_cells = {}
var _has_computed = false

func has_computed():
	return _has_computed

func is_visible(grid_x, grid_y):
	return visible_cells.has(Vector2i(int(grid_x), int(grid_y)))

func is_explored(grid_x, grid_y):
	return explored_cells.has(Vector2i(int(grid_x), int(grid_y)))

func clear():
	visible_cells.clear()
	explored_cells.clear()
	_has_computed = false

func compute(origin_cell, sight_radius, is_opaque_fn):
	var origin = Vector2i(int(origin_cell.x), int(origin_cell.y))
	var radius = max(1, int(sight_radius))
	visible_cells.clear()
	visible_cells[origin] = true
	explored_cells[origin] = true
	for octant in OCTANT_TRANSFORMS:
		_cast_light(origin, radius, 1, 1.0, 0.0, octant[0], octant[1], octant[2], octant[3], is_opaque_fn)
	for cell in visible_cells.keys():
		explored_cells[cell] = true
	_has_computed = true
	return visible_cells

func _cast_light(origin, radius, row, start_slope, end_slope, xx, xy, yx, yy, is_opaque_fn):
	if start_slope < end_slope:
		return
	var next_start_slope = start_slope
	var radius_sq = (float(radius) + 0.5) * (float(radius) + 0.5)
	for distance in range(row, radius + 1):
		var blocked = false
		var delta_y = -distance
		for delta_x in range(-distance, 1):
			var left_slope = (float(delta_x) - 0.5) / (float(delta_y) + 0.5)
			var right_slope = (float(delta_x) + 0.5) / (float(delta_y) - 0.5)
			if start_slope < right_slope:
				continue
			if end_slope > left_slope:
				break
			var map_x = origin.x + delta_x * xx + delta_y * xy
			var map_y = origin.y + delta_x * yx + delta_y * yy
			var cell = Vector2i(map_x, map_y)
			if float(delta_x * delta_x + delta_y * delta_y) <= radius_sq:
				visible_cells[cell] = true
			var cell_opaque = is_opaque_fn.call(map_x, map_y)
			if blocked:
				if cell_opaque:
					next_start_slope = right_slope
				else:
					blocked = false
					start_slope = next_start_slope
			elif cell_opaque and distance < radius:
				blocked = true
				_cast_light(origin, radius, distance + 1, start_slope, left_slope, xx, xy, yx, yy, is_opaque_fn)
				next_start_slope = right_slope
		if blocked:
			break

func _get_node_cells(node):
	if node.has_meta("door_cells"):
		return node.get_meta("door_cells")
	if node.has_method("get_grid_position") and node.get_grid_position() != null:
		var pos = node.get_grid_position()
		return [Vector2i(int(pos.x), int(pos.y))]
	if node.has_meta("grid_cell"):
		return [node.get_meta("grid_cell")]
	return []

func apply_visibility(entity_grid):
	if entity_grid == null or not _has_computed:
		return
	for layer_name in STATIC_LAYERS:
		if not entity_grid.layers.lookup.has(layer_name):
			continue
		var layer = entity_grid.layers.lookup[layer_name]
		for child in layer.get_children():
			var cells = _get_node_cells(child)
			if cells.is_empty():
				continue
			var any_visible = false
			var any_explored = false
			for cell in cells:
				if visible_cells.has(cell):
					any_visible = true
					break
				if explored_cells.has(cell):
					any_explored = true
			if any_visible:
				child.visible = true
				child.modulate = LIT_MODULATE
			elif any_explored:
				child.visible = true
				child.modulate = FOG_MODULATE
			else:
				child.visible = false
	if entity_grid.layers.lookup.has("trap"):
		var trap_layer = entity_grid.layers.lookup["trap"]
		for trap in trap_layer.get_children():
			var pos = trap.get_grid_position()
			if pos == null:
				continue
			var cell = Vector2i(int(pos.x), int(pos.y))
			var discovered = bool(trap.get("is_discovered"))
			var disarmed = bool(trap.get("is_disarmed"))
			if disarmed or not discovered:
				trap.visible = false
			elif visible_cells.has(cell):
				trap.visible = true
				trap.modulate = LIT_MODULATE
			elif explored_cells.has(cell):
				trap.visible = true
				trap.modulate = FOG_MODULATE
			else:
				trap.visible = false
	if entity_grid.layers.lookup.has("loot"):
		var loot_layer = entity_grid.layers.lookup["loot"]
		for loot_node in loot_layer.get_children():
			var cells = _get_node_cells(loot_node)
			if cells.is_empty():
				continue
			var is_lit = visible_cells.has(cells[0])
			loot_node.visible = is_lit
			if is_lit:
				loot_node.modulate = LIT_MODULATE
	if entity_grid.layers.lookup.has("actors"):
		var actors_layer = entity_grid.layers.lookup["actors"]
		for actor in actors_layer.get_children():
			if actor.get("entity_kind") == "player":
				actor.visible = true
				actor.modulate = LIT_MODULATE
				continue
			var cells = _get_node_cells(actor)
			if cells.is_empty():
				continue
			var is_lit = visible_cells.has(cells[0])
			actor.visible = is_lit
			if is_lit:
				actor.modulate = LIT_MODULATE
