extends RefCounted

class_name GridSerializer

const MonsterEntityScript = preload("res://script/instance/entity/monster_entity.gd")
const ShopkeeperScript = preload("res://script/instance/entity/shopkeeper.gd")
const ShopPedestalScript = preload("res://script/instance/entity/shop_pedestal.gd")

static func _vec2i_to_arr(vec):
	if vec == null:
		return null
	return [int(vec.x), int(vec.y)]

static func _arr_to_vec2i(arr):
	if typeof(arr) != TYPE_ARRAY or arr.size() < 2:
		return null
	return Vector2i(int(arr[0]), int(arr[1]))

static func _sanitize_value(val):
	match typeof(val):
		TYPE_VECTOR2:
			return [float(val.x), float(val.y)]
		TYPE_VECTOR2I:
			return [int(val.x), int(val.y)]
		TYPE_RECT2I:
			return [int(val.position.x), int(val.position.y), int(val.size.x), int(val.size.y)]
		TYPE_COLOR:
			return [float(val.r), float(val.g), float(val.b), float(val.a)]
		TYPE_ARRAY:
			var out_arr = []
			for item in val:
				out_arr.append(_sanitize_value(item))
			return out_arr
		TYPE_DICTIONARY:
			var out_dict = {}
			for key in val.keys():
				var entry = val[key]
				if entry is Node:
					continue
				out_dict[str(key)] = _sanitize_value(entry)
			return out_dict
		TYPE_OBJECT:
			return null
		_:
			return val

static func serialize_grid(grid):
	if grid == null:
		return null
	var width = grid._grid_lookup.size() if grid._grid_lookup != null else 64
	var height = grid._grid_lookup[0].size() if width > 0 and grid._grid_lookup[0] != null else 64

	var floor_cells = []
	for cell in grid._floor_cells.keys():
		floor_cells.append([int(cell.x), int(cell.y)])

	var wall_cells = []
	for cell in grid._wall_cells.keys():
		wall_cells.append([int(cell.x), int(cell.y)])

	var liquid_cells = []
	for cell in grid._liquid_cells.keys():
		liquid_cells.append({ x = int(cell.x), y = int(cell.y), type = str(grid._liquid_cells[cell]) })

	var destructible_cells = []
	for cell in grid._destructible_cells.keys():
		destructible_cells.append([int(cell.x), int(cell.y)])

	var blocker_cells = []
	for cell in grid._blocker_cells.keys():
		blocker_cells.append([int(cell.x), int(cell.y)])

	var room_names = []
	for cell in grid._room_names_by_cell.keys():
		room_names.append({ x = int(cell.x), y = int(cell.y), name = str(grid._room_names_by_cell[cell]) })

	var explored_cells = []
	for cell in grid.fov.explored_cells.keys():
		explored_cells.append([int(cell.x), int(cell.y)])

	var custom_tiles = []
	for tile_info in grid._custom_tiles:
		custom_tiles.append({
			x = int(tile_info.cell.x),
			y = int(tile_info.cell.y),
			layer = str(tile_info.layer),
			sprite_path = str(tile_info.sprite_path)
		})

	var floor_decals = []
	for decal_info in grid._floor_decals:
		floor_decals.append({
			x = int(decal_info.cell.x),
			y = int(decal_info.cell.y),
			path = str(decal_info.path)
		})

	var seen_doors = {}
	var doors = []
	for cell in grid._doors_by_cell.keys():
		var door = grid._doors_by_cell[cell]
		if not is_instance_valid(door):
			continue
		var door_id = door.get_instance_id()
		if seen_doors.has(door_id):
			continue
		seen_doors[door_id] = true
		var anchor_cell = cell
		if door.has_meta("door_cells"):
			var span = door.get_meta("door_cells")
			if typeof(span) == TYPE_ARRAY and span.size() >= 2:
				anchor_cell = span[1]
			elif typeof(span) == TYPE_ARRAY and span.size() == 1:
				anchor_cell = span[0]
		doors.append({
			x = int(anchor_cell.x),
			y = int(anchor_cell.y),
			orientation = str(door.orientation),
			style = str(door.door_style),
			is_open = bool(door.is_open),
			is_locked = bool(door.is_locked),
			is_broken = bool(door.is_broken),
			lock_difficulty = int(door.lock_difficulty)
		})

	var stairs = []
	for cell in grid._stairs_by_cell.keys():
		var stair_info = grid._stairs_by_cell[cell]
		stairs.append({
			x = int(cell.x),
			y = int(cell.y),
			direction = str(stair_info.get("direction", "down"))
		})

	var teleporters = []
	for cell in grid._teleporters_by_cell.keys():
		var tp_info = grid._teleporters_by_cell[cell]
		var target_cell = tp_info.get("target_cell", Vector2i.ZERO)
		teleporters.append({
			x = int(cell.x),
			y = int(cell.y),
			channel = int(tp_info.get("channel", 0)),
			target_x = int(target_cell.x),
			target_y = int(target_cell.y)
		})

	var elements = []
	for cell in grid._elements_by_cell.keys():
		var elem = grid._elements_by_cell[cell]
		if not is_instance_valid(elem):
			continue
		elements.append({
			x = int(cell.x),
			y = int(cell.y),
			element_type = str(elem.element_type),
			used = bool(elem.used),
			is_broken = bool(elem.is_broken),
			state_data = _sanitize_value(elem.state_data)
		})

	var traps = []
	for cell in grid._traps_by_cell.keys():
		var trap = grid._traps_by_cell[cell]
		if not is_instance_valid(trap):
			continue
		traps.append({
			x = int(cell.x),
			y = int(cell.y),
			trap_name = str(trap.trap_name),
			trap_level = int(trap.trap_level),
			casts_spell = str(trap.casts_spell),
			trigger_mode = str(trap.trigger_mode),
			is_discovered = bool(trap.is_discovered),
			is_disarmed = bool(trap.is_disarmed),
			is_triggered = bool(trap.is_triggered),
			cooldown_turns = int(trap.cooldown_turns)
		})

	var loot = []
	for cell in grid._loot_by_cell.keys():
		var entries = grid._loot_by_cell[cell]
		if typeof(entries) != TYPE_ARRAY or entries.is_empty():
			continue
		var items_out = []
		for entry in entries:
			if typeof(entry) == TYPE_DICTIONARY and entry.has("data"):
				items_out.append(_sanitize_value(entry.data))
		if not items_out.is_empty():
			loot.append({
				x = int(cell.x),
				y = int(cell.y),
				items = items_out
			})

	var spell_mines = []
	for mine in grid._spell_mines:
		var mine_pos = mine.get("grid_pos", Vector2i.ZERO)
		spell_mines.append({
			x = int(mine_pos.x),
			y = int(mine_pos.y),
			spell_name = str(mine.get("spell_name", "")),
			turns = int(mine.get("turns", 0))
		})

	var monsters = []
	for monster in grid.get_monsters():
		if monster is ShopkeeperScript:
			continue
		var m_pos = monster.get_grid_position()
		if m_pos == null:
			continue
		monsters.append({
			x = int(m_pos.x),
			y = int(m_pos.y),
			monster_name = str(monster.monster_name),
			monster_level = int(monster.monster_level),
			hp = int(monster.hp),
			max_hp = int(monster.max_hp),
			is_hostile = bool(monster.is_hostile),
			alerted = bool(monster.alerted),
			xp_value = int(monster.xp_value),
			spell_cooldowns = _sanitize_value(monster.spell_cooldowns),
			active_buffs = _sanitize_value(monster.active_buffs),
			active_dots = _sanitize_value(monster.active_dots),
			status_flags = _sanitize_value(monster.status_flags)
		})

	var shops = []
	if grid.shop_manager != null:
		for shop in grid.shop_manager._shops:
			var brax_pos = shop.brax.get_grid_position() if is_instance_valid(shop.brax) else null
			var pedestals_out = []
			for ped in shop.pedestals:
				if not is_instance_valid(ped):
					continue
				var ped_pos = ped.get_grid_position()
				if ped_pos == null:
					continue
				pedestals_out.append({
					x = int(ped_pos.x),
					y = int(ped_pos.y),
					item_data = _sanitize_value(ped.item_data),
					is_paid = bool(ped.is_paid),
					is_taken = bool(ped.is_taken)
				})
			var guards_out = []
			for guard in shop.guards:
				if not is_instance_valid(guard):
					continue
				var guard_pos = guard.get_grid_position()
				if guard_pos == null:
					continue
				guards_out.append({
					x = int(guard_pos.x),
					y = int(guard_pos.y),
					monster_name = str(guard.monster_name),
					hp = int(guard.hp),
					max_hp = int(guard.max_hp),
					is_hostile = bool(guard.is_hostile)
				})
			shops.append({
				id = str(shop.id),
				bounds = [int(shop.bounds.position.x), int(shop.bounds.position.y), int(shop.bounds.size.x), int(shop.bounds.size.y)],
				brax_home = _vec2i_to_arr(shop.brax_home),
				brax_shop = _vec2i_to_arr(shop.brax_shop),
				brax_pos = _vec2i_to_arr(brax_pos),
				brax_hp = int(shop.brax.hp) if is_instance_valid(shop.brax) else 0,
				brax_max_hp = int(shop.brax.max_hp) if is_instance_valid(shop.brax) else 120,
				brax_hostile = bool(shop.brax.is_hostile) if is_instance_valid(shop.brax) else false,
				unpaid_total = int(shop.unpaid_total),
				is_hostile = bool(shop.is_hostile),
				player_inside = bool(shop.player_inside),
				pedestals = pedestals_out,
				guards = guards_out
			})

	return {
		floor_level = int(grid.floor_level),
		branch_id = int(grid.branch_id),
		room_name = str(grid.room_name),
		width = int(width),
		height = int(height),
		stairs_up_cell = _vec2i_to_arr(grid.stairs_up_cell),
		stairs_down_cell = _vec2i_to_arr(grid.stairs_down_cell),
		player_spawn_cell = _vec2i_to_arr(grid.player_spawn_cell),
		floor_cells = floor_cells,
		wall_cells = wall_cells,
		liquid_cells = liquid_cells,
		destructible_cells = destructible_cells,
		blocker_cells = blocker_cells,
		room_names = room_names,
		explored_cells = explored_cells,
		custom_tiles = custom_tiles,
		floor_decals = floor_decals,
		doors = doors,
		stairs = stairs,
		teleporters = teleporters,
		elements = elements,
		traps = traps,
		loot = loot,
		spell_mines = spell_mines,
		monsters = monsters,
		shops = shops
	}

static func _resolve_element_animation(element_type):
	if element_type == "pedestal":
		return OD.Load.animation(OD.Resources.paths.pedestal)
	if element_type == "custom_breakable":
		var breakables = OD.Resources.paths.get("breakables", [])
		if not breakables.is_empty():
			return OD.Load.animation(breakables[0].sprite)
		return null
	return OD.Assets.element(element_type)

static func deserialize_grid(data):
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var grid = EntityGrid.new()
	var b_id = int(data.get("branch_id", 0))
	grid.init(b_id)
	grid.floor_level = int(data.get("floor_level", 1))
	grid.room_name = str(data.get("room_name", ""))
	grid.resize(int(data.get("width", 64)), int(data.get("height", 64)))

	for pair in data.get("floor_cells", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			grid.add_floor_tile_at_grid(int(pair[0]), int(pair[1]))

	for pair in data.get("wall_cells", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			grid._wall_cells[Vector2i(int(pair[0]), int(pair[1]))] = true

	for liq in data.get("liquid_cells", []):
		if typeof(liq) == TYPE_DICTIONARY:
			grid.carve_liquid_cell(int(liq.get("x", 0)), int(liq.get("y", 0)), str(liq.get("type", "water")))

	for pair in data.get("destructible_cells", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			grid.mark_destructible(int(pair[0]), int(pair[1]))

	for pair in data.get("blocker_cells", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			grid.mark_blocker(int(pair[0]), int(pair[1]))

	for rn_entry in data.get("room_names", []):
		if typeof(rn_entry) == TYPE_DICTIONARY:
			grid._room_names_by_cell[Vector2i(int(rn_entry.get("x", 0)), int(rn_entry.get("y", 0)))] = str(rn_entry.get("name", ""))

	for custom_tile in data.get("custom_tiles", []):
		if typeof(custom_tile) == TYPE_DICTIONARY:
			var sp_path = str(custom_tile.get("sprite_path", ""))
			if sp_path != "" and OD.Load.exists(sp_path):
				grid.add_tile(int(custom_tile.get("x", 0)), int(custom_tile.get("y", 0)), str(custom_tile.get("layer", "custom_engraving")), sp_path)

	for decal_entry in data.get("floor_decals", []):
		if typeof(decal_entry) == TYPE_DICTIONARY:
			var d_path = str(decal_entry.get("path", ""))
			if d_path != "" and OD.Load.exists(d_path):
				grid.add_floor_decal(int(decal_entry.get("x", 0)), int(decal_entry.get("y", 0)), d_path)

	grid.auto_tile_walls()
	grid.auto_tile_liquids()
	grid.decorate_walls()

	for door_data in data.get("doors", []):
		if typeof(door_data) != TYPE_DICTIONARY:
			continue
		var door = grid.add_door(
			int(door_data.get("x", 0)),
			int(door_data.get("y", 0)),
			str(door_data.get("orientation", "ew")),
			bool(door_data.get("is_locked", false)),
			str(door_data.get("style", "1x1"))
		)
		if door != null:
			door.is_open = bool(door_data.get("is_open", false))
			door.is_locked = bool(door_data.get("is_locked", false))
			door.is_broken = bool(door_data.get("is_broken", false))
			door.lock_difficulty = int(door_data.get("lock_difficulty", 1))
			door._sync_visual()

	for stair_data in data.get("stairs", []):
		if typeof(stair_data) == TYPE_DICTIONARY:
			grid.add_stairs(int(stair_data.get("x", 0)), int(stair_data.get("y", 0)), str(stair_data.get("direction", "down")))

	for tp_data in data.get("teleporters", []):
		if typeof(tp_data) == TYPE_DICTIONARY:
			var tp_anim = OD.Load.animation("dungeon/teleporter.spr") if OD.Load.exists("dungeon/teleporter.spr") else OD.Assets.element("teleporter")
			if tp_anim != null:
				grid.add_teleporter(
					int(tp_data.get("x", 0)),
					int(tp_data.get("y", 0)),
					int(tp_data.get("channel", 0)),
					Vector2i(int(tp_data.get("target_x", 0)), int(tp_data.get("target_y", 0))),
					tp_anim
				)

	for elem_data in data.get("elements", []):
		if typeof(elem_data) != TYPE_DICTIONARY:
			continue
		var elem_type = str(elem_data.get("element_type", ""))
		var elem_anim = _resolve_element_animation(elem_type)
		var state_dict = elem_data.get("state_data", {})
		if typeof(state_dict) != TYPE_DICTIONARY:
			state_dict = {}
		var elem = grid.add_element(int(elem_data.get("x", 0)), int(elem_data.get("y", 0)), elem_type, elem_anim, state_dict)
		if elem != null:
			elem.used = bool(elem_data.get("used", false))
			elem.is_broken = bool(elem_data.get("is_broken", false))
			if elem.is_broken:
				elem.visible = false
				grid.unblock_cell(int(elem_data.get("x", 0)), int(elem_data.get("y", 0)))
			elif elem.used and elem._animation != null and elem_type in ["lever", "bookshelf", "uberchest", "freezer"]:
				elem._animation.set_frame(1)

	for trap_data in data.get("traps", []):
		if typeof(trap_data) != TYPE_DICTIONARY:
			continue
		var trap_def = OD.Database.get_trap(str(trap_data.get("trap_name", "")))
		var trap = grid.add_trap(int(trap_data.get("x", 0)), int(trap_data.get("y", 0)), trap_def)
		if trap != null:
			trap.trap_name = str(trap_data.get("trap_name", trap.trap_name))
			trap.trap_level = int(trap_data.get("trap_level", trap.trap_level))
			trap.casts_spell = str(trap_data.get("casts_spell", trap.casts_spell))
			trap.trigger_mode = str(trap_data.get("trigger_mode", trap.trigger_mode))
			trap.is_discovered = bool(trap_data.get("is_discovered", false))
			trap.is_disarmed = bool(trap_data.get("is_disarmed", false))
			trap.is_triggered = bool(trap_data.get("is_triggered", false))
			trap.cooldown_turns = int(trap_data.get("cooldown_turns", 0))
			trap.visible = trap.is_discovered and not trap.is_disarmed

	for loot_entry in data.get("loot", []):
		if typeof(loot_entry) != TYPE_DICTIONARY:
			continue
		var lx = int(loot_entry.get("x", 0))
		var ly = int(loot_entry.get("y", 0))
		for item_entry in loot_entry.get("items", []):
			if typeof(item_entry) == TYPE_DICTIONARY:
				grid.add_loot_item(lx, ly, item_entry)

	for mine_data in data.get("spell_mines", []):
		if typeof(mine_data) == TYPE_DICTIONARY:
			grid.place_spell_mine({
				grid_pos = Vector2i(int(mine_data.get("x", 0)), int(mine_data.get("y", 0))),
				spell_name = str(mine_data.get("spell_name", "")),
				turns = int(mine_data.get("turns", 0))
			})

	for m_data in data.get("monsters", []):
		if typeof(m_data) != TYPE_DICTIONARY:
			continue
		var monster = grid.spawn_monster_at(
			str(m_data.get("monster_name", "")),
			int(m_data.get("x", 0)),
			int(m_data.get("y", 0)),
			grid.floor_level,
			bool(m_data.get("is_hostile", true)),
			true
		)
		if monster != null:
			monster.monster_level = int(m_data.get("monster_level", monster.monster_level))
			monster.max_hp = max(1, int(m_data.get("max_hp", monster.max_hp)))
			monster.hp = clamp(int(m_data.get("hp", monster.max_hp)), 1, monster.max_hp)
			monster.alerted = bool(m_data.get("alerted", false))
			monster.xp_value = int(m_data.get("xp_value", monster.xp_value))
			monster.spell_cooldowns = m_data.get("spell_cooldowns", {}).duplicate(true)
			monster.active_buffs = m_data.get("active_buffs", []).duplicate(true)
			monster.active_dots = m_data.get("active_dots", []).duplicate(true)
			monster.status_flags = m_data.get("status_flags", {}).duplicate(true)
			if monster.has_method("refresh_health_bar"):
				monster.refresh_health_bar()

	if grid.shop_manager != null:
		for shop_data in data.get("shops", []):
			if typeof(shop_data) != TYPE_DICTIONARY:
				continue
			var b_arr = shop_data.get("bounds", [0, 0, 0, 0])
			var bounds_rect = Rect2i(int(b_arr[0]), int(b_arr[1]), int(b_arr[2]), int(b_arr[3]))
			var brax_home = _arr_to_vec2i(shop_data.get("brax_home", null))
			var brax_shop = _arr_to_vec2i(shop_data.get("brax_shop", null))
			var brax_pos = _arr_to_vec2i(shop_data.get("brax_pos", null))
			var shop_id = str(shop_data.get("id", "shop_1"))
			var brax_node = null
			if brax_pos != null and int(shop_data.get("brax_hp", 0)) > 0:
				brax_node = ShopkeeperScript.new()
				brax_node.init(shop_id, "Brax", bool(shop_data.get("brax_hostile", false)), false)
				brax_node.max_hp = max(1, int(shop_data.get("brax_max_hp", 120)))
				brax_node.hp = clamp(int(shop_data.get("brax_hp", 120)), 1, brax_node.max_hp)
				grid.add_entity(brax_pos.x, brax_pos.y, brax_node)
			var pedestals_restored = []
			for ped_data in shop_data.get("pedestals", []):
				if typeof(ped_data) != TYPE_DICTIONARY:
					continue
				var px = int(ped_data.get("x", 0))
				var py = int(ped_data.get("y", 0))
				var ped = ShopPedestalScript.new()
				ped.init(shop_id, ped_data.get("item_data", null))
				ped.is_paid = bool(ped_data.get("is_paid", false))
				ped.is_taken = bool(ped_data.get("is_taken", false))
				if ped.is_taken:
					ped.clear_item(ped.is_paid)
				grid.add_entity(px, py, ped)
				grid.mark_blocker(px, py)
				grid.shop_manager.register_pedestal(ped, px, py)
				pedestals_restored.append(ped)
			var guards_restored = []
			for guard_data in shop_data.get("guards", []):
				if typeof(guard_data) != TYPE_DICTIONARY:
					continue
				var gx = int(guard_data.get("x", 0))
				var gy = int(guard_data.get("y", 0))
				var guard = ShopkeeperScript.new()
				guard.init(shop_id, str(guard_data.get("monster_name", "Dread Collector")), bool(guard_data.get("is_hostile", true)), true)
				guard.max_hp = max(1, int(guard_data.get("max_hp", guard.max_hp)))
				guard.hp = clamp(int(guard_data.get("hp", guard.max_hp)), 1, guard.max_hp)
				grid.add_entity(gx, gy, guard)
				guards_restored.append(guard)
			var shop_entry = {
				id = shop_id,
				bounds = bounds_rect,
				brax_home = brax_home if brax_home != null else Vector2i(-1, -1),
				brax_shop = brax_shop if brax_shop != null else Vector2i(-1, -1),
				brax = brax_node,
				pedestals = pedestals_restored,
				guards = guards_restored,
				unpaid_total = int(shop_data.get("unpaid_total", 0)),
				is_hostile = bool(shop_data.get("is_hostile", false)),
				player_inside = bool(shop_data.get("player_inside", false))
			}
			grid.shop_manager._shops.append(shop_entry)
			grid.shop_manager._shops_by_id[shop_id] = shop_entry

	var s_up = _arr_to_vec2i(data.get("stairs_up_cell", null))
	if s_up != null:
		grid.stairs_up_cell = s_up
	var s_down = _arr_to_vec2i(data.get("stairs_down_cell", null))
	if s_down != null:
		grid.stairs_down_cell = s_down
	var p_spawn = _arr_to_vec2i(data.get("player_spawn_cell", null))
	if p_spawn != null:
		grid.player_spawn_cell = p_spawn

	for pair in data.get("explored_cells", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			grid.fov.explored_cells[Vector2i(int(pair[0]), int(pair[1]))] = true
	if not grid.fov.explored_cells.is_empty():
		grid.fov._has_computed = true

	return grid
