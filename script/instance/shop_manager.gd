extends RefCounted

class_name ShopManager

const ShopkeeperScript = preload("res://script/instance/entity/shopkeeper.gd")
const ShopPedestalScript = preload("res://script/instance/entity/shop_pedestal.gd")

signal shop_alert(message, grid_pos, color)
signal hostile_attack(attacker_name, damage, grid_pos)

var _shops = []
var _shops_by_id = {}
var _pedestals_by_cell = {}
var _next_shop_index = 1

func roll_shop_item(floor_level = 1):
	var pool = OD.Database.get_all_items()
	if pool.is_empty():
		return null
	var candidates = []
	for entry in pool:
		if entry.price > 0 and entry.icon != "" and entry.level <= floor_level + 3:
			candidates.append(entry)
	if candidates.is_empty():
		for entry in pool:
			if entry.price > 0 and entry.icon != "":
				candidates.append(entry)
	if candidates.is_empty():
		return null
	var picked = candidates[randi() % candidates.size()]
	var buy_scaler = float(OD.Database.get_tweak("store buy price scaler", 1.63))
	var sell_scaler = float(OD.Database.get_tweak("store sell price scaler", 0.63))
	var buy_price = max(5, int(round(float(picked.price) * buy_scaler)))
	var sell_price = max(1, int(round(float(picked.price) * sell_scaler)))
	return {
		name = picked.name,
		price = buy_price,
		sell_price = sell_price,
		icon = picked.icon,
		description = picked.description,
		level = picked.level
	}

func register_pedestal(pedestal, grid_x, grid_y):
	_pedestals_by_cell[Vector2i(int(grid_x), int(grid_y))] = pedestal

func get_pedestal_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _pedestals_by_cell.has(cell_key):
		var pedestal = _pedestals_by_cell[cell_key]
		if is_instance_valid(pedestal):
			return pedestal
	return null

func get_shop_by_id(shop_id):
	if _shops_by_id.has(shop_id):
		return _shops_by_id[shop_id]
	return null

func get_shopkeeper_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	for shop in _shops:
		if is_instance_valid(shop.brax):
			var brax_position = shop.brax.get_grid_position()
			if brax_position != null and Vector2i(int(brax_position.x), int(brax_position.y)) == cell_key:
				return shop.brax
		for guard in shop.guards:
			if is_instance_valid(guard):
				var guard_position = guard.get_grid_position()
				if guard_position != null and Vector2i(int(guard_position.x), int(guard_position.y)) == cell_key:
					return guard
	return null

func has_actor_at(cell_key):
	for shop in _shops:
		if is_instance_valid(shop.brax):
			var brax_position = shop.brax.get_grid_position()
			if brax_position != null and Vector2i(int(brax_position.x), int(brax_position.y)) == cell_key:
				return true
		for guard in shop.guards:
			if is_instance_valid(guard):
				var guard_position = guard.get_grid_position()
				if guard_position != null and Vector2i(int(guard_position.x), int(guard_position.y)) == cell_key:
					return true
	return false

func register_shop(shop_definition, offset_cell, entity_grid):
	var shop_id = "shop_" + str(_next_shop_index)
	_next_shop_index += 1
	var shifted_bounds = Rect2i(
		shop_definition.bounds.position + offset_cell,
		shop_definition.bounds.size
	)
	var brax_home = shop_definition.brax_home + offset_cell if shop_definition.brax_home != Vector2i(-1, -1) else Vector2i(-1, -1)
	var brax_shop = shop_definition.brax_shop + offset_cell if shop_definition.brax_shop != Vector2i(-1, -1) else Vector2i(-1, -1)
	var brax_node = null
	if brax_home != Vector2i(-1, -1):
		brax_node = ShopkeeperScript.new()
		brax_node.init(shop_id, "Brax", false, false)
		entity_grid.add_entity(brax_home.x, brax_home.y, brax_node)
	var pedestals = []
	for local_cell in shop_definition.pedestal_cells:
		var world_cell = local_cell + offset_cell
		var pedestal = get_pedestal_at(world_cell.x, world_cell.y)
		if pedestal != null:
			pedestal.shop_id = shop_id
			pedestals.append(pedestal)
	var shop = {
		id = shop_id,
		bounds = shifted_bounds,
		brax_home = brax_home,
		brax_shop = brax_shop,
		brax = brax_node,
		pedestals = pedestals,
		guards = [],
		unpaid_total = 0,
		is_hostile = false,
		player_inside = false
	}
	_shops.append(shop)
	_shops_by_id[shop_id] = shop
	return shop

func teleport_brax_to_shop(shop, player_cell, entity_grid = null):
	if shop == null or shop.is_hostile or not is_instance_valid(shop.brax):
		return
	if shop.brax_shop == Vector2i(-1, -1):
		return
	var current_position = shop.brax.get_grid_position()
	var current_cell = Vector2i(int(current_position.x), int(current_position.y)) if current_position != null else null
	if current_cell != null and current_cell == shop.brax_shop:
		return
	if shop.brax_shop != player_cell and not has_actor_at(shop.brax_shop):
		shop.brax.teleport_to(shop.brax_shop)
		if entity_grid != null and current_cell != null:
			entity_grid.move_entity(shop.brax, current_cell, shop.brax_shop)

func teleport_brax_home(shop, player_cell, entity_grid = null):
	if shop == null or shop.is_hostile or not is_instance_valid(shop.brax):
		return
	if shop.brax_home == Vector2i(-1, -1):
		return
	var current_position = shop.brax.get_grid_position()
	var current_cell = Vector2i(int(current_position.x), int(current_position.y)) if current_position != null else null
	if current_cell != null and current_cell == shop.brax_home:
		return
	if shop.brax_home != player_cell and not has_actor_at(shop.brax_home):
		shop.brax.teleport_to(shop.brax_home)
		if entity_grid != null and current_cell != null:
			entity_grid.move_entity(shop.brax, current_cell, shop.brax_home)

func on_player_moved(player_position, entity_grid):
	var player_cell = Vector2i(int(player_position.x), int(player_position.y))
	for shop in _shops:
		var interior = Rect2i(
			shop.bounds.position + Vector2i(1, 1),
			shop.bounds.size - Vector2i(2, 2)
		)
		if interior.has_point(player_cell):
			if not shop.player_inside:
				shop.player_inside = true
				if not shop.is_hostile:
					shop_alert.emit("Welcome to Brax's Shop!", shop.brax.get_grid_position() if is_instance_valid(shop.brax) else player_cell, Color(1.0, 0.85, 0.35))
		elif shop.player_inside and not shop.bounds.has_point(player_cell):
			shop.player_inside = false
			if shop.unpaid_total > 0 and not shop.is_hostile:
				make_shop_hostile(shop, entity_grid, player_cell, "THIEF! Pay your tab!")
			elif not shop.is_hostile:
				teleport_brax_home(shop, player_cell, entity_grid)

func make_shop_hostile(shop, entity_grid, player_cell, reason = "THIEF! Dread Collectors summoned!"):
	if shop == null or shop.is_hostile:
		return
	shop.is_hostile = true
	if is_instance_valid(shop.brax):
		shop.brax.set_hostile(true)
	OD.Audio.play_sfx("cursed")
	var alert_position = shop.brax.get_grid_position() if is_instance_valid(shop.brax) else player_cell
	shop_alert.emit(reason, alert_position, Color(1.0, 0.25, 0.2))
	var guard_names = ["Dread Collector", "Big Red"]
	var spawn_origin = shop.brax_home if shop.brax_home != Vector2i(-1, -1) else player_cell
	for guard_name in guard_names:
		var spawn_cell = _find_spawn_cell(spawn_origin, player_cell, entity_grid)
		if spawn_cell != null:
			var guard = ShopkeeperScript.new()
			guard.init(shop.id, guard_name, true, true)
			entity_grid.add_entity(spawn_cell.x, spawn_cell.y, guard)
			shop.guards.append(guard)
			shop_alert.emit(guard_name + " appears!", spawn_cell, Color(1.0, 0.3, 0.2))

func _find_spawn_cell(origin, player_cell, entity_grid):
	for radius in range(1, 6):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var candidate = origin + Vector2i(dx, dy)
				if candidate == player_cell:
					continue
				if entity_grid.is_walkable(candidate.x, candidate.y):
					return candidate
	return null

func step_hostile_actors(entity_grid, player_position):
	var player_cell = Vector2i(int(player_position.x), int(player_position.y))
	for shop in _shops:
		if not shop.is_hostile:
			continue
		if is_instance_valid(shop.brax):
			var brax_result = shop.brax.step_toward(player_cell, entity_grid)
			if brax_result.get("attacked", false):
				OD.Audio.play_sfx("large_attack")
				hostile_attack.emit(brax_result.attacker, brax_result.damage, player_cell)
		for guard in shop.guards:
			if is_instance_valid(guard):
				var guard_result = guard.step_toward(player_cell, entity_grid)
				if guard_result.get("attacked", false):
					OD.Audio.play_sfx("large_attack")
					hostile_attack.emit(guard_result.attacker, guard_result.damage, player_cell)
