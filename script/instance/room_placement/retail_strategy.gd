extends Node

const GRID_SIZE_NORMAL = 100
const GRID_SIZE_NO_GRIND = 75
const GRID_BORDER = 3
const MIN_ROOMS_NORMAL = 15
const MIN_FLOOR_NORMAL = 3000
const MIN_ROOMS_NO_GRIND = 10
const MIN_FLOOR_NO_GRIND = 800
const MAX_DOOR_ATTEMPTS = 5
const MAX_GEN_RETRIES = 12
const DEFAULT_MAX_SHOPS = 3
const DEFAULT_NUM_STAIRS = 6
const STAIR_MIN_DIST_SQ = 400
const STAIR_MAX_ATTEMPTS = 4000

const OPPOSITE_DOOR = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left"
}

static func _build_tile_cache(eligible_layouts):
	var cache = {}
	for layout in eligible_layouts:
		var room_def = OD.Database.get_room(layout.name)
		if room_def == null or not room_def.has("row"):
			continue
		var rows = OD.DataStructure.arrayify(room_def.row)
		var grid_rows = []
		var door_list = []
		for row_idx in range(layout.height):
			var row_text = rows[row_idx].text if row_idx < rows.size() else ""
			var row_chars = []
			for col_idx in range(layout.width):
				var tile_char = row_text[col_idx] if col_idx < row_text.length() else " "
				row_chars.append(tile_char)
				if tile_char == "D":
					var kind = "up" if row_idx < layout.height / 2 else "down"
					door_list.append({ x = col_idx, y = row_idx, kind = kind })
				elif tile_char == "d":
					var kind = "left" if col_idx < layout.width / 2 else "right"
					door_list.append({ x = col_idx, y = row_idx, kind = kind })
			grid_rows.append(row_chars)
		cache[layout.name] = {
			rows = grid_rows,
			doors = door_list
		}
	return cache

static func _create_empty_grid(grid_size):
	var grid = []
	for row_idx in range(grid_size):
		var row = []
		row.resize(grid_size)
		row.fill(" ")
		grid.append(row)
	return grid

static func _can_place_room(tile_grid, grid_size, layout, tile_data, pos_x, pos_y):
	var max_bound = grid_size - GRID_BORDER
	if pos_x < GRID_BORDER or pos_y < GRID_BORDER:
		return false
	if pos_x + layout.width > max_bound or pos_y + layout.height > max_bound:
		return false
	var rows = tile_data.rows
	for local_y in range(layout.height):
		var world_y = pos_y + local_y
		var grid_row = tile_grid[world_y]
		var room_row = rows[local_y]
		for local_x in range(layout.width):
			var room_char = room_row[local_x]
			if room_char == " ":
				continue
			var world_x = pos_x + local_x
			var existing = grid_row[world_x]
			if room_char == "#":
				if existing != " " and existing != "#":
					return false
			elif room_char == "D" or room_char == "d":
				if existing != " " and existing != "D" and existing != "d":
					return false
			else:
				if existing != " ":
					return false
	return true

static func _place_room(tile_grid, layout, tile_data, pos_x, pos_y, open_doors, placements, room_index):
	var floor_added = 0
	var claimed_doors = []
	var rows = tile_data.rows
	for local_y in range(layout.height):
		var world_y = pos_y + local_y
		var grid_row = tile_grid[world_y]
		var room_row = rows[local_y]
		for local_x in range(layout.width):
			var room_char = room_row[local_x]
			if room_char == " ":
				continue
			var world_x = pos_x + local_x
			var existing = grid_row[world_x]
			if room_char == "D" or room_char == "d":
				var door_kind = "up" if (room_char == "D" and local_y < layout.height / 2) else ("down" if room_char == "D" else ("left" if local_x < layout.width / 2 else "right"))
				if existing == "D" or existing == "d":
					claimed_doors.append({ x = local_x, y = local_y, kind = door_kind, spawn_door = true })
				else:
					open_doors.append({
						world_x = world_x,
						world_y = world_y,
						local_x = local_x,
						local_y = local_y,
						kind = door_kind,
						placement_index = room_index
					})
			grid_row[world_x] = room_char
			if room_char == ".":
				floor_added += 1
	placements.append({
		layout = layout,
		x = pos_x,
		y = pos_y,
		claimed_doors = claimed_doors
	})
	return floor_added

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

static func _is_wall_or_blank(tile_grid, grid_x, grid_y):
	var cell = tile_grid[grid_y][grid_x]
	return cell == "#" or cell == " "

static func _place_retail_stairs(entity_grid, tile_grid, grid_size, floor_level, branch_length):
	var num_stairs = DEFAULT_NUM_STAIRS
	var start_idx = 0 if floor_level > 1 else num_stairs
	var end_idx = num_stairs if floor_level >= branch_length else num_stairs * 2
	var placed_coords = []
	for stair_idx in range(start_idx, end_idx):
		var direction = "up" if stair_idx < num_stairs else "down"
		var placed = false
		var attempts = 0
		while attempts < STAIR_MAX_ATTEMPTS:
			attempts += 1
			var cand_x = randi_range(2, grid_size - 3)
			var cand_y = randi_range(2, grid_size - 3)
			if tile_grid[cand_y][cand_x] != "#":
				continue
			if tile_grid[cand_y][cand_x - 1] != "#" or tile_grid[cand_y][cand_x + 1] != "#":
				continue
			if not _is_wall_or_blank(tile_grid, cand_x, cand_y - 1):
				continue
			if not _is_wall_or_blank(tile_grid, cand_x - 1, cand_y - 1) or not _is_wall_or_blank(tile_grid, cand_x + 1, cand_y - 1):
				continue
			if tile_grid[cand_y + 1][cand_x] != ".":
				continue
			var stair_cell = Vector2i(cand_x, cand_y + 1)
			if entity_grid.get_stairs_at(stair_cell.x, stair_cell.y) != null or entity_grid.is_blocked(stair_cell.x, stair_cell.y):
				continue
			var too_close = false
			for prev in placed_coords:
				var dx = cand_x - prev.x
				var dy = cand_y - prev.y
				if dx * dx + dy * dy < STAIR_MIN_DIST_SQ:
					too_close = true
					break
			if too_close:
				continue
			entity_grid.add_stairs(stair_cell.x, stair_cell.y, direction)
			placed_coords.append(Vector2i(cand_x, cand_y))
			placed = true
			break
		if not placed:
			for fallback_y in range(2, grid_size - 3):
				for fallback_x in range(2, grid_size - 3):
					if tile_grid[fallback_y][fallback_x] == "#" and tile_grid[fallback_y + 1][fallback_x] == ".":
						var fb_cell = Vector2i(fallback_x, fallback_y + 1)
						if entity_grid.get_stairs_at(fb_cell.x, fb_cell.y) == null and not entity_grid.is_blocked(fb_cell.x, fb_cell.y):
							entity_grid.add_stairs(fb_cell.x, fb_cell.y, direction)
							placed_coords.append(Vector2i(fallback_x, fallback_y))
							placed = true
							break
				if placed:
					break

static func generate(_branch_name, floor_level):
	var floor_index = max(0, floor_level - 1)
	var settings = OD.DungeonSettings.get_settings()
	var no_grind = settings != null and settings.get("no_time_to_grind", false)
	var grid_size = GRID_SIZE_NO_GRIND if no_grind else GRID_SIZE_NORMAL
	var min_rooms = MIN_ROOMS_NO_GRIND if no_grind else MIN_ROOMS_NORMAL
	var min_floor = MIN_FLOOR_NO_GRIND if no_grind else MIN_FLOOR_NORMAL

	var eligible_layouts = OD.Database.get_room_layouts_for_floor(floor_index)
	var tile_cache = _build_tile_cache(eligible_layouts)
	var normal_layouts = []
	var all_non_special = []
	for layout in eligible_layouts:
		if not tile_cache.has(layout.name):
			continue
		if layout.special:
			continue
		all_non_special.append(layout)
		if not layout.shop and not layout.zoo:
			normal_layouts.append(layout)

	var start_layout = OD.Database.get_room_layout("Starting Room") if floor_level == 1 else null
	if start_layout != null and not tile_cache.has(start_layout.name):
		var start_cache = _build_tile_cache([start_layout])
		for key in start_cache.keys():
			tile_cache[key] = start_cache[key]

	var best_grid = null
	var best_placements = []
	var best_floor_count = -1
	var best_player_spawn = Vector2i(4, 6)
	var player_spawn = Vector2i(4, 6)

	for _retry in range(MAX_GEN_RETRIES):
		var tile_grid = _create_empty_grid(grid_size)
		var open_doors = []
		var placements = []
		var floor_count = 0
		var shops_placed = 0
		var zoos_placed = 0
		var placed_unique = {}

		var first_layout = start_layout
		if first_layout == null and not normal_layouts.is_empty():
			first_layout = normal_layouts[randi() % normal_layouts.size()]
		if first_layout == null:
			break

		var start_x = randi_range(GRID_BORDER, max(GRID_BORDER, grid_size - first_layout.width - GRID_BORDER))
		var start_y = randi_range(GRID_BORDER, max(GRID_BORDER, grid_size - first_layout.height - GRID_BORDER))
		floor_count += _place_room(tile_grid, first_layout, tile_cache[first_layout.name], start_x, start_y, open_doors, placements, 0)
		if floor_level == 1:
			player_spawn = Vector2i(start_x + 4, start_y + 4)
		elif not first_layout.floor_cells.is_empty():
			player_spawn = Vector2i(start_x + first_layout.floor_cells[0].x, start_y + first_layout.floor_cells[0].y)

		while not open_doors.is_empty():
			var source_door = open_doors.pop_front()
			var target_kind = OPPOSITE_DOOR[source_door.kind]
			for _attempt in range(MAX_DOOR_ATTEMPTS):
				if all_non_special.is_empty():
					break
				var cand_layout = all_non_special[randi() % all_non_special.size()]
				if cand_layout.shop and shops_placed >= DEFAULT_MAX_SHOPS:
					continue
				if cand_layout.zoo and zoos_placed >= 1:
					continue
				if (cand_layout.shop or cand_layout.zoo) and placed_unique.has(cand_layout.name):
					continue
				var cand_data = tile_cache[cand_layout.name]
				var matching_doors = cand_layout.doors[target_kind]
				if matching_doors.is_empty():
					continue
				var cand_door = matching_doors[randi() % matching_doors.size()]
				var cand_x = source_door.world_x - cand_door.x
				var cand_y = source_door.world_y - cand_door.y
				if not _can_place_room(tile_grid, grid_size, cand_layout, cand_data, cand_x, cand_y):
					continue
				var new_idx = placements.size()
				placements[source_door.placement_index].claimed_doors.append({
					x = source_door.local_x,
					y = source_door.local_y,
					kind = source_door.kind,
					spawn_door = false
				})
				floor_count += _place_room(tile_grid, cand_layout, cand_data, cand_x, cand_y, open_doors, placements, new_idx)
				if cand_layout.shop:
					shops_placed += 1
					placed_unique[cand_layout.name] = true
				elif cand_layout.zoo:
					zoos_placed += 1
					placed_unique[cand_layout.name] = true
				break

		if placements.size() > best_placements.size() or (placements.size() == best_placements.size() and floor_count > best_floor_count):
			best_grid = tile_grid
			best_placements = placements
			best_floor_count = floor_count
			best_player_spawn = player_spawn

		if placements.size() > min_rooms and floor_count >= min_floor:
			break

	var branch_id = max(0, floor_level - 1)
	var branch_info = OD.Database.get_branch_info(branch_id)
	if branch_info == null:
		branch_id = 0
		branch_info = OD.Database.get_branch_info(0)
	var branch_length = int(branch_info.length) if branch_info != null and branch_info.has("length") else 10

	var entity_grid = EntityGrid.new()
	entity_grid.init(branch_id)
	entity_grid.floor_level = floor_level
	entity_grid.branch_id = branch_id
	entity_grid.player_spawn_cell = best_player_spawn
	entity_grid.resize(grid_size, grid_size)

	var pending_doors = []
	for idx in range(best_placements.size()):
		var placement = best_placements[idx]
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

	for door_info in pending_doors:
		var style = "3x3" if _can_place_3x3_door(entity_grid, door_info.x, door_info.y, door_info.orientation) else "1x1"
		entity_grid.add_door(door_info.x, door_info.y, door_info.orientation, door_info.locked, style)

	if best_grid != null:
		_place_retail_stairs(entity_grid, best_grid, grid_size, floor_level, branch_length)

	entity_grid.auto_tile_walls()
	return entity_grid
