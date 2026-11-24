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

static func _collect_flagged_cells(entity_grid, placements, flag_name):
	var cells = []
	for placement in placements:
		var layout = placement.layout
		if layout.shop or layout.zoo or layout.name == "Starting Room":
			continue
		if flag_name != "" and layout.get(flag_name, false):
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
			if entity_grid.get_element_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.get_trap_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.get_teleporter_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.get_loot_at(world_cell.x, world_cell.y) != null:
				continue
			if entity_grid.player_spawn_cell != null and world_cell == entity_grid.player_spawn_cell:
				continue
			if _is_adjacent_to_door(entity_grid, world_cell):
				continue
			cells.append(world_cell)
	cells.shuffle()
	return cells

static func _pick_valid_item_from_pool(pool, max_level):
	if pool.is_empty():
		return null
	var leveled = []
	var fallback = []
	for entry in pool:
		var icon_path = entry.get("icon", "")
		if icon_path == "" or not OD.Load.exists(icon_path):
			continue
		fallback.append(entry)
		if entry.get("level", 1) <= max_level:
			leveled.append(entry)
	var source = leveled if not leveled.is_empty() else fallback
	if source.is_empty():
		return null
	return source[randi() % source.size()]

static func _roll_treasure_loot(floor_level):
	var roll_size = max(1, int(OD.Database.get_tweak("treasure roll size", 690)))
	var roll = randi() % roll_size
	var weapon_max = int(OD.Database.get_tweak("weapon roll max", 89))
	var armour_max = int(OD.Database.get_tweak("armour roll max", 249))
	var ring_max = int(OD.Database.get_tweak("ring roll max", 269))
	var ammo_max = int(OD.Database.get_tweak("ammo roll max", 349))
	var food_max = int(OD.Database.get_tweak("food roll max", 429))
	var potion_max = int(OD.Database.get_tweak("potion roll max", 519))
	var lockpick_max = int(OD.Database.get_tweak("lockpick roll max", 559))
	var mushroom_max = int(OD.Database.get_tweak("mushroom roll max", 649))
	var max_level = floor_level + 2

	if roll <= weapon_max:
		var item = _pick_valid_item_from_pool(OD.Database.get_items_by_category("weapon"), max_level)
		return { kind = "item", item = item } if item != null else null
	if roll <= armour_max:
		var item = _pick_valid_item_from_pool(OD.Database.get_items_by_category("armour"), max_level)
		return { kind = "item", item = item } if item != null else null
	if roll <= ring_max:
		var rings = []
		for armour_item in OD.Database.get_items_by_category("armour"):
			var raw_armour = armour_item.get("raw", {}).get("armour", {})
			if typeof(raw_armour) == TYPE_DICTIONARY and raw_armour.get("type", "") == "ring":
				rings.append(armour_item)
		var pool = rings if not rings.is_empty() else OD.Database.get_items_by_category("armour")
		var item = _pick_valid_item_from_pool(pool, max_level)
		return { kind = "item", item = item } if item != null else null
	if roll <= ammo_max:
		var item = _pick_valid_item_from_pool(OD.Database.get_items_by_category("bolts"), max_level)
		return { kind = "item", item = item } if item != null else null
	if roll <= food_max:
		var item = _pick_valid_item_from_pool(OD.Database.get_items_by_category("food"), max_level)
		return { kind = "item", item = item } if item != null else null
	if roll <= potion_max:
		var item = _pick_valid_item_from_pool(OD.Database.get_items_by_category("potion"), max_level)
		return { kind = "item", item = item } if item != null else null
	if roll <= lockpick_max:
		return { kind = "lockpick", amount = 1 }
	if roll <= mushroom_max:
		var mushrooms = []
		for food_item in OD.Database.get_items_by_category("food"):
			var lower_name = food_item.get("name", "").to_lower()
			if "cap" in lower_name or "shroom" in lower_name or "truffle" in lower_name or "ear" in lower_name or "puffball" in lower_name:
				mushrooms.append(food_item)
		var pool = mushrooms if not mushrooms.is_empty() else OD.Database.get_items_by_category("reagent")
		var item = _pick_valid_item_from_pool(pool, max_level)
		return { kind = "item", item = item } if item != null else null
	var wand_item = _pick_valid_item_from_pool(OD.Database.get_items_by_category("wand"), max_level)
	return { kind = "item", item = wand_item } if wand_item != null else null

static func _populate_floor_loot_and_traps(entity_grid, placements, floor_level, no_grind):
	var scale_factor = 0.5 if no_grind else 1.0
	var used_cells = {}

	var trap_cells = _collect_flagged_cells(entity_grid, placements, "notraps")
	var target_traps = int(ceil(float(max(0, int(OD.Database.get_tweak("num traps per level", 60)))) * scale_factor))
	for _ii in range(target_traps):
		var cell = _take_random_cell(trap_cells, used_cells)
		if cell == null:
			break
		var trap_def = OD.Database.get_trap(null, floor_level + 1)
		if trap_def != null:
			entity_grid.add_trap(cell.x, cell.y, trap_def)

	var treasure_cells = _collect_flagged_cells(entity_grid, placements, "notreasure")
	var min_treasures = max(0, int(OD.Database.get_tweak("minimum number of treasures", 37)))
	var max_add_treasures = max(0, int(OD.Database.get_tweak("maximum additional treasures", 55)))
	var target_treasures = int(ceil(float(min_treasures + randi_range(0, max_add_treasures)) * scale_factor))
	for _ii in range(target_treasures):
		var cell = _take_random_cell(treasure_cells, used_cells)
		if cell == null:
			break
		var loot_data = _roll_treasure_loot(floor_level)
		if loot_data != null:
			entity_grid.add_loot_item(cell.x, cell.y, loot_data)

	var reagent_pool = []
	reagent_pool.append_array(OD.Database.get_items_by_category("reagent"))
	reagent_pool.append_array(OD.Database.get_items_by_category("component"))
	var target_reagents = int(ceil(float(max(0, int(OD.Database.get_tweak("number of reagents per level", 30)))) * scale_factor))
	for _ii in range(target_reagents):
		var cell = _take_random_cell(treasure_cells, used_cells)
		if cell == null:
			break
		var reagent_item = _pick_valid_item_from_pool(reagent_pool, floor_level + 2)
		if reagent_item != null:
			entity_grid.add_loot_item(cell.x, cell.y, { kind = "item", item = reagent_item })

	var target_zorkmids = int(ceil(float(max(0, int(OD.Database.get_tweak("zorkmids per level", 210)))) * scale_factor))
	var zorkmids_remaining = target_zorkmids
	while zorkmids_remaining > 0:
		var cell = _take_random_cell(treasure_cells, used_cells)
		if cell == null:
			break
		var pile_amount = min(zorkmids_remaining, randi_range(8, 28) + floor_level * 2)
		zorkmids_remaining -= pile_amount
		entity_grid.add_loot_item(cell.x, cell.y, { kind = "zorkmids", amount = pile_amount })

	var min_food = int(ceil(float(max(0, int(OD.Database.get_tweak("minimum food per level", 35)))) * scale_factor))
	var target_food_items = clamp(min_food / 5, 4, 14)
	var food_pool = OD.Database.get_items_by_category("food")
	for _ii in range(target_food_items):
		var cell = _take_random_cell(treasure_cells, used_cells)
		if cell == null:
			break
		var food_item = _pick_valid_item_from_pool(food_pool, floor_level + 2)
		if food_item != null:
			entity_grid.add_loot_item(cell.x, cell.y, { kind = "item", item = food_item })

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
				anim.set_meta("grid_cell", cell)
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

static func _pick_floor_monster(floor_level):
	if OD.Database == null:
		return null
	for _try in range(12):
		var cand = OD.Database.get_random_monster()
		if typeof(cand) == TYPE_DICTIONARY and cand.has("name") and OD.Database.get_monster(str(cand.name)) != null:
			var lvl = str(cand.get("level", "0")).to_int()
			if lvl <= max(1, int(floor_level) + 1):
				return cand
	return OD.Database.get_monster("Diggle")

static func _populate_monsters(entity_grid, placements, floor_level, no_grind):
	var min_per_room = max(1, int(OD.Database.get_tweak("minimum number of monsters in room", 1)))
	var max_extra = max(1, int(OD.Database.get_tweak("maximum number of additional monsters", 3)))
	for placement in placements:
		var layout = placement.layout
		if layout.shop or layout.name == "Starting Room":
			continue
		var room_cells = []
		for local_cell in layout.floor_cells:
			var world_cell = Vector2i(placement.x + local_cell.x, placement.y + local_cell.y)
			if entity_grid.is_walkable(world_cell.x, world_cell.y) and entity_grid.get_stairs_at(world_cell.x, world_cell.y) == null:
				room_cells.append(world_cell)
		if room_cells.is_empty():
			continue
		room_cells.shuffle()
		var target_count = min_per_room + randi_range(0, max_extra)
		if layout.zoo:
			target_count = max(target_count, min(room_cells.size() / 2, 12))
		elif no_grind:
			target_count = max(1, int(ceil(float(target_count) * 0.7)))
		var spawned = 0
		for cell in room_cells:
			if spawned >= target_count:
				break
			var mon_def = _pick_floor_monster(floor_level)
			if mon_def != null and mon_def.has("name"):
				if entity_grid.spawn_monster_at(str(mon_def.name), cell.x, cell.y, floor_level, true) != null:
					spawned += 1

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
	_populate_floor_loot_and_traps(entity_grid, placements, _floor_level, no_grind)
	_populate_monsters(entity_grid, placements, _floor_level, no_grind)
	_populate_floor_decals(entity_grid, placements, no_grind)
