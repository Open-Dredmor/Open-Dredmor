extends Node

const GRID_SIZE = 56
const GRID_BORDER = 3
const MAX_WIZARD_ROOMS = 5
const MAX_DOOR_ATTEMPTS = 8

const OPPOSITE_DOOR = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left"
}

static func _create_empty_grid():
	var grid = []
	for row_idx in range(GRID_SIZE):
		var row = []
		row.resize(GRID_SIZE)
		row.fill(" ")
		grid.append(row)
	return grid

static func _build_tile_cache(layouts):
	var cache = {}
	for layout in layouts:
		var room_def = OD.Database.get_room(layout.name)
		if room_def == null or not room_def.has("row"):
			continue
		var rows = OD.DataStructure.arrayify(room_def.row)
		var grid_rows = []
		for row_idx in range(layout.height):
			var row_text = rows[row_idx].text if row_idx < rows.size() else ""
			var row_chars = []
			for col_idx in range(layout.width):
				row_chars.append(row_text[col_idx] if col_idx < row_text.length() else " ")
			grid_rows.append(row_chars)
		cache[layout.name] = { rows = grid_rows }
	return cache

static func _can_place_room(tile_grid, layout, tile_data, pos_x, pos_y):
	var max_bound = GRID_SIZE - GRID_BORDER
	if pos_x < GRID_BORDER or pos_y < GRID_BORDER:
		return false
	if pos_x + layout.width > max_bound or pos_y + layout.height > max_bound:
		return false
	var rows = tile_data.rows
	for local_y in range(layout.height):
		var grid_row = tile_grid[pos_y + local_y]
		var room_row = rows[local_y]
		for local_x in range(layout.width):
			var room_char = room_row[local_x]
			if room_char == " ":
				continue
			var existing = grid_row[pos_x + local_x]
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
	var claimed_doors = []
	var rows = tile_data.rows
	for local_y in range(layout.height):
		var grid_row = tile_grid[pos_y + local_y]
		var room_row = rows[local_y]
		for local_x in range(layout.width):
			var room_char = room_row[local_x]
			if room_char == " ":
				continue
			var world_x = pos_x + local_x
			var world_y = pos_y + local_y
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
	placements.append({
		layout = layout,
		x = pos_x,
		y = pos_y,
		claimed_doors = claimed_doors
	})

static func generate(floor_level):
	var wizard_layouts = OD.Database.get_wizard_room_layouts()
	var start_rooms = []
	var mid_rooms = []
	for layout in wizard_layouts:
		if layout.genhint == "wizardStart":
			start_rooms.append(layout)
		elif layout.genhint != "diggleHell":
			mid_rooms.append(layout)

	var fallback_boxes = OD.Database.get_magic_box_layouts()
	if start_rooms.is_empty():
		start_rooms = fallback_boxes
	if start_rooms.is_empty():
		return null

	var all_layouts = start_rooms + mid_rooms
	var tile_cache = _build_tile_cache(all_layouts)
	var tile_grid = _create_empty_grid()
	var open_doors = []
	var placements = []

	var first_layout = start_rooms[randi() % start_rooms.size()]
	var start_x = int((GRID_SIZE - first_layout.width) / 2.0)
	var start_y = int((GRID_SIZE - first_layout.height) / 2.0)
	_place_room(tile_grid, first_layout, tile_cache[first_layout.name], start_x, start_y, open_doors, placements, 0)

	while not open_doors.is_empty() and placements.size() < MAX_WIZARD_ROOMS and not mid_rooms.is_empty():
		var source_door = open_doors.pop_front()
		var target_kind = OPPOSITE_DOOR[source_door.kind]
		for _attempt in range(MAX_DOOR_ATTEMPTS):
			var cand_layout = mid_rooms[randi() % mid_rooms.size()]
			if not tile_cache.has(cand_layout.name):
				continue
			var matching_doors = cand_layout.doors[target_kind]
			if matching_doors.is_empty():
				continue
			var cand_door = matching_doors[randi() % matching_doors.size()]
			var cand_x = source_door.world_x - cand_door.x
			var cand_y = source_door.world_y - cand_door.y
			if not _can_place_room(tile_grid, cand_layout, tile_cache[cand_layout.name], cand_x, cand_y):
				continue
			var new_idx = placements.size()
			placements[source_door.placement_index].claimed_doors.append({
				x = source_door.local_x,
				y = source_door.local_y,
				kind = source_door.kind,
				spawn_door = false
			})
			_place_room(tile_grid, cand_layout, tile_cache[cand_layout.name], cand_x, cand_y, open_doors, placements, new_idx)
			break

	var branch_id = max(0, floor_level - 1)
	if OD.Database.get_branch_info(branch_id) == null:
		branch_id = 0

	var entity_grid = EntityGrid.new()
	entity_grid.init(branch_id)
	entity_grid.floor_level = floor_level
	entity_grid.branch_id = branch_id
	entity_grid.resize(GRID_SIZE, GRID_SIZE)

	for placement in placements:
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
				entity_grid.add_door(placement.x + door.x, placement.y + door.y, orientation, false, "1x1")
		room.free()

	var spawn_cell = Vector2i(start_x + 4, start_y + 4)
	if not first_layout.floor_cells.is_empty():
		spawn_cell = Vector2i(start_x + first_layout.floor_cells[0].x, start_y + first_layout.floor_cells[0].y)
	for local_cell in first_layout.floor_cells:
		var cand = Vector2i(start_x + local_cell.x, start_y + local_cell.y)
		if entity_grid.is_walkable(cand.x, cand.y):
			spawn_cell = cand
			break

	var has_return_portal = false
	for elem in entity_grid._elements_by_cell.values():
		if is_instance_valid(elem) and (elem.element_type == "wizardportal" or elem.element_type == "portal"):
			has_return_portal = true
			break

	if not has_return_portal:
		var portal_cell = null
		for local_cell in first_layout.floor_cells:
			var cand = Vector2i(start_x + local_cell.x, start_y + local_cell.y)
			if cand != spawn_cell and entity_grid.is_walkable(cand.x, cand.y):
				portal_cell = cand
				break
		if portal_cell == null:
			portal_cell = spawn_cell
		var portal_anim = OD.Assets.element("wizardportal")
		if portal_anim != null:
			entity_grid.add_element(portal_cell.x, portal_cell.y, "wizardportal", portal_anim)

	entity_grid.player_spawn_cell = spawn_cell
	entity_grid.auto_tile_walls()
	return entity_grid
