extends Node2D

class_name EntityGrid

const DoorScript = preload("res://script/instance/entity/door.gd")
const ElementScript = preload("res://script/instance/entity/dungeon_element.gd")
const TrapScript = preload("res://script/instance/entity/trap.gd")
const ShopPedestalScript = preload("res://script/instance/entity/shop_pedestal.gd")
const ShopManagerScript = preload("res://script/instance/shop_manager.gd")

signal script_ticker(message)
signal script_spell_cast(spell_name, grid_pos)
signal trap_triggered(trap_result, grid_pos)
signal teleporter_stepped(teleporter_info, grid_pos)

var layers = {
	list = [],
	lookup = {}
}

var layer_names = [
	"liquid",
	"wall",
	"wall_decoration",
	"floor",
	"floor_decoration",
	"trap",
	"custom_blocker",
	"custom_breakable",
	"pedestal",
	"statue",
	"custom_engraving",
	"element",	
	"loot",
	"cursor",
	"actors",
	"floating_text"
]

var xml_name_to_layer_name = {
	"customengraving": "custom_engraving",
	"customblocker": "custom_blocker",
	"lava": "liquid",
	"ice": "liquid",
	"goo": "liquid",
	"water": "liquid",
	"horde": "actors",
	"monster": "actors",
	"player": "actors",
	"element": "actors",
	"pedestal": "actors"
}

var animated_tile_lookup = {
	water = true,
	lava = true,
	ice = true,
	goo = true
}

var _tilesets
var _grid_lookup = null
var _grid_center = null
var _wall_cells = {}
var _floor_cells = {}
var _liquid_cells = {}
var _floor_tile_nodes = {}
var _liquid_edge_nodes = []
var _wall_decor_nodes = []
var _destructible_cells = {}
var _blocker_cells = {}
var _doors_by_cell = {}
var _elements_by_cell = {}
var _traps_by_cell = {}
var _loot_by_cell = {}
var _teleporters_by_cell = {}
var _stairs_by_cell = {}
var _named_entities = {}
var _room_scripts = []
var shop_manager = ShopManagerScript.new()
var pending_shop_def = null
var floor_level = 1
var branch_id = 0
var stairs_up_cell = null
var stairs_down_cell = null
var player_spawn_cell = null

func init(branch_id = 0):
	_tilesets = OD.Assets.tileset_for_branch(branch_id)
	var layer_order = 0
	for layer_name in layer_names:
		layer_order += 1
		var layer = Node2D.new()
		layer.name = layer_name
		layer.z_index = layer_order
		if layer_name == "actors":
			layer.y_sort_enabled = true
		layers.lookup[layer.name] = layer
		layers.list.append(layer)
		add_child(layer)

func resize(grid_width, grid_height):
	_grid_lookup = {}
	for ii in range(grid_width):
		_grid_lookup[ii] = {}
		for jj in range(grid_height):
			_grid_lookup[ii][jj] = {}
	_grid_center = Vector2(grid_width / 2, grid_height / 2)
	OD.Math.set_grid_center(_grid_center.x, _grid_center.y)
	position = Vector2(-_grid_center.x * OD.Assets.CELL_PIXEL_WIDTH, -_grid_center.y * OD.Assets.CELL_PIXEL_HEIGHT)

func insert(source_grid, offset_position):
	var offset_cell = Vector2i(int(offset_position.x), int(offset_position.y))
	for wall_cell in source_grid._wall_cells.keys():
		_wall_cells[wall_cell + offset_cell] = true
	for floor_cell in source_grid._floor_cells.keys():
		_floor_cells[floor_cell + offset_cell] = true
	for liquid_cell in source_grid._liquid_cells.keys():
		_liquid_cells[liquid_cell + offset_cell] = source_grid._liquid_cells[liquid_cell]
	for destructible_cell in source_grid._destructible_cells.keys():
		_destructible_cells[destructible_cell + offset_cell] = true
	for blocker_cell in source_grid._blocker_cells.keys():
		_blocker_cells[blocker_cell + offset_cell] = true
	for elem_cell in source_grid._elements_by_cell.keys():
		_elements_by_cell[elem_cell + offset_cell] = source_grid._elements_by_cell[elem_cell]
	for trap_cell in source_grid._traps_by_cell.keys():
		_traps_by_cell[trap_cell + offset_cell] = source_grid._traps_by_cell[trap_cell]
	for loot_cell in source_grid._loot_by_cell.keys():
		_loot_by_cell[loot_cell + offset_cell] = source_grid._loot_by_cell[loot_cell]
	for entity_id in source_grid._named_entities.keys():
		var info = source_grid._named_entities[entity_id]
		_named_entities[entity_id] = {
			node = info.node,
			layer = info.layer,
			cell = info.cell + offset_cell,
			is_blocker = info.is_blocker
		}
	for script_def in source_grid._room_scripts:
		var shifted_conditions = []
		for cond in script_def.conditions:
			var shifted_cond = cond.duplicate()
			if shifted_cond.has("grid_pos"):
				shifted_cond.grid_pos = shifted_cond.grid_pos + offset_cell
			shifted_conditions.append(shifted_cond)
		var shifted_actions = []
		for act in script_def.actions:
			var shifted_act = act.duplicate()
			if shifted_act.has("grid_pos"):
				shifted_act.grid_pos = shifted_act.grid_pos + offset_cell
			shifted_actions.append(shifted_act)
		_room_scripts.append({
			repeat = script_def.repeat,
			conditions = shifted_conditions,
			actions = shifted_actions
		})
	for layer_key in source_grid.layers.lookup.keys():
		var source_layer = source_grid.layers.lookup[layer_key]
		var target_layer = layers.lookup[layer_key]
		for child in source_layer.get_children():
			child.get_parent().remove_child(child)
			if child.has_method("get_grid_position") and child.get_grid_position() != null:
				var new_grid_pos = child.get_grid_position() + offset_position
				child.move_to(new_grid_pos.x, new_grid_pos.y)
			else:
				var source_cell = Vector2i(int(round(child.position.x)), int(round(child.position.y)))
				child.position = OD.Math.grid_to_pixel(child.position.x + offset_position.x, child.position.y + offset_position.y)
				if layer_key == "floor":
					_floor_tile_nodes[source_cell + offset_cell] = child
			target_layer.add_child(child)
	for ped_cell in source_grid.shop_manager._pedestals_by_cell.keys():
		var shifted_ped_cell = ped_cell + offset_cell
		shop_manager.register_pedestal(source_grid.shop_manager._pedestals_by_cell[ped_cell], shifted_ped_cell.x, shifted_ped_cell.y)
	if source_grid.pending_shop_def != null:
		shop_manager.register_shop(source_grid.pending_shop_def, offset_cell, self)
				
func get_layer(name):
	if xml_name_to_layer_name.has(name):
		return layers.lookup[xml_name_to_layer_name[name]]
	else:
		return layers.lookup[name]

func add_entity(grid_x, grid_y, entity):
	var layer = get_layer(entity.entity_kind)
	entity.position = OD.Math.grid_to_pixel(grid_x, grid_y)
	entity.move_to(grid_x, grid_y)
	layer.add_child(entity)

func add_animation(x, y, name, animation):
	var layer = get_layer(name)
	animation.position = Vector2(x, y)	
	layer.add_child(animation)

func add_tile(x, y, name, sprite_path = null):
	var layer = get_layer(name)
	var tile = null
	var cell_key = Vector2i(int(x), int(y))
	match name:
		"floor":
			_floor_cells[cell_key] = true
			tile = _tilesets.basic.get_tile(name)
			_floor_tile_nodes[cell_key] = tile
		"wall":
			_wall_cells[cell_key] = true
			tile = _tilesets.basic.get_tile(name)
		"ice","lava","goo","water":
			_liquid_cells[cell_key] = name
			tile = _tilesets.liquids.get_animation(name)
		_:
			tile = OD.Load.animation(sprite_path)
	tile.position = Vector2(x, y)
	layer.add_child(tile)

func mark_destructible(grid_x, grid_y):
	_destructible_cells[Vector2i(int(grid_x), int(grid_y))] = true

func mark_blocker(grid_x, grid_y):
	_blocker_cells[Vector2i(int(grid_x), int(grid_y))] = true

func is_destructible(grid_x, grid_y):
	return _destructible_cells.has(Vector2i(int(grid_x), int(grid_y)))

func is_blocked(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _wall_cells.has(cell_key) or _blocker_cells.has(cell_key):
		return true
	if _doors_by_cell.has(cell_key):
		var door = _doors_by_cell[cell_key]
		if is_instance_valid(door) and not door.can_pass():
			return true
	if shop_manager != null and shop_manager.has_actor_at(cell_key):
		return true
	return false

func is_walkable(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	return _floor_cells.has(cell_key) and not is_blocked(grid_x, grid_y)

func find_path(start_cell, goal_cell, max_visited = 4096):
	var start = Vector2i(int(start_cell.x), int(start_cell.y))
	var goal = Vector2i(int(goal_cell.x), int(goal_cell.y))
	if start == goal or not is_walkable(goal.x, goal.y):
		return []
	var frontier = [start]
	var came_from = {}
	came_from[start] = start
	var visited_count = 0
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var found = false
	var head = 0
	while head < frontier.size() and visited_count < max_visited:
		var current = frontier[head]
		head += 1
		visited_count += 1
		if current == goal:
			found = true
			break
		for dir in directions:
			var next_cell = current + dir
			if came_from.has(next_cell):
				continue
			if not is_walkable(next_cell.x, next_cell.y):
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)
	if not found:
		return []
	var path = []
	var step = goal
	while step != start:
		path.append(step)
		step = came_from[step]
	path.reverse()
	return path

func register_named_entity(entity_id, node, layer_name, grid_x, grid_y, is_blocker = false):
	if entity_id == null or entity_id == "":
		return
	_named_entities[entity_id] = {
		node = node,
		layer = layer_name,
		cell = Vector2i(int(grid_x), int(grid_y)),
		is_blocker = is_blocker
	}

func add_room_script(script_def):
	_room_scripts.append(script_def)

func evaluate_scripts(player_grid_pos):
	var player_cell = Vector2i(int(player_grid_pos.x), int(player_grid_pos.y))
	for script_def in _room_scripts:
		if script_def.repeat == 0:
			continue
		if _conditions_met(script_def.conditions, player_cell):
			if script_def.repeat > 0:
				script_def.repeat -= 1
			for action in script_def.actions:
				_execute_script_action(action, player_cell)

func _conditions_met(conditions, player_cell):
	for cond in conditions:
		if cond.get("condition_type", "") == "at":
			if not cond.has("grid_pos"):
				return false
			var target_cell = cond.grid_pos
			var target_id = cond.get("id", "")
			if target_id == "player":
				if player_cell != target_cell:
					return false
			else:
				if not _named_entities.has(target_id):
					return false
				if _named_entities[target_id].cell != target_cell:
					return false
	return true

func _execute_script_action(action, player_cell):
	if action.get("on", "success") != "success":
		return
	var action_type = action.get("action_type", "")
	match action_type:
		"remove":
			var target_id = action.get("id", "")
			if _named_entities.has(target_id):
				var info = _named_entities[target_id]
				if info.is_blocker:
					_blocker_cells.erase(info.cell)
				if is_instance_valid(info.node):
					if info.node.get_parent() != null:
						info.node.get_parent().remove_child(info.node)
					info.node.queue_free()
				_named_entities.erase(target_id)
		"move":
			var target_id = action.get("id", "")
			if _named_entities.has(target_id) and action.has("grid_pos"):
				var info = _named_entities[target_id]
				var dest = action.grid_pos
				if info.is_blocker:
					_blocker_cells.erase(info.cell)
					_blocker_cells[dest] = true
				info.cell = dest
				if is_instance_valid(info.node):
					info.node.position = OD.Math.grid_to_pixel(dest.x, dest.y)
		"create":
			if action.has("grid_pos"):
				var pos = action.grid_pos
				var create_type = action.get("create_type", "")
				var created_node = null
				var is_blocker = false
				if action.has("pngSprite"):
					created_node = OD.Load.png_sprite(action.pngSprite, int(action.get("pngFirst", 0)), int(action.get("pngNum", 1)), int(action.get("pngRate", 100)))
				elif action.has("png"):
					created_node = OD.Load.animation(action.png)
				elif create_type == "monster":
					var monster = OD.Database.get_monster(action.get("name", "")) if action.has("name") else OD.Database.get_random_monster()
					if monster != null:
						var palette_path = monster.palette.name if monster.has("palette") and monster.palette.has("name") else null
						created_node = OD.Load.animation(monster.idleSprite.down, palette_path)
				if created_node != null:
					var layer_name = create_type if layers.lookup.has(create_type) else "custom_blocker"
					var pixel_pos = OD.Math.grid_to_pixel(pos.x, pos.y)
					add_animation(pixel_pos.x, pixel_pos.y, layer_name, created_node)
					if create_type == "customblocker" and (not action.has("passable") or int(action.passable) == 0):
						mark_blocker(pos.x, pos.y)
						is_blocker = true
					if action.has("id"):
						register_named_entity(action.id, created_node, layer_name, pos.x, pos.y, is_blocker)
		"ticker":
			var msg = action.get("text", "")
			if msg != "":
				script_ticker.emit(msg)
		"spell":
			var spell_name = action.get("casts", "")
			if spell_name != "":
				script_spell_cast.emit(spell_name, player_cell)

func add_door(grid_x, grid_y, orientation = "ew", locked = false, style = "1x1"):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _doors_by_cell.has(cell_key):
		return _doors_by_cell[cell_key]
	var door = DoorScript.new()
	door.init(orientation, locked, style)
	if style == "3x3" and orientation == "ns":
		add_entity(grid_x, grid_y - 1, door)
		var aux = door.get_aux_node()
		if aux != null:
			aux.position = OD.Math.grid_to_pixel(grid_x, grid_y + 1)
			get_layer(door.entity_kind).add_child(aux)
		for dy in [-1, 0, 1]:
			var span_cell = Vector2i(int(grid_x), int(grid_y) + dy)
			if _wall_cells.has(span_cell):
				_wall_cells.erase(span_cell)
				add_floor_tile_at_grid(span_cell.x, span_cell.y)
			_doors_by_cell[span_cell] = door
	elif style == "3x3" and orientation == "ew":
		add_entity(grid_x, grid_y, door)
		for dx in [-1, 0, 1]:
			var span_cell = Vector2i(int(grid_x) + dx, int(grid_y))
			if _wall_cells.has(span_cell):
				_wall_cells.erase(span_cell)
				add_floor_tile_at_grid(span_cell.x, span_cell.y)
			_doors_by_cell[span_cell] = door
	else:
		add_entity(grid_x, grid_y, door)
		_doors_by_cell[cell_key] = door
	return door

func add_floor_tile_at_grid(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	_floor_cells[cell_key] = true
	var tile = _tilesets.basic.get_tile("floor")
	tile.position = OD.Math.grid_to_pixel(cell_key.x, cell_key.y)
	_floor_tile_nodes[cell_key] = tile
	get_layer("floor").add_child(tile)

func has_floor(grid_x, grid_y):
	return _floor_cells.has(Vector2i(int(grid_x), int(grid_y)))

func has_wall(grid_x, grid_y):
	return _wall_cells.has(Vector2i(int(grid_x), int(grid_y)))

func has_liquid(grid_x, grid_y):
	return _liquid_cells.has(Vector2i(int(grid_x), int(grid_y)))

func carve_liquid_cell(grid_x, grid_y, liquid_type):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _floor_tile_nodes.has(cell_key):
		var floor_node = _floor_tile_nodes[cell_key]
		if is_instance_valid(floor_node):
			if floor_node.get_parent() != null:
				floor_node.get_parent().remove_child(floor_node)
			floor_node.queue_free()
		_floor_tile_nodes.erase(cell_key)
	if liquid_type == "water" or liquid_type == "lava":
		_floor_cells.erase(cell_key)
		mark_blocker(cell_key.x, cell_key.y)
	_liquid_cells[cell_key] = liquid_type
	var anim = _tilesets.liquids.get_animation(liquid_type)
	var pixel_pos = OD.Math.grid_to_pixel(cell_key.x, cell_key.y)
	add_animation(pixel_pos.x, pixel_pos.y, "liquid", anim)

func add_floor_decal(grid_x, grid_y, decal_path):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	var decal_node = null
	if decal_path.ends_with(".spr"):
		decal_node = OD.Load.animation(decal_path)
	else:
		var tex = OD.Load.image(decal_path)
		if tex != null:
			var sprite = Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.texture = tex
			decal_node = sprite
	if decal_node != null:
		var pixel_pos = OD.Math.grid_to_pixel(cell_key.x, cell_key.y)
		decal_node.position = pixel_pos
		get_layer("floor_decoration").add_child(decal_node)
	return decal_node

func get_door_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _doors_by_cell.has(cell_key):
		var door = _doors_by_cell[cell_key]
		if is_instance_valid(door):
			return door
	return null

func add_element(grid_x, grid_y, element_type, animation, initial_data = {}):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	var element = ElementScript.new()
	element.init(element_type, animation, initial_data)
	add_entity(grid_x, grid_y, element)
	_elements_by_cell[cell_key] = element
	mark_blocker(grid_x, grid_y)
	return element

func get_element_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _elements_by_cell.has(cell_key):
		var element = _elements_by_cell[cell_key]
		if is_instance_valid(element):
			return element
	return null

func unblock_cell(grid_x, grid_y):
	_blocker_cells.erase(Vector2i(int(grid_x), int(grid_y)))

func add_stairs(grid_x, grid_y, direction):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	var sprite_path = "dungeon/stairs_up.spr" if direction == "up" else "dungeon/stairs_down.spr"
	var stairs_anim = OD.Load.animation(sprite_path)
	var pixel_pos = OD.Math.grid_to_pixel(cell_key.x, cell_key.y)
	if stairs_anim.is_tall():
		pixel_pos.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
	add_animation(pixel_pos.x, pixel_pos.y, "floor_decoration", stairs_anim)
	_stairs_by_cell[cell_key] = {
		direction = direction,
		node = stairs_anim
	}
	if direction == "up":
		stairs_up_cell = cell_key
	else:
		stairs_down_cell = cell_key
	return _stairs_by_cell[cell_key]

func get_stairs_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _stairs_by_cell.has(cell_key):
		return _stairs_by_cell[cell_key]
	return null

func add_teleporter(grid_x, grid_y, channel, target_cell, animation):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	var pixel_pos = OD.Math.grid_to_pixel(cell_key.x, cell_key.y)
	add_animation(pixel_pos.x, pixel_pos.y, "floor_decoration", animation)
	_teleporters_by_cell[cell_key] = {
		channel = channel,
		target_cell = Vector2i(int(target_cell.x), int(target_cell.y)),
		node = animation
	}
	return _teleporters_by_cell[cell_key]

func get_teleporter_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _teleporters_by_cell.has(cell_key):
		return _teleporters_by_cell[cell_key]
	return null

func add_trap(grid_x, grid_y, trap_def):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	var trap = TrapScript.new()
	trap.init(trap_def)
	add_entity(grid_x, grid_y, trap)
	_traps_by_cell[cell_key] = trap
	return trap

func add_loot_item(grid_x, grid_y, loot_data):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	var icon_path = ""
	if loot_data.get("kind", "") == "zorkmids":
		var cash_paths = OD.Resources.paths.loot.zorkmids
		var cash_idx = clamp(int(loot_data.get("amount", 10)) / 8, 0, cash_paths.size() - 1)
		icon_path = cash_paths[cash_idx]
	elif loot_data.get("kind", "") == "lockpick":
		icon_path = OD.Resources.paths.loot.lockpick
	elif loot_data.has("item") and loot_data.item != null:
		icon_path = loot_data.item.get("icon", "")
	if icon_path == "" or not OD.Load.exists(icon_path):
		return null
	var loot_node = null
	if icon_path.ends_with(".spr"):
		loot_node = OD.Load.animation(icon_path)
	else:
		var tex = OD.Load.image(icon_path)
		if tex != null:
			var sprite = Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.texture = tex
			loot_node = sprite
	if loot_node == null:
		return null
	var pixel_pos = OD.Math.grid_to_pixel(cell_key.x, cell_key.y)
	add_animation(pixel_pos.x, pixel_pos.y, "loot", loot_node)
	_loot_by_cell[cell_key] = {
		node = loot_node,
		data = loot_data
	}
	return _loot_by_cell[cell_key]

func get_loot_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _loot_by_cell.has(cell_key):
		return _loot_by_cell[cell_key]
	return null

func add_shop_pedestal(grid_x, grid_y, floor_level = 1):
	var pedestal = ShopPedestalScript.new()
	var rolled = shop_manager.roll_shop_item(floor_level)
	pedestal.init("", rolled)
	add_entity(grid_x, grid_y, pedestal)
	shop_manager.register_pedestal(pedestal, grid_x, grid_y)
	mark_blocker(grid_x, grid_y)
	return pedestal

func on_player_step(player_pos):
	evaluate_scripts(player_pos)
	update_trap_visibility(player_pos)
	trigger_trap_at(player_pos)
	if shop_manager != null:
		shop_manager.on_player_moved(player_pos, self)
		shop_manager.step_hostile_actors(self, player_pos)
	var teleporter = get_teleporter_at(player_pos.x, player_pos.y)
	if teleporter != null:
		teleporter_stepped.emit(teleporter, Vector2i(int(player_pos.x), int(player_pos.y)))

func get_trap_at(grid_x, grid_y):
	var cell_key = Vector2i(int(grid_x), int(grid_y))
	if _traps_by_cell.has(cell_key):
		var trap = _traps_by_cell[cell_key]
		if is_instance_valid(trap):
			return trap
	return null

func update_trap_visibility(player_pos, trap_sight_radius = 2, trap_sense_level = 1):
	for trap in _traps_by_cell.values():
		if is_instance_valid(trap):
			trap.update_visibility(player_pos, trap_sight_radius, trap_sense_level)

func trigger_trap_at(grid_pos):
	var cell_key = Vector2i(int(grid_pos.x), int(grid_pos.y))
	var trap = get_trap_at(cell_key.x, cell_key.y)
	if trap == null:
		return null
	var result = trap.step_on()
	if result != null:
		trap_triggered.emit(result, cell_key)
	return result

func auto_tile_walls():
	var wall_layer = layers.lookup["wall"]
	for child in wall_layer.get_children():
		wall_layer.remove_child(child)
		child.queue_free()
	for cell in _wall_cells.keys():
		var has_north = _wall_cells.has(cell + Vector2i(0, -1))
		var has_south = _wall_cells.has(cell + Vector2i(0, 1))
		var has_west = _wall_cells.has(cell + Vector2i(-1, 0))
		var has_east = _wall_cells.has(cell + Vector2i(1, 0))
		var tile = _tilesets.basic.get_wall_tile(has_north, has_south, has_west, has_east)
		tile.position = OD.Math.grid_to_pixel(cell.x, cell.y)
		wall_layer.add_child(tile)

func auto_tile_liquids():
	var floor_layer = layers.lookup["floor"]
	for node in _liquid_edge_nodes:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.queue_free()
	_liquid_edge_nodes.clear()
	for cell in _liquid_cells.keys():
		var has_n = _liquid_cells.has(cell + Vector2i(0, -1))
		var has_s = _liquid_cells.has(cell + Vector2i(0, 1))
		var has_w = _liquid_cells.has(cell + Vector2i(-1, 0))
		var has_e = _liquid_cells.has(cell + Vector2i(1, 0))
		var has_nw = _liquid_cells.has(cell + Vector2i(-1, -1))
		var has_ne = _liquid_cells.has(cell + Vector2i(1, -1))
		var has_sw = _liquid_cells.has(cell + Vector2i(-1, 1))
		var has_se = _liquid_cells.has(cell + Vector2i(1, 1))
		var edge_tile = _tilesets.basic.get_liquid_edge_tile(has_n, has_s, has_w, has_e, has_nw, has_ne, has_sw, has_se)
		if edge_tile != null:
			edge_tile.position = OD.Math.grid_to_pixel(cell.x, cell.y)
			floor_layer.add_child(edge_tile)
			_liquid_edge_nodes.append(edge_tile)

func decorate_walls():
	if not _tilesets.basic.has_tile("wallDecor"):
		return
	var decor_layer = layers.lookup["wall_decoration"]
	for node in _wall_decor_nodes:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.queue_free()
	_wall_decor_nodes.clear()
	var placed_decor = {}
	for cell in _wall_cells.keys():
		if _destructible_cells.has(cell):
			continue
		var north = cell + Vector2i(0, -1)
		var south = cell + Vector2i(0, 1)
		if not _wall_cells.has(north):
			continue
		if _wall_cells.has(south):
			continue
		if not _floor_cells.has(south) and not _liquid_cells.has(south):
			continue
		if _stairs_by_cell.has(south) or _doors_by_cell.has(south):
			continue
		if placed_decor.has(cell + Vector2i(-1, 0)) or placed_decor.has(cell + Vector2i(1, 0)):
			continue
		if randi() % 7 != 0:
			continue
		var decor_tile = _tilesets.basic.get_tile("wallDecor")
		decor_tile.position = OD.Math.grid_to_pixel(cell.x, cell.y)
		decor_layer.add_child(decor_tile)
		_wall_decor_nodes.append(decor_tile)
		placed_decor[cell] = true
	
func move(target_x, target_y, entity):
	entity.position = OD.Math.grid_to_pixel(target_x, target_y)
