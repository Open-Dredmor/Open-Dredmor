extends Node

const BUCKET_SIZE = 16
const OPPOSITE_DOOR = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left"
}

static func _bucket_range(start_coord, length):
	return range(int(floor(float(start_coord) / BUCKET_SIZE)), int(floor(float(start_coord + length - 1) / BUCKET_SIZE)) + 1)

static func _collides(buckets, rect):
	for bx in _bucket_range(rect.x, rect.w):
		for by in _bucket_range(rect.y, rect.h):
			var key = Vector2i(bx, by)
			if not buckets.has(key):
				continue
			for existing in buckets[key]:
				if rect.x + 1 < existing.x + existing.w and rect.x + rect.w - 1 > existing.x and rect.y + 1 < existing.y + existing.h and rect.y + rect.h - 1 > existing.y:
					return true
	return false

static func _insert_bucket(buckets, rect):
	for bx in _bucket_range(rect.x, rect.w):
		for by in _bucket_range(rect.y, rect.h):
			var key = Vector2i(bx, by)
			if not buckets.has(key):
				buckets[key] = []
			buckets[key].append(rect)

static func _collect_doors(layout, placement_index, x_pos, y_pos, exclude_door = null):
	var out = []
	for kind in ["up", "down", "left", "right"]:
		for door in layout.doors[kind]:
			if exclude_door != null and door.x == exclude_door.x and door.y == exclude_door.y and door.kind == exclude_door.kind:
				continue
			out.append({
				placement_index = placement_index,
				local_x = door.x,
				local_y = door.y,
				world_x = x_pos + door.x,
				world_y = y_pos + door.y,
				kind = kind
			})
	return out

static func _can_place_3x3_door(entity_grid, grid_x, grid_y, orientation):
	if orientation == "ns":
		if not entity_grid.has_wall(grid_x, grid_y - 2) or not entity_grid.has_wall(grid_x, grid_y + 2):
			return false
		for dy in [-1, 1]:
			if not entity_grid.has_wall(grid_x, grid_y + dy):
				return false
			if not entity_grid.has_floor(grid_x - 1, grid_y + dy) or not entity_grid.has_floor(grid_x + 1, grid_y + dy):
				return false
			if entity_grid.get_door_at(grid_x, grid_y + dy) != null:
				return false
		return true
	if not entity_grid.has_wall(grid_x - 2, grid_y) or not entity_grid.has_wall(grid_x + 2, grid_y):
		return false
	for dx in [-1, 1]:
		if not entity_grid.has_wall(grid_x + dx, grid_y):
			return false
		if not entity_grid.has_floor(grid_x + dx, grid_y - 1) or not entity_grid.has_floor(grid_x + dx, grid_y + 1):
			return false
		if entity_grid.get_door_at(grid_x + dx, grid_y) != null:
			return false
	return true

static func _compute_offset(source_door, target_door, layout):
	var pos_x = source_door.world_x
	var pos_y = source_door.world_y
	match target_door.kind:
		"up":
			pos_x -= target_door.x
		"down":
			pos_y -= layout.height - 1
			pos_x -= target_door.x
		"left":
			pos_y -= target_door.y
		"right":
			pos_x -= layout.width - 1
			pos_y -= target_door.y
	return Vector2i(pos_x, pos_y)

static func _try_place_from_pool(candidates, frontier_doors, buckets, placements):
	var shuffled_candidates = candidates.duplicate()
	shuffled_candidates.shuffle()
	for frontier_idx in range(frontier_doors.size() - 1, -1, -1):
		var source_door = frontier_doors[frontier_idx]
		var target_kind = OPPOSITE_DOOR[source_door.kind]
		for layout in shuffled_candidates:
			var door_list = layout.doors[target_kind]
			if door_list.is_empty():
				continue
			var shuffled_doors = door_list.duplicate()
			shuffled_doors.shuffle()
			for target_door in shuffled_doors:
				var offset = _compute_offset(source_door, target_door, layout)
				var rect = { x = offset.x, y = offset.y, w = layout.width, h = layout.height }
				if _collides(buckets, rect):
					continue
				var new_idx = placements.size()
				placements.append({
					layout = layout,
					x = offset.x,
					y = offset.y,
					claimed_doors = [{ x = target_door.x, y = target_door.y, kind = target_door.kind, spawn_door = false }]
				})
				placements[source_door.placement_index].claimed_doors.append({
					x = source_door.local_x,
					y = source_door.local_y,
					kind = source_door.kind,
					spawn_door = true
				})
				_insert_bucket(buckets, rect)
				frontier_doors.remove_at(frontier_idx)
				var new_doors = _collect_doors(layout, new_idx, offset.x, offset.y, target_door)
				new_doors.shuffle()
				for new_door in new_doors:
					frontier_doors.append(new_door)
				return true
	return false

static func generate(_branch_name, floor_level):
	var floor_index = max(0, floor_level - 1)
	var settings = OD.DungeonSettings.get_settings()
	var no_grind = settings != null and settings.get("no_time_to_grind", false)
	var target_rooms = 18 + min(floor_level * 2, 12)
	if no_grind:
		target_rooms = max(10, int(target_rooms * 0.65))

	var eligible_layouts = OD.Database.get_room_layouts_for_floor(floor_index)
	var normal_rooms = []
	var shop_rooms = []
	var zoo_rooms = []
	var special_rooms = []
	for layout in eligible_layouts:
		if layout.shop:
			shop_rooms.append(layout)
		elif layout.zoo:
			zoo_rooms.append(layout)
		elif layout.special:
			special_rooms.append(layout)
		else:
			normal_rooms.append(layout)

	if normal_rooms.is_empty():
		normal_rooms = eligible_layouts.duplicate()

	var start_layout = OD.Database.get_room_layout("Starting Room") if floor_level == 1 else null
	if start_layout == null:
		start_layout = OD.DataStructure.choose(normal_rooms, 1)

	var buckets = {}
	var placements = []
	var frontier_doors = []

	var start_rect = { x = 0, y = 0, w = start_layout.width, h = start_layout.height }
	placements.append({
		layout = start_layout,
		x = 0,
		y = 0,
		claimed_doors = []
	})
	_insert_bucket(buckets, start_rect)
	for door in _collect_doors(start_layout, 0, 0, 0):
		frontier_doors.append(door)
	frontier_doors.shuffle()

	if not shop_rooms.is_empty():
		_try_place_from_pool(shop_rooms, frontier_doors, buckets, placements)
	if not zoo_rooms.is_empty():
		_try_place_from_pool(zoo_rooms, frontier_doors, buckets, placements)

	var special_budget = 2
	var safety_limit = target_rooms * 4
	while placements.size() < target_rooms and not frontier_doors.is_empty() and safety_limit > 0:
		safety_limit -= 1
		var pool = normal_rooms
		if special_budget > 0 and not special_rooms.is_empty() and randi() % 5 == 0:
			pool = special_rooms
			special_budget -= 1
		if not _try_place_from_pool(pool, frontier_doors, buckets, placements):
			if frontier_doors.size() > 0:
				frontier_doors.pop_back()

	var branch_id = max(0, floor_level - 1)
	if OD.Database.get_branch_info(branch_id) == null:
		branch_id = 0
	var entity_grid = EntityGrid.new()
	entity_grid.init(branch_id)
	entity_grid.floor_level = floor_level
	entity_grid.branch_id = branch_id
	entity_grid.resize(1, 1)

	var pending_doors = []
	var farthest_index = 0
	var farthest_dist = -1
	for idx in range(placements.size()):
		var placement = placements[idx]
		var room = Room.new()
		room.init(placement.layout.name)
		room.position = Vector2(placement.x, placement.y)
		for door in placement.claimed_doors:
			room.claim_door(door.x, door.y, door.kind)
		room.seal_available_doors()
		entity_grid.insert(room.entity_grid, room.position)
		for door in placement.claimed_doors:
			if door.get("spawn_door", false):
				var orientation = "ns" if door.kind == "left" or door.kind == "right" else "ew"
				var is_locked = floor_level > 1 and randi() % 8 == 0
				pending_doors.append({
					x = placement.x + door.x,
					y = placement.y + door.y,
					orientation = orientation,
					locked = is_locked
				})
		var debug_button = room.get_debug_button()
		debug_button.position = OD.Math.grid_to_pixel(room.position.x, room.position.y) + entity_grid.position - Vector2(32, 32)
		entity_grid.add_child(debug_button)
		room.free()
		var dist = abs(placement.x) + abs(placement.y)
		if idx > 0 and not placement.layout.floor_cells.is_empty() and dist > farthest_dist:
			farthest_dist = dist
			farthest_index = idx

	for door_info in pending_doors:
		var style = "3x3" if _can_place_3x3_door(entity_grid, door_info.x, door_info.y, door_info.orientation) else "1x1"
		entity_grid.add_door(door_info.x, door_info.y, door_info.orientation, door_info.locked, style)

	if floor_level > 1 and not start_layout.floor_cells.is_empty():
		var up_cell = start_layout.floor_cells[0]
		entity_grid.add_stairs(up_cell.x, up_cell.y, "up")

	var down_placement = placements[farthest_index]
	if not down_placement.layout.floor_cells.is_empty():
		var down_cell = down_placement.layout.floor_cells[down_placement.layout.floor_cells.size() / 2]
		entity_grid.add_stairs(down_placement.x + down_cell.x, down_placement.y + down_cell.y, "down")

	entity_grid.auto_tile_walls()
	return entity_grid
