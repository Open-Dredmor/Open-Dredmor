extends Node

class_name FloorPopulator

const VENDING_TYPES = [
	"boltvending",
	"craftvending",
	"drinkvending",
	"foodvending",
	"thrownvending"
]

const CHANCE_ELEMENT_RULES = [
	{ tweak = "dispenser chance", default_chance = 10, type = "dispenser" },
	{ tweak = "fountain chance", default_chance = 19, type = "fountain" },
	{ tweak = "uberchest chance", default_chance = 21, type = "uberchest" },
	{ tweak = "evilchest chance", default_chance = 60, type = "evilchest" },
	{ tweak = "anvil chance", default_chance = 80, type = "anvil" },
	{ tweak = "bbq chance", default_chance = 22, type = "bbq" },
	{ tweak = "freezer chance", default_chance = 30, type = "freezer" }
]

const FIXED_ELEMENT_RULES = [
	{ tweak = "num shelves per level", default_count = 4, type = "bookshelf" },
	{ tweak = "dredmor statues per level", default_count = 3, type = "dredmorstatue" },
	{ tweak = "num lutefisk statues", default_count = 0, type = "lutefiskstatue" },
	{ tweak = "num quest statues", default_count = 0, type = "queststatue" }
]

const CARDINAL_DIRS = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]

const EIGHT_DIRS = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1)
]

static func _liquid_type_for_branch(branch_info):
	var tileset_name = str(branch_info.get("tileset", "")).to_lower()
	var branch_name = str(branch_info.get("name", "")).to_lower()
	if "lava" in tileset_name or "diggle_hell" in tileset_name or "lava" in branch_name:
		return "lava"
	if "frozen" in tileset_name or "ice" in branch_name:
		return "ice"
	if "fungus" in tileset_name or "moonbase" in tileset_name or "clockwork" in tileset_name or "ossuary" in tileset_name:
		return "goo"
	return "water"

static func _can_carve_lake_cell(entity_grid, cell, used_cells):
	if not _is_cell_eligible(entity_grid, cell, used_cells):
		return false
	if entity_grid.has_liquid(cell.x, cell.y):
		return false
	for dir in EIGHT_DIRS:
		var neighbor = cell + dir
		if not entity_grid.has_floor(neighbor.x, neighbor.y) and not entity_grid.has_liquid(neighbor.x, neighbor.y):
			return false
		if entity_grid.get_door_at(neighbor.x, neighbor.y) != null or entity_grid.get_stairs_at(neighbor.x, neighbor.y) != null:
			return false
		if entity_grid.get_element_at(neighbor.x, neighbor.y) != null or entity_grid.get_trap_at(neighbor.x, neighbor.y) != null:
			return false
		if entity_grid.player_spawn_cell != null and neighbor == entity_grid.player_spawn_cell:
			return false
	return true

static func _populate_lakes(entity_grid, placements, used_cells, no_grind):
	var branch_info = OD.Database.get_branch_info(entity_grid.branch_id)
	if branch_info == null:
		return
	var leveldata = branch_info.get("leveldata", {})
	if typeof(leveldata) != TYPE_DICTIONARY or int(leveldata.get("genLakes", 0)) != 1:
		return
	var liquid_type = _liquid_type_for_branch(branch_info)
	var seed_candidates = []
	for placement in placements:
		var layout = placement.layout
		if layout.shop or layout.zoo or layout.name == "Starting Room":
			continue
		for local_cell in layout.floor_cells:
			var world_cell = Vector2i(placement.x + local_cell.x, placement.y + local_cell.y)
			if _can_carve_lake_cell(entity_grid, world_cell, used_cells):
				seed_candidates.append(world_cell)
	if seed_candidates.is_empty():
		return
	seed_candidates.shuffle()
	var target_lakes = randi_range(1, 2) if no_grind else randi_range(2, 4)
	var lakes_carved = 0
	for seed_cell in seed_candidates:
		if lakes_carved >= target_lakes:
			break
		if not _can_carve_lake_cell(entity_grid, seed_cell, used_cells):
			continue
		var target_size = randi_range(4, 10)
		var frontier = [seed_cell]
		var carved_cells = []
		while not frontier.is_empty() and carved_cells.size() < target_size:
			var idx = randi() % frontier.size()
			var current = frontier[idx]
			frontier.remove_at(idx)
			if not _can_carve_lake_cell(entity_grid, current, used_cells):
				continue
			used_cells[current] = true
			entity_grid.carve_liquid_cell(current.x, current.y, liquid_type)
			carved_cells.append(current)
			for dir in CARDINAL_DIRS:
				var next_cell = current + dir
				if _can_carve_lake_cell(entity_grid, next_cell, used_cells):
					frontier.append(next_cell)
		if not carved_cells.is_empty():
			lakes_carved += 1

static func _populate_floor_decals(entity_grid, placements, no_grind):
	var valid_decals = []
	for decal_path in OD.Resources.paths.decals:
		if OD.Load.exists(decal_path):
			valid_decals.append(decal_path)
	if valid_decals.is_empty():
		return
	var candidate_cells = []
	for placement in placements:
		var layout = placement.layout
		if layout.shop:
			continue
		for local_cell in layout.floor_cells:
			var world_cell = Vector2i(placement.x + local_cell.x, placement.y + local_cell.y)
			if not entity_grid.is_walkable(world_cell.x, world_cell.y):
				continue
			if entity_grid.has_liquid(world_cell.x, world_cell.y):
				continue
			if entity_grid.get_stairs_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.get_door_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.get_teleporter_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.get_trap_at(world_cell.x, world_cell.y) != null:
				continue
			candidate_cells.append(world_cell)
	if candidate_cells.is_empty():
		return
	candidate_cells.shuffle()
	var max_decals = 25 if no_grind else 50
	var target_decals = clamp(candidate_cells.size() / 45, 8, max_decals)
	for ii in range(min(target_decals, candidate_cells.size())):
		var cell = candidate_cells[ii]
		var chosen_decal = valid_decals[randi() % valid_decals.size()]
		entity_grid.add_floor_decal(cell.x, cell.y, chosen_decal)

static func _is_adjacent_to_door(entity_grid, cell):
	for dir in CARDINAL_DIRS:
		var neighbor = cell + dir
		if entity_grid.get_door_at(neighbor.x, neighbor.y) != null:
			return true
	return false

static func _is_cell_eligible(entity_grid, cell, used_cells):
	if used_cells.has(cell):
		return false
	if not entity_grid.has_floor(cell.x, cell.y):
		return false
	if entity_grid.is_blocked(cell.x, cell.y):
		return false
	if entity_grid.get_stairs_at(cell.x, cell.y) != null:
		return false
	if entity_grid.get_door_at(cell.x, cell.y) != null:
		return false
	if entity_grid.get_trap_at(cell.x, cell.y) != null:
		return false
	if entity_grid.get_element_at(cell.x, cell.y) != null:
		return false
	if entity_grid.get_teleporter_at(cell.x, cell.y) != null:
		return false
	if entity_grid.player_spawn_cell != null and cell == entity_grid.player_spawn_cell:
		return false
	if _is_adjacent_to_door(entity_grid, cell):
		return false
	return true

static func _take_random_cell(cells, used_cells):
	while not cells.is_empty():
		var idx = randi() % cells.size()
		var cell = cells[idx]
		cells.remove_at(idx)
		if not used_cells.has(cell):
			used_cells[cell] = true
			return cell
	return null

static func _spawn_element(entity_grid, cell, elem_type):
	var actual_type = elem_type
	if elem_type == "dispenser":
		actual_type = VENDING_TYPES[randi() % VENDING_TYPES.size()]
	var asset = OD.Assets.element(actual_type)
	if asset == null:
		return false
	entity_grid.add_element(cell.x, cell.y, actual_type, asset)
	return true

static func _spawn_blocker_prop(entity_grid, cell):
	var prop_paths = OD.Resources.paths.props
	var use_destructible = (randi() % 100) < 60
	if use_destructible and not prop_paths.destructible.is_empty():
		var chosen = prop_paths.destructible[randi() % prop_paths.destructible.size()]
		if OD.Load.exists(chosen.sprite):
			var anim = OD.Load.animation(chosen.sprite)
			if anim != null:
				entity_grid.add_element(cell.x, cell.y, "custom_breakable", anim, { name = chosen.name })
				return true
	if not prop_paths.decorative.is_empty():
		var sprite_path = prop_paths.decorative[randi() % prop_paths.decorative.size()]
		if OD.Load.exists(sprite_path):
			var anim = OD.Load.animation(sprite_path)
			if anim != null:
				var pixel_pos = OD.Math.grid_to_pixel(cell.x, cell.y)
				if anim.is_tall():
					pixel_pos.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
				entity_grid.add_animation(pixel_pos.x, pixel_pos.y, "custom_blocker", anim)
				entity_grid.mark_blocker(cell.x, cell.y)
				return true
	return false

static func _create_teleporter_anim(channel):
	var pad_configs = OD.Resources.paths.teleporters
	if pad_configs.is_empty():
		return null
	var cfg = pad_configs[channel % pad_configs.size()]
	if OD.Load.exists(cfg.prefix + "0000.png"):
		return OD.Load.png_sprite(cfg.prefix, 0, cfg.frames, cfg.rate)
	return null

static func _populate_teleporters(entity_grid, all_eligible_cells, used_cells):
	var num_teleporters = max(0, int(OD.Database.get_tweak("number of teleporters", 5)))
	for channel in range(num_teleporters):
		if all_eligible_cells.size() < 2:
			break
		var cell_a = _take_random_cell(all_eligible_cells, used_cells)
		var cell_b = _take_random_cell(all_eligible_cells, used_cells)
		if cell_a == null or cell_b == null:
			break
		var anim_a = _create_teleporter_anim(channel)
		var anim_b = _create_teleporter_anim(channel)
		if anim_a != null and anim_b != null:
			entity_grid.add_teleporter(cell_a.x, cell_a.y, channel, cell_b, anim_a)
			entity_grid.add_teleporter(cell_b.x, cell_b.y, channel, cell_a, anim_b)

static func _populate_wizard_portal(entity_grid, all_eligible_cells, used_cells):
	var portal_cell = _take_random_cell(all_eligible_cells, used_cells)
	if portal_cell != null:
		_spawn_element(entity_grid, portal_cell, "wizardportal")

static func populate(entity_grid, placements, _floor_level, no_grind = false):
	var used_cells = {}
	_populate_lakes(entity_grid, placements, used_cells, no_grind)
	var eligible_rooms = []
	var all_eligible_cells = []

	for placement in placements:
		var layout = placement.layout
		if layout.shop or layout.zoo or layout.noblockers or layout.name == "Starting Room":
			continue
		var room_cells = []
		for local_cell in layout.floor_cells:
			var world_cell = Vector2i(placement.x + local_cell.x, placement.y + local_cell.y)
			if _is_cell_eligible(entity_grid, world_cell, used_cells):
				room_cells.append(world_cell)
				all_eligible_cells.append(world_cell)
		if not room_cells.is_empty():
			eligible_rooms.append({
				layout = layout,
				cells = room_cells
			})

	for room_info in eligible_rooms:
		for rule in CHANCE_ELEMENT_RULES:
			if room_info.cells.is_empty():
				break
			var chance_val = max(1, int(OD.Database.get_tweak(rule.tweak, rule.default_chance)))
			if randi() % chance_val == 0:
				var cell = _take_random_cell(room_info.cells, used_cells)
				if cell != null:
					_spawn_element(entity_grid, cell, rule.type)

	all_eligible_cells.shuffle()

	for rule in FIXED_ELEMENT_RULES:
		var target_count = max(0, int(OD.Database.get_tweak(rule.tweak, rule.default_count)))
		for _ii in range(target_count):
			var cell = _take_random_cell(all_eligible_cells, used_cells)
			if cell == null:
				break
			_spawn_element(entity_grid, cell, rule.type)

	var max_graffiti = max(0, int(OD.Database.get_tweak("max wizard graffitis", 3)))
	if max_graffiti > 0 and OD.Load.exists(OD.Resources.paths.element.wizard_graffiti + "0000.png"):
		var graffiti_count = randi_range(0, max_graffiti)
		for _ii in range(graffiti_count):
			var cell = _take_random_cell(all_eligible_cells, used_cells)
			if cell == null:
				break
			_spawn_element(entity_grid, cell, "wizard_graffiti")

	var min_blockers = max(0, int(OD.Database.get_tweak("minimum blockers", 22)))
	var blocker_a = max(0, int(OD.Database.get_tweak("blocker number a", 12)))
	var blocker_b = max(0, int(OD.Database.get_tweak("blocker number b", 12)))
	var target_blockers = min_blockers + randi_range(0, blocker_a) + randi_range(0, blocker_b)
	if no_grind:
		target_blockers = int(ceil(float(target_blockers) * 0.5))

	for _ii in range(target_blockers):
		var cell = _take_random_cell(all_eligible_cells, used_cells)
		if cell == null:
			break
		_spawn_blocker_prop(entity_grid, cell)

	_populate_teleporters(entity_grid, all_eligible_cells, used_cells)
	_populate_wizard_portal(entity_grid, all_eligible_cells, used_cells)
	_populate_floor_decals(entity_grid, placements, no_grind)
