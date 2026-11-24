extends Node2D

class_name Dungeon

const ElementDialogScript = preload("res://script/instance/ui/element_dialog.gd")
const ShopDialogScript = preload("res://script/instance/ui/shop_dialog.gd")

signal floor_changed(floor_level, branch_name)

var floors = []
# TODO Use ID instead of name
var _branch_name = "The Dungeon"
var _floor_level = 1
var _entity_grid
var _target_cursor
var _player

var FLOOR_STRATEGY = {
	CONNECT_DOORS = "connect_doors",
	DEBUG_ROOMS = "debug_rooms",
	ALL_ROOMS = "all_rooms",
	CENTER_PACK = "center_pack"
}

var _active_strategy = FLOOR_STRATEGY.CONNECT_DOORS
var _zorkmids_ref = { value = 150 }
var _lutefisk_ref = { value = 10 }
var _player_bag = []
var _interaction_dialog = null
var _pending_interaction = null

func global_coordinates_to_grid(x, y):
	var xform = get_global_transform_with_canvas()
	var scale_vec = xform.get_scale()
	var local_x = (x - xform.origin.x) / scale_vec.x
	var local_y = (y - xform.origin.y) / scale_vec.y
	var grid_x = floor((local_x + (OD.Assets.CELL_PIXEL_WIDTH / 2.0)) / OD.Assets.CELL_PIXEL_WIDTH)
	var grid_y = floor((local_y + (OD.Assets.CELL_PIXEL_HEIGHT / 2.0)) / OD.Assets.CELL_PIXEL_HEIGHT)
	return Vector2(grid_x, grid_y)
func init():	
	call_deferred("_build_ui")

func _input(ev):
	if is_instance_valid(_interaction_dialog):
		if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
			_close_element_dialog()
		return
	if ev is InputEventKey and ev.is_pressed():
		if ev.keycode == KEY_SPACE and not ev.echo:
			OD.Scenes.goto(OD.Scenes.GAME)
		elif not ev.echo and (ev.unicode == ord(">") or ev.unicode == ord("<")):
			if _entity_grid != null and _player != null:
				var player_pos = _player.get_grid_position()
				var stairs = _entity_grid.get_stairs_at(player_pos.x, player_pos.y)
				if stairs != null:
					var wanted = "down" if ev.unicode == ord(">") else "up"
					if stairs.direction == wanted:
						_change_floor(wanted)
						return
	if ev is InputEventMouseMotion:
		if _target_cursor != null and _entity_grid != null and ! _target_cursor.is_selecting():
			var grid_coords = global_coordinates_to_grid(ev.position.x, ev.position.y)
			_entity_grid.move(grid_coords.x, grid_coords.y, _target_cursor)
	if ev is InputEventMouseButton and ev.pressed and _target_cursor != null:
		var grid_coords = global_coordinates_to_grid(ev.position.x, ev.position.y)
		var allow_debug_teleport = _active_strategy == FLOOR_STRATEGY.DEBUG_ROOMS or OD.DungeonSettings.get_settings().get("debug_teleport", false)
		if ev.button_index == MOUSE_BUTTON_RIGHT and allow_debug_teleport:
			_pending_interaction = null
			OD.ActionQueue.clear()
			_target_cursor.select(grid_coords.x, grid_coords.y)
			_player.move_to(grid_coords.x, grid_coords.y)
			_player.idle()
			if _entity_grid != null:
				_entity_grid.on_player_step(_player.get_grid_position())
				var debug_stairs = _entity_grid.get_stairs_at(grid_coords.x, grid_coords.y)
				if debug_stairs != null:
					_change_floor(debug_stairs.direction)
			return
		if ev.button_index != MOUSE_BUTTON_LEFT:
			return
		_pending_interaction = null
		var shopkeeper = _entity_grid.shop_manager.get_shopkeeper_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if shopkeeper != null:
			_interact_or_approach({ kind = "shopkeeper", target_pos = Vector2i(int(grid_coords.x), int(grid_coords.y)) })
			return
		var shop_pedestal = _entity_grid.shop_manager.get_pedestal_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if shop_pedestal != null:
			_interact_or_approach({ kind = "shop_pedestal", target_pos = Vector2i(int(grid_coords.x), int(grid_coords.y)) })
			return
		var door = _entity_grid.get_door_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if door != null and not door.can_pass():
			_interact_or_approach({ kind = "door", target_pos = Vector2i(int(grid_coords.x), int(grid_coords.y)) })
			return
		var element = _entity_grid.get_element_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if element != null and not element.is_broken:
			_interact_or_approach({ kind = "element", target_pos = Vector2i(int(grid_coords.x), int(grid_coords.y)) })
			return
		var trap = _entity_grid.get_trap_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if trap != null and trap.is_discovered and not trap.is_disarmed:
			_interact_or_approach({ kind = "trap", target_pos = Vector2i(int(grid_coords.x), int(grid_coords.y)) })
			return
		var stairs = _entity_grid.get_stairs_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if stairs != null:
			var stairs_cell = Vector2i(int(grid_coords.x), int(grid_coords.y))
			var current_pos = _player.get_grid_position()
			if Vector2i(int(current_pos.x), int(current_pos.y)) == stairs_cell:
				_change_floor(stairs.direction)
			else:
				_move_to_stairs(stairs_cell, stairs.direction)
			return
		if _entity_grid != null and not _entity_grid.is_walkable(grid_coords.x, grid_coords.y):
			return
		_target_cursor.select(grid_coords.x, grid_coords.y)
		OD.ActionQueue.clear()
		var action = OD.Actions.MoveToLocation.new()
		action.init(_player, grid_coords, _entity_grid)
		OD.ActionQueue.add(action)

func _is_adjacent(pos_a, pos_b):
	return max(abs(int(pos_a.x) - int(pos_b.x)), abs(int(pos_a.y) - int(pos_b.y))) <= 1

func _find_best_adjacent_cell(target_cell):
	var player_pos = _player.get_grid_position()
	var best_cell = null
	var best_len = 999999
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate = target_cell + dir
		if not _entity_grid.is_walkable(candidate.x, candidate.y):
			continue
		var path = _entity_grid.find_path(player_pos, candidate)
		if not path.is_empty() and path.size() < best_len:
			best_len = path.size()
			best_cell = candidate
	return best_cell

func _interact_or_approach(interaction):
	var player_pos = _player.get_grid_position()
	if _is_adjacent(player_pos, interaction.target_pos):
		_execute_interaction(interaction)
		return
	var dest_cell = _find_best_adjacent_cell(interaction.target_pos)
	if dest_cell == null:
		return
	_pending_interaction = interaction
	_target_cursor.select(interaction.target_pos.x, interaction.target_pos.y)
	OD.ActionQueue.clear()
	var action = OD.Actions.MoveToLocation.new()
	action.init(_player, dest_cell, _entity_grid)
	action.completed.connect(_on_approach_completed)
	OD.ActionQueue.add(action)

func _move_to_stairs(stairs_cell, direction):
	if not _entity_grid.is_walkable(stairs_cell.x, stairs_cell.y):
		return
	_pending_interaction = { kind = "stairs", target_pos = stairs_cell, direction = direction }
	_target_cursor.select(stairs_cell.x, stairs_cell.y)
	OD.ActionQueue.clear()
	var action = OD.Actions.MoveToLocation.new()
	action.init(_player, stairs_cell, _entity_grid)
	action.completed.connect(_on_approach_completed)
	OD.ActionQueue.add(action)

func _on_approach_completed(reached):
	if not reached or _pending_interaction == null:
		_pending_interaction = null
		return
	var interaction = _pending_interaction
	_pending_interaction = null
	if interaction.kind == "stairs":
		var player_pos = _player.get_grid_position()
		if Vector2i(int(player_pos.x), int(player_pos.y)) == interaction.target_pos:
			_change_floor(interaction.direction)
		return
	if _is_adjacent(_player.get_grid_position(), interaction.target_pos):
		_execute_interaction(interaction)

func _execute_interaction(interaction):
	var pos = interaction.target_pos
	match interaction.kind:
		"door":
			var door = _entity_grid.get_door_at(pos.x, pos.y)
			if door != null and not door.can_pass():
				door.interact()
		"element":
			var element = _entity_grid.get_element_at(pos.x, pos.y)
			if element != null and not element.is_broken:
				_handle_element_interaction(element, pos)
		"trap":
			var trap = _entity_grid.get_trap_at(pos.x, pos.y)
			if trap != null and trap.is_discovered and not trap.is_disarmed:
				_handle_trap_disarm(trap)
		"shopkeeper":
			var keeper = _entity_grid.shop_manager.get_shopkeeper_at(pos.x, pos.y)
			if keeper != null:
				_handle_shopkeeper_interaction(keeper, pos)
		"shop_pedestal":
			var pedestal = _entity_grid.shop_manager.get_pedestal_at(pos.x, pos.y)
			if pedestal != null:
				_handle_shop_pedestal_interaction(pedestal, pos)

func _connect_grid_signals(grid):
	grid.trap_triggered.connect(_on_trap_triggered)
	grid.shop_manager.shop_alert.connect(_on_shop_alert)
	grid.shop_manager.hostile_attack.connect(_on_hostile_attack)

func _create_floor(floor_level):
	var strategy = _active_strategy
	var grid = load("res://script/instance/room_placement/" + strategy + "_strategy.gd").generate(_branch_name, floor_level)
	grid.name = "EntityGrid-" + strategy + "_strategy-F" + str(floor_level)
	_connect_grid_signals(grid)
	while floors.size() < floor_level:
		floors.append(null)
	floors[floor_level - 1] = grid
	return grid

func _resolve_floor_spawn_cell(grid, direction):
	if direction == "down" and grid.stairs_up_cell != null:
		return grid.stairs_up_cell
	if direction == "up" and grid.stairs_down_cell != null:
		return grid.stairs_down_cell
	var settings = OD.DungeonSettings.get_settings()
	return Vector2i(settings.player_start_x, settings.player_start_y)

func _change_floor(direction):
	var target_level = _floor_level + 1 if direction == "down" else _floor_level - 1
	if target_level < 1:
		var pos = _player.get_grid_position()
		_spawn_floating_text(pos, "The exit is blocked.", Color(0.9, 0.7, 0.5))
		return
	_pending_interaction = null
	OD.ActionQueue.clear()
	_close_element_dialog()
	if _player.get_parent() != null:
		_player.get_parent().remove_child(_player)
	if _target_cursor.get_parent() != null:
		_target_cursor.get_parent().remove_child(_target_cursor)
	if _entity_grid != null and _entity_grid.get_parent() == self:
		remove_child(_entity_grid)
	_floor_level = target_level
	if floors.size() >= _floor_level and floors[_floor_level - 1] != null:
		_entity_grid = floors[_floor_level - 1]
	else:
		_entity_grid = _create_floor(_floor_level)
	add_child(_entity_grid)
	if _entity_grid._grid_center != null:
		OD.Math.set_grid_center(_entity_grid._grid_center.x, _entity_grid._grid_center.y)
	var spawn_cell = _resolve_floor_spawn_cell(_entity_grid, direction)
	_entity_grid.add_entity(spawn_cell.x, spawn_cell.y, _player)
	_player.idle()
	_entity_grid.add_entity(spawn_cell.x, spawn_cell.y, _target_cursor)
	_entity_grid.update_trap_visibility(_player.get_grid_position())
	OD.Audio.play_sfx("stairs")
	_spawn_floating_text(spawn_cell, "Floor " + str(_floor_level), Color(0.95, 0.9, 0.45))
	floor_changed.emit(_floor_level, _branch_name)

func get_floor_level():
	return _floor_level

func get_branch_name():
	return _branch_name

func get_player_global_position():
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree():
		return _player.global_position
	return null

func _build_ui():
	_player = PlayerCharacter.new()
	_player.init()
	_target_cursor = TargetCursor.new()
	_target_cursor.init()
	var settings = OD.DungeonSettings.get_settings()
	_entity_grid = _create_floor(_floor_level)
	_entity_grid.add_entity(settings.player_start_x, settings.player_start_y, _player)
	add_child(_entity_grid)
	_entity_grid.add_entity(0, 0, _target_cursor)
	_entity_grid.update_trap_visibility(_player.get_grid_position())
	_seed_player_bag()
	floor_changed.emit(_floor_level, _branch_name)

func _on_trap_triggered(trap_result, grid_pos):
	_spawn_spell_vfx(trap_result.casts_spell, grid_pos)
	_spawn_floating_text(grid_pos, trap_result.trap_name + "!", Color(1.0, 0.35, 0.25))

func _handle_trap_disarm(trap):
	var disarm_res = trap.attempt_disarm()
	var pos = trap.get_grid_position()
	if disarm_res.success:
		_spawn_floating_text(pos, "Disarmed!", Color(0.45, 0.95, 0.45))
	else:
		if disarm_res.has("triggered") and disarm_res.triggered != null:
			_spawn_spell_vfx(disarm_res.triggered.casts_spell, pos)
		_spawn_floating_text(pos, "Trap Triggered!", Color(1.0, 0.35, 0.25))

func _spawn_spell_vfx(spell_name, grid_pos):
	if spell_name == "" or _entity_grid == null:
		return
	var spell = OD.Database.get_spell(spell_name)
	if spell == null or spell.anim == null or typeof(spell.anim) != TYPE_DICTIONARY:
		return
	var anim_def = spell.anim
	if anim_def.has("sfx"):
		OD.Audio.play_sfx(anim_def.sfx)
	if anim_def.has("sprite") and anim_def.has("frames"):
		var first_idx = int(anim_def.get("first", 0))
		var frame_count = int(anim_def.frames)
		var frame_rate = int(anim_def.get("framerate", 80))
		var vfx = OD.Load.png_sprite(anim_def.sprite, first_idx, first_idx + frame_count, frame_rate)
		if vfx != null:
			var px = OD.Math.grid_to_pixel(grid_pos.x, grid_pos.y)
			_entity_grid.add_animation(px.x, px.y, "player", vfx)
			vfx.animation_complete.connect(func():
				if is_instance_valid(vfx):
					vfx.queue_free()
			)

func _spawn_floating_text(grid_pos, text, color):
	if _entity_grid == null:
		return
	var label = Label.new()
	label.text = text
	var px = OD.Math.grid_to_pixel(grid_pos.x, grid_pos.y)
	label.position = px + Vector2(-80, -32)
	label.custom_minimum_size = Vector2(160, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OD.Assets.dialog().font)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_entity_grid.get_layer("player").add_child(label)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

func is_dialog_open():
	return is_instance_valid(_interaction_dialog)

func _close_element_dialog():
	if is_instance_valid(_interaction_dialog):
		_interaction_dialog.queue_free()
		_interaction_dialog = null

func _handle_element_interaction(element, grid_coords):
	_close_element_dialog()
	_interaction_dialog = ElementDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_element_dialog(
		element,
		_zorkmids_ref,
		_lutefisk_ref,
		func(): _interaction_dialog = null,
		func(): _entity_grid.unblock_cell(grid_coords.x, grid_coords.y)
	)

func _seed_player_bag():
	if not _player_bag.is_empty():
		return
	var sell_scaler = float(OD.Database.get_tweak("store sell price scaler", 0.63))
	for item_entry in OD.Database.get_all_items():
		if item_entry.price > 0 and item_entry.icon != "":
			_player_bag.append({
				name = item_entry.name,
				icon = item_entry.icon,
				sell_price = max(1, int(round(float(item_entry.price) * sell_scaler))),
				description = item_entry.description
			})
			if _player_bag.size() >= 3:
				break

func _on_shop_alert(message, grid_pos, color):
	_spawn_floating_text(grid_pos, message, color)

func _on_hostile_attack(attacker_name, damage, grid_pos):
	_spawn_floating_text(grid_pos, attacker_name + " hits -" + str(damage), Color(1.0, 0.2, 0.2))

func _handle_shopkeeper_interaction(keeper, pos):
	if keeper.is_hostile:
		keeper.hp -= 25
		OD.Audio.play_sfx("large_damage")
		_spawn_floating_text(pos, "-25 HP", Color(1.0, 0.85, 0.25))
		if keeper.hp <= 0:
			OD.Audio.play_sfx("large_die")
			_spawn_floating_text(pos, keeper.monster_name + " defeated!", Color(0.45, 0.95, 0.45))
			keeper.queue_free()
		return
	var shop = _entity_grid.shop_manager.get_shop_by_id(keeper.shop_id)
	if shop == null:
		return
	var player_pos = _player.get_grid_position()
	var player_cell = Vector2i(int(player_pos.x), int(player_pos.y))
	_entity_grid.shop_manager.teleport_brax_to_shop(shop, player_cell)
	_close_element_dialog()
	_interaction_dialog = ShopDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_brax_dialog(
		shop,
		_zorkmids_ref,
		_player_bag,
		func(): _interaction_dialog = null,
		func(): _entity_grid.shop_manager.make_shop_hostile(shop, _entity_grid, player_cell)
	)

func _handle_shop_pedestal_interaction(pedestal, pos):
	if not pedestal.has_item():
		_spawn_floating_text(pos, "Empty pedestal", Color(0.85, 0.85, 0.85))
		return
	var shop = _entity_grid.shop_manager.get_shop_by_id(pedestal.shop_id)
	var player_pos = _player.get_grid_position()
	var player_cell = Vector2i(int(player_pos.x), int(player_pos.y))
	if shop != null and not shop.is_hostile:
		_entity_grid.shop_manager.teleport_brax_to_shop(shop, player_cell)
	_close_element_dialog()
	_interaction_dialog = ShopDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_pedestal_dialog(
		pedestal,
		shop,
		_zorkmids_ref,
		_player_bag,
		func(): _interaction_dialog = null,
		func(): _entity_grid.shop_manager.make_shop_hostile(shop, _entity_grid, player_cell)
	)
		
