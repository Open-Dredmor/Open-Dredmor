extends Node2D

class_name Dungeon

const ElementDialogScript = preload("res://script/instance/ui/element_dialog.gd")
const CraftingDialogScript = preload("res://script/instance/ui/crafting_dialog.gd")
const ShopDialogScript = preload("res://script/instance/ui/shop_dialog.gd")
const PocketDimensionScript = preload("res://script/instance/room_placement/pocket_dimension.gd")
const CommandProcessorScript = preload("res://script/instance/command/command_processor.gd")
const InputMapperScript = preload("res://script/instance/input/input_mapper.gd")
const TurnSchedulerScript = preload("res://script/instance/turn/turn_scheduler.gd")
const CombatResolverScript = preload("res://script/instance/combat/combat_resolver.gd")
const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")
const CastSpellCommandScript = preload("res://script/instance/command/cast_spell_command.gd")
const UseItemCommandScript = preload("res://script/instance/command/use_item_command.gd")
const DeathManagerScript = preload("res://script/instance/death_manager.gd")
const FloatingCombatTextScript = preload("res://script/instance/ui/floating_combat_text.gd")
const SaveManagerScript = preload("res://script/instance/save_manager.gd")
const GridSerializerScript = preload("res://script/instance/grid_serializer.gd")

signal floor_changed(floor_level, branch_name)
signal fov_updated()
signal spell_cast_completed(spell_name, result)
signal spell_targeting_changed(spell_name)
signal player_died(death_summary)

var floors = []
# TODO Use ID instead of name
var _branch_name = "The Dungeon"
var _floor_level = 1
var _entity_grid
var _target_cursor
var _player

var FLOOR_STRATEGY = {
	CONNECT_DOORS = "connect_doors",
	RETAIL = "retail",
	DEBUG_ROOMS = "debug_rooms",
	ALL_ROOMS = "all_rooms",
	CENTER_PACK = "center_pack"
}

var _active_strategy = FLOOR_STRATEGY.RETAIL
var _zorkmids_ref = { value = 150 }
var _lutefisk_ref = { value = 10 }
var _player_bag = []
var _interaction_dialog = null
var _crafting_dialog = null
var _pending_spell_name = ""
var _pending_wand_inventory_index = -1
var _monsters_killed = 0
var _discovered_rooms = {}
var _pending_interaction = null
var _in_pocket_dimension = false
var _pocket_dimensions = {}
var _saved_main_return_cell = null
var _command_processor = CommandProcessorScript.new()
var _input_mapper = InputMapperScript.new()
var _turn_scheduler = TurnSchedulerScript.new()

func get_command_processor():
	return _command_processor

func get_input_mapper():
	return _input_mapper

func get_turn_scheduler():
	return _turn_scheduler

func clear_pending_interaction():
	_pending_interaction = null

func change_floor_to(direction):
	_change_floor(direction)

func _build_command_context():
	var allow_debug_teleport = _active_strategy == FLOOR_STRATEGY.DEBUG_ROOMS or OD.DungeonSettings.get_settings().get("debug_teleport", false)
	return {
		dungeon = self,
		entity_grid = _entity_grid,
		player = _player,
		target_cursor = _target_cursor,
		allow_debug_teleport = allow_debug_teleport
	}

func submit_command(command):
	return _turn_scheduler.submit_command(command, _build_command_context())

func execute_interact_command(command):
	var kind = command.interaction_kind
	var cell = command.target_cell
	if kind == "pickup":
		var current_position = _player.get_grid_position() if _player != null else null
		if current_position == null or Vector2i(int(current_position.x), int(current_position.y)) == cell:
			return pickup_loot_at_player()
		return _move_to_pickup(cell)
	if kind == "stairs":
		var stairs = _entity_grid.get_stairs_at(cell.x, cell.y)
		if stairs == null:
			return false
		var current_position = _player.get_grid_position()
		if Vector2i(int(current_position.x), int(current_position.y)) == cell:
			_change_floor(stairs.direction)
		else:
			_move_to_stairs(cell, stairs.direction)
		return true
	return _interact_or_approach({ kind = kind, target_pos = cell })

func _get_player_melee_weapon_damage():
	if _player == null or _player.equipment == null:
		return null
	var combined = {}
	var has_weapon = false
	for slot_name in ["weapon_right", "weapon_left"]:
		var item = _player.equipment.get(slot_name, null)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var damage_source = item.get("weapon_damage", item)
			for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
				if damage_source.has(damage_type):
					has_weapon = true
					combined[damage_type] = int(combined.get(damage_type, 0)) + int(damage_source[damage_type])
	return combined if has_weapon else null

func _handle_enemy_death(enemy, grid_position):
	if enemy == null:
		return
	_monsters_killed += 1
	var enemy_name = enemy.get("monster_name") if enemy.get("monster_name") != null else "Enemy"
	if enemy.has_method("play_sfx"):
		enemy.play_sfx("die")
	else:
		OD.Audio.play_sfx("large_die")
	var xp_gain = enemy.get_xp_value() if enemy.has_method("get_xp_value") else 10
	_spawn_floating_text(grid_position, enemy_name + " defeated! +" + str(xp_gain) + " XP", Color(0.45, 0.95, 0.45))
	_log_event("The " + enemy_name + " is defeated! (+" + str(xp_gain) + " XP)")
	if enemy.has_method("play_sfx"):
		enemy.play_sfx("die")
	if enemy.has_method("play_die_animation_at"):
		enemy.play_die_animation_at(_entity_grid, grid_position)
	award_xp(xp_gain, grid_position)
	if _player != null and _player.has_method("advance_kill_quests"):
		var done_quests = _player.advance_kill_quests(_floor_level)
		for completed_quest in done_quests:
			var q_title = str(completed_quest.get("title", "Quest"))
			_log_event("Quest Completed: " + q_title + "!")
			_spawn_floating_text(grid_position, "Quest Complete!", Color(1.0, 0.88, 0.35))
	if enemy.has_method("roll_drops") and _entity_grid != null:
		for drop_data in enemy.roll_drops():
			_entity_grid.add_loot_item(grid_position.x, grid_position.y, drop_data)
	var drop_chance = int(OD.Database.get_tweak("monster loot drop chance", 3))
	if drop_chance > 0 and (randi() % drop_chance) == 0 and _entity_grid != null:
		var gold_per_level = max(1, int(OD.Database.get_tweak("gold drop per level", 3)))
		var gold_amount = randi_range(1, gold_per_level * max(1, _floor_level))
		_entity_grid.add_loot_item(grid_position.x, grid_position.y, { kind = "zorkmids", amount = gold_amount })
	if _entity_grid != null:
		_entity_grid.unregister_entity(enemy, grid_position)
	enemy.queue_free()
	if enemy_name == "Lord Dredmor":
		DeathManagerScript.record_high_score(_player, _floor_level, "Defeated Lord Dredmor", _monsters_killed, DeathManagerScript.HIGH_SCORES_PATH, true)
		_log_event("Victory! You have defeated Lord Dredmor!")

func _resolve_player_attack(target, target_cell, options = {}):
	if _player == null or target == null:
		return false
	var attack_opts = options.duplicate()
	var kind = str(attack_opts.get("kind", "melee"))
	if kind == "melee" and not attack_opts.has("weapon"):
		var weapon_damage = _get_player_melee_weapon_damage()
		if weapon_damage != null:
			attack_opts["weapon"] = weapon_damage
		else:
			attack_opts["weapon"] = { crushing = 2 }
	var player_position = _player.get_grid_position()
	if player_position != null:
		_player.face_towards(target_cell)
	_player.play_attack_animation(kind)
	var target_name = str(target.get("monster_name")) if target.get("monster_name") != null else "Enemy"
	var result = CombatResolverScript.resolve_attack(_player, target, attack_opts)
	if not result.hit:
		if OD.Audio != null:
			OD.Audio.play_sfx("evade")
		spawn_floating_badge(target_cell, "dodge", "Dodged!")
		_log_event("The " + target_name + " dodges your attack!")
		if result.ammo_recovered and _entity_grid != null and attack_opts.has("ammo_item"):
			_entity_grid.add_loot_item(target_cell.x, target_cell.y, attack_opts.ammo_item)
		return true
	target.hp -= result.total_damage
	if target.has_method("refresh_health_bar"):
		target.refresh_health_bar()
	if target.has_method("play_hit_animation"):
		target.play_hit_animation()
	if result.critical and OD.Audio != null:
		OD.Audio.play_sfx("crit")
	if target.has_method("play_sfx"):
		target.play_sfx("hit")
	else:
		OD.Audio.play_sfx("large_damage")
	var tag_suffix = ""
	if result.critical:
		tag_suffix += " CRIT!"
		spawn_floating_badge(target_cell, "crit", "CRIT!")
	if result.blocked:
		tag_suffix += " (Blocked)"
		spawn_floating_badge(target_cell, "block", "Blocked!")
	var damage_color = Color(1.0, 0.55, 0.15) if result.critical else Color(1.0, 0.85, 0.25)
	var damage_scale = 1.25 if result.critical else 1.0
	_spawn_floating_text(target_cell, "-" + str(result.total_damage), damage_color, damage_scale)
	_log_event("You hit the " + target_name + " for " + str(result.total_damage) + " damage!" + tag_suffix)
	if target.has_method("on_hit_received"):
		target.on_hit_received()
	if _player.has_method("on_attack_performed"):
		for proc_spell in _player.on_attack_performed():
			SpellEngineScript.execute_spell(proc_spell, _player, target_cell, {
				entity_grid = _entity_grid,
				dungeon = self,
				free_cast = true
			})
	if result.ammo_recovered and _entity_grid != null and attack_opts.has("ammo_item"):
		_entity_grid.add_loot_item(target_cell.x, target_cell.y, attack_opts.ammo_item)
	if target.hp <= 0:
		_handle_enemy_death(target, target_cell)
		return true
	if result.countered and player_position != null:
		var counter_result = CombatResolverScript.resolve_attack(target, _player, { kind = "melee", is_counter = true })
		if counter_result.hit and counter_result.total_damage > 0:
			_player.modify_hp(-counter_result.total_damage, str(target.get("monster_name")))
			var p_cell = Vector2i(int(player_position.x), int(player_position.y))
			spawn_floating_badge(p_cell, "counter", "Counter!")
			_spawn_floating_text(p_cell, "-" + str(counter_result.total_damage), Color(1.0, 0.3, 0.3))
			_log_event("The " + target_name + " counters for " + str(counter_result.total_damage) + " damage!")
			_trigger_player_hit_procs(target_cell)
	return true

func execute_ranged_attack(target_cell, options = {}):
	if _entity_grid == null or _player == null:
		return false
	var enemy = _entity_grid.get_enemy_at(target_cell.x, target_cell.y)
	if enemy == null:
		_spawn_floating_text(target_cell, "No target", Color(0.8, 0.8, 0.8))
		return false
	if OD.Audio != null:
		var ranged_kind = str(options.get("kind", ""))
		OD.Audio.play_sfx("bow" if ranged_kind == "bolt" else "missile")
	return _resolve_player_attack(enemy, target_cell, options)

func execute_attack_at(target_cell):
	if _entity_grid == null or _player == null:
		return false
	var enemy = _entity_grid.get_enemy_at(target_cell.x, target_cell.y)
	var element = _entity_grid.get_element_at(target_cell.x, target_cell.y)
	var is_breakable = element != null and not element.is_broken and element.element_type == "custom_breakable"
	if enemy == null and not is_breakable:
		return false
	var player_position = _player.get_grid_position()
	if player_position != null and not _is_adjacent(player_position, target_cell):
		return _interact_or_approach({ kind = "attack", target_pos = target_cell })
	if enemy != null:
		return _resolve_player_attack(enemy, target_cell, { kind = "melee" })
	if is_breakable:
		_handle_element_interaction(element, target_cell)
		return true
	return false

func execute_cast_spell(spell_name, target_cell):
	if spell_name == "" or _entity_grid == null or _player == null:
		return false
	_player.face_towards(target_cell)
	_player.play_cast_animation()
	var result = SpellEngineScript.execute_spell(spell_name, _player, target_cell, _build_command_context())
	if not result.get("executed", false):
		var p_position = _player.get_grid_position()
		var p_cell = Vector2i(int(p_position.x), int(p_position.y)) if p_position != null else target_cell
		_spawn_floating_text(p_cell, str(result.get("reason", "Cannot cast")), Color(1.0, 0.5, 0.45))
		return false
	spell_cast_completed.emit(spell_name, result)
	return true

func begin_spell_targeting(spell_name):
	if spell_name == "" or _player == null:
		return false
	var spell_definition = OD.Database.get_spell(spell_name) if OD.Database != null else null
	if spell_definition == null:
		return false
	var check = SpellEngineScript.can_cast(_player, spell_definition)
	if not check.ok:
		var p_position = _player.get_grid_position()
		if p_position != null:
			_spawn_floating_text(Vector2i(int(p_position.x), int(p_position.y)), check.reason, Color(1.0, 0.5, 0.45))
		return false
	if not SpellEngineScript.requires_target_selection(spell_definition):
		var p_position = _player.get_grid_position()
		var p_cell = Vector2i(int(p_position.x), int(p_position.y)) if p_position != null else Vector2i.ZERO
		var cmd = CastSpellCommandScript.new().init(_player, spell_name, p_cell)
		submit_command(cmd)
		return true
	_pending_spell_name = spell_name
	spell_targeting_changed.emit(_pending_spell_name)
	return true

func cancel_spell_targeting():
	if _pending_spell_name == "" and _pending_wand_inventory_index < 0:
		return
	_pending_spell_name = ""
	_pending_wand_inventory_index = -1
	spell_targeting_changed.emit("")

func is_targeting_spell():
	return _pending_spell_name != ""

func get_pending_spell_name():
	return _pending_spell_name

func begin_use_inventory_item(inventory_index):
	if _player == null or inventory_index < 0 or inventory_index >= _player.inventory.size():
		return { targeting = false, executed = false }
	var item = _player.inventory[inventory_index]
	if item == null or not _player.is_item_usable(item):
		return { targeting = false, executed = false }
	var cat = str(item.get("category", ""))
	if cat == "toolkit":
		var tool_tag = OD.Database.get_toolkit_tag_for_item(item) if OD.Database != null else ""
		return { targeting = false, executed = true, open_crafting = true, tool_tag = tool_tag }
	if cat == "wand":
		var wand_spell = str(item.get("wand_spell", ""))
		var spell_definition = OD.Database.get_spell(wand_spell) if OD.Database != null and wand_spell != "" else null
		if spell_definition != null and SpellEngineScript.requires_target_selection(spell_definition):
			_pending_wand_inventory_index = inventory_index
			_pending_spell_name = wand_spell
			spell_targeting_changed.emit(_pending_spell_name)
			return { targeting = true, spell_name = wand_spell }
	var p_position = _player.get_grid_position()
	var p_cell = Vector2i(int(p_position.x), int(p_position.y)) if p_position != null else Vector2i.ZERO
	var cmd = UseItemCommandScript.new().init(_player, { kind = "inventory_consumable", inv_idx = inventory_index, item = item }, p_cell)
	submit_command(cmd)
	return { targeting = false, executed = true }

func execute_use_item(item_data, target_cell):
	if item_data.is_empty() or _player == null:
		return false
	var item_kind = str(item_data.get("kind", ""))
	if item_kind == "bolt" or item_kind == "thrown":
		return execute_ranged_attack(target_cell, {
			kind = item_kind,
			ammo = item_data.get("damage", item_data),
			ammo_item = item_data
		})
	if item_kind == "inventory_consumable":
		var inventory_index = int(item_data.get("inv_idx", -1))
		var result = _player.use_consumable_at(inventory_index, target_cell, _build_command_context())
		var p_position = _player.get_grid_position()
		var p_cell = Vector2i(int(p_position.x), int(p_position.y)) if p_position != null else target_cell
		if not result.get("executed", false):
			_log_event(str(result.get("reason", "Cannot use")))
			return false
		var result_kind = str(result.get("kind", ""))
		if result_kind == "food":
			_player.play_eat_animation()
			if OD.Audio != null:
				OD.Audio.play_sfx("eat")
			_spawn_floating_text(p_cell, "+" + str(result.get("hp_per_turn", 1)) + " HP/turn", Color(0.45, 0.95, 0.45))
		elif result_kind == "booze":
			_player.play_drink_animation()
			if OD.Audio != null:
				OD.Audio.play_sfx("drink")
			_spawn_floating_text(p_cell, "Tipsy! +" + str(result.get("mp_per_turn", 1)) + " MP/turn", Color(0.45, 0.78, 1.0))
		elif result_kind == "potion":
			_player.play_drink_animation()
			if OD.Audio != null:
				OD.Audio.play_sfx("drink")
			_log_event("Used " + str(result.get("item_name", "Item")) + ".")
		elif result_kind == "mushroom":
			_player.play_eat_animation()
			if OD.Audio != null:
				OD.Audio.play_sfx("eat")
			_log_event("Used " + str(result.get("item_name", "Item")) + ".")
		elif result_kind == "wand":
			_player.face_towards(target_cell)
			_player.play_cast_animation()
			if result.get("burned_out", false):
				_log_event(str(result.get("item_name", "Wand")) + " burned out!")
			else:
				_log_event("Used " + str(result.get("spell_name", "Wand")) + " (" + str(result.get("remaining_charges", 0)) + " charges left).")
		else:
			_log_event("Used " + str(result.get("item_name", "Item")) + ".")
		return true
	_log_event("Used " + str(item_data.get("name", "Item")) + ".")
	return true

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

func init_async():
	await _build_ui_async()

func handle_dungeon_input(event):
	if _player != null and _player.is_dead:
		return
	if is_instance_valid(_interaction_dialog):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_element_dialog()
		return
	if event is InputEventKey and event.is_pressed() and not event.echo and _input_mapper.is_action_key("restart_scene", event.keycode):
		OD.Scenes.goto(OD.Scenes.GAME)
		return
	if event is InputEventMouseMotion:
		if _target_cursor != null and _entity_grid != null and ! _target_cursor.is_selecting():
			var grid_coordinates = global_coordinates_to_grid(event.position.x, event.position.y)
			_entity_grid.move(grid_coordinates.x, grid_coordinates.y, _target_cursor)
		return
	if _turn_scheduler.is_auto_stepping() and ((event is InputEventKey and event.is_pressed() and not event.echo) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed)):
		_turn_scheduler.cancel_auto_actions()
		return
	if _turn_scheduler.is_busy():
		return
	if _pending_spell_name != "":
		if event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_ESCAPE:
			cancel_spell_targeting()
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_spell_targeting()
			return
		if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var target_coordinates = global_coordinates_to_grid(event.position.x, event.position.y)
			var chosen_cell = Vector2i(int(target_coordinates.x), int(target_coordinates.y))
			if _pending_wand_inventory_index >= 0:
				var chosen_inventory_index = _pending_wand_inventory_index
				var wand_item = _player.inventory[chosen_inventory_index] if chosen_inventory_index < _player.inventory.size() else {}
				_pending_wand_inventory_index = -1
				_pending_spell_name = ""
				spell_targeting_changed.emit("")
				var wand_cmd = UseItemCommandScript.new().init(_player, { kind = "inventory_consumable", inv_idx = chosen_inventory_index, item = wand_item }, chosen_cell)
				submit_command(wand_cmd)
				return
			var chosen_spell = _pending_spell_name
			_pending_spell_name = ""
			spell_targeting_changed.emit("")
			var cmd = CastSpellCommandScript.new().init(_player, chosen_spell, chosen_cell)
			submit_command(cmd)
			return
		return
	var command = _input_mapper.translate_dungeon_input(event, _build_command_context())
	if command != null:
		submit_command(command)

func _is_adjacent(position_a, position_b):
	return abs(int(position_a.x) - int(position_b.x)) + abs(int(position_a.y) - int(position_b.y)) <= 1

func _find_best_adjacent_cell(target_cell):
	var player_position = _player.get_grid_position()
	var best_cell = null
	var best_len = 999999
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate = target_cell + direction
		if not _entity_grid.is_walkable(candidate.x, candidate.y):
			continue
		var path = _entity_grid.find_path(player_position, candidate)
		if not path.is_empty() and path.size() < best_len:
			best_len = path.size()
			best_cell = candidate
	return best_cell

func _queue_approach_to_cell(destination_cell, select_cell, interaction):
	_pending_interaction = interaction
	if _target_cursor != null:
		_target_cursor.select(select_cell.x, select_cell.y)
	OD.ActionQueue.clear()
	var action = OD.Actions.MoveToLocation.new()
	action.init(_player, destination_cell, _entity_grid)
	action.completed.connect(_on_approach_completed)
	OD.ActionQueue.add(action)
	_turn_scheduler.start_queued_actions(_build_command_context())

func _interact_or_approach(interaction):
	var player_position = _player.get_grid_position()
	if _is_adjacent(player_position, interaction.target_pos):
		_execute_interaction(interaction)
		return true
	var destination_cell = _find_best_adjacent_cell(interaction.target_pos)
	if destination_cell == null:
		return false
	_queue_approach_to_cell(destination_cell, interaction.target_pos, interaction)
	return true

func _move_to_stairs(stairs_cell, direction):
	if not _entity_grid.is_walkable(stairs_cell.x, stairs_cell.y):
		return false
	_queue_approach_to_cell(stairs_cell, stairs_cell, { kind = "stairs", target_pos = stairs_cell, direction = direction })
	return true

func _move_to_pickup(loot_cell):
	if not _entity_grid.is_walkable(loot_cell.x, loot_cell.y):
		return false
	_queue_approach_to_cell(loot_cell, loot_cell, { kind = "pickup", target_pos = loot_cell })
	return true

func _on_approach_completed(reached):
	if not reached or _pending_interaction == null:
		_pending_interaction = null
		return
	var interaction = _pending_interaction
	_pending_interaction = null
	if interaction.kind == "stairs":
		var player_position = _player.get_grid_position()
		if Vector2i(int(player_position.x), int(player_position.y)) == interaction.target_pos:
			_change_floor(interaction.direction)
		return
	if interaction.kind == "pickup":
		var player_position = _player.get_grid_position()
		if Vector2i(int(player_position.x), int(player_position.y)) == interaction.target_pos:
			pickup_loot_at_player(interaction.target_pos)
		return
	if _is_adjacent(_player.get_grid_position(), interaction.target_pos):
		_execute_interaction(interaction)

func _execute_interaction(interaction):
	var position = interaction.target_pos
	match interaction.kind:
		"attack":
			execute_attack_at(position)
		"door":
			var door = _entity_grid.get_door_at(position.x, position.y)
			if door != null and not door.can_pass():
				if door.interact():
					update_fov()
		"element":
			var element = _entity_grid.get_element_at(position.x, position.y)
			if element != null and not element.is_broken:
				_handle_element_interaction(element, position)
		"trap":
			var trap = _entity_grid.get_trap_at(position.x, position.y)
			if trap != null and trap.is_discovered and not trap.is_disarmed:
				_handle_trap_disarm(trap)
		"shopkeeper":
			var keeper = _entity_grid.shop_manager.get_shopkeeper_at(position.x, position.y)
			if keeper != null:
				_handle_shopkeeper_interaction(keeper, position)
		"shop_pedestal":
			var pedestal = _entity_grid.shop_manager.get_pedestal_at(position.x, position.y)
			if pedestal != null:
				_handle_shop_pedestal_interaction(pedestal, position)

func _connect_grid_signals(grid):
	grid.trap_triggered.connect(_on_trap_triggered)
	grid.teleporter_stepped.connect(_on_teleporter_stepped)
	grid.spell_mine_detonated.connect(_on_spell_mine_detonated)
	grid.loot_stepped.connect(_on_loot_stepped)
	grid.shop_manager.shop_alert.connect(_on_shop_alert)
	grid.shop_manager.hostile_attack.connect(_on_hostile_attack)

func _on_spell_mine_detonated(mine_info, trigger_position):
	if mine_info == null or mine_info.get("spell_name", "") == "":
		return
	SpellEngineScript.execute_spell(mine_info.spell_name, mine_info.get("caster", _player), trigger_position, {
		entity_grid = _entity_grid,
		dungeon = self,
		free_cast = true
	})

func _create_floor(floor_level):
	var strategy = _active_strategy
	var grid = load("res://script/instance/room_placement/" + strategy + "_strategy.gd").generate(_branch_name, floor_level)
	grid.name = "EntityGrid-" + strategy + "_strategy-F" + str(floor_level)
	_connect_grid_signals(grid)
	while floors.size() < floor_level:
		floors.append(null)
	floors[floor_level - 1] = grid
	return grid

func _create_floor_async(floor_level):
	var strategy = _active_strategy
	var strategy_script = load("res://script/instance/room_placement/" + strategy + "_strategy.gd")
	var grid = null
	if strategy_script != null and strategy_script.has_method("generate_async"):
		grid = await strategy_script.generate_async(_branch_name, floor_level, 82.0, 95.0)
	else:
		grid = strategy_script.generate(_branch_name, floor_level)
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
		_log_event("The exit is blocked.")
		return
	_pending_interaction = null
	_turn_scheduler.cancel_auto_actions()
	_close_element_dialog()
	if _player.get_parent() != null:
		if _entity_grid != null:
			_entity_grid.unregister_entity(_player)
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
	update_fov()
	OD.Audio.play_sfx("stairs")
	floor_changed.emit(_floor_level, _branch_name)
	save_game()

func get_floor_level():
	return _floor_level

func get_branch_name():
	return _branch_name

func get_current_room_name():
	if _entity_grid == null or _player == null or not is_instance_valid(_player):
		return ""
	var position = _player.get_grid_position()
	if position == null:
		return ""
	return _entity_grid.get_room_name_at(position.x, position.y)

func get_player():
	return _player

func get_entity_grid():
	return _entity_grid

func get_player_global_position():
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree():
		return _player.global_position
	return null

func update_fov():
	if _entity_grid != null and _player != null and is_instance_valid(_player):
		var player_position = _player.get_grid_position()
		if player_position != null:
			_entity_grid.update_fov(player_position, _player.get_sight_radius())
			var room_name = _entity_grid.get_room_name_at(player_position.x, player_position.y)
			if room_name != "":
				var room_key = str(_floor_level) + ":" + room_name
				if not _discovered_rooms.has(room_key):
					_discovered_rooms[room_key] = true
					_log_event("You have discovered " + room_name + "!")
	fov_updated.emit()

func _on_turn_completed(_turn_number, _summary):
	update_fov()

func _build_ui():
	var pending_save = OD.DungeonSettings.get_pending_load_data() if OD.DungeonSettings != null else null
	if pending_save != null:
		OD.DungeonSettings.clear_pending_load_data()
		if restore_from_save(pending_save):
			return
	_setup_player_and_scheduler()
	var settings = OD.DungeonSettings.get_settings()
	_entity_grid = _create_floor(_floor_level)
	_finish_floor_setup(settings)

func _build_ui_async():
	var pending_save = OD.DungeonSettings.get_pending_load_data() if OD.DungeonSettings != null else null
	if pending_save != null:
		OD.DungeonSettings.clear_pending_load_data()
		if restore_from_save(pending_save):
			return
	_setup_player_and_scheduler()
	var settings = OD.DungeonSettings.get_settings()
	_entity_grid = await _create_floor_async(_floor_level)
	_finish_floor_setup(settings)

func save_game(target_path = ""):
	var result = SaveManagerScript.save_run(self, target_path)
	if result.ok:
		_log_event("Game saved.")
	else:
		_log_event("Save failed: " + str(result.get("error", "Unknown error")))
	return result

func restore_from_save(save_data):
	if typeof(save_data) != TYPE_DICTIONARY:
		return false
	_setup_player_and_scheduler()
	_branch_name = str(save_data.get("branch_name", "The Dungeon"))
	_floor_level = max(1, int(save_data.get("floor", 1)))
	_monsters_killed = int(save_data.get("monsters_killed", 0))
	_lutefisk_ref.value = int(save_data.get("lutefisk", 10))
	_discovered_rooms = save_data.get("discovered_rooms", {}).duplicate(true)
	_in_pocket_dimension = bool(save_data.get("in_pocket_dimension", false))
	_saved_main_return_cell = GridSerializerScript._arr_to_vec2i(save_data.get("saved_main_return_cell", null))
	_active_strategy = str(save_data.get("active_strategy", FLOOR_STRATEGY.RETAIL))
	if _turn_scheduler != null:
		_turn_scheduler.turn_count = int(save_data.get("turn_count", 0))

	floors.clear()
	var floors_dict = save_data.get("floors", {})
	if typeof(floors_dict) == TYPE_DICTIONARY:
		var max_floor = _floor_level
		for key in floors_dict.keys():
			max_floor = max(max_floor, int(key))
		for _index in range(max_floor):
			floors.append(null)
		for key in floors_dict.keys():
			var f_index = int(key) - 1
			if f_index >= 0:
				var restored_grid = GridSerializerScript.deserialize_grid(floors_dict[key])
				if restored_grid != null:
					restored_grid.name = "EntityGrid-" + _active_strategy + "-F" + str(key)
					_connect_grid_signals(restored_grid)
					floors[f_index] = restored_grid

	_pocket_dimensions.clear()
	var pocket_dict = save_data.get("pocket_dimensions", {})
	if typeof(pocket_dict) == TYPE_DICTIONARY:
		for key in pocket_dict.keys():
			var restored_pocket = GridSerializerScript.deserialize_grid(pocket_dict[key])
			if restored_pocket != null:
				restored_pocket.name = "EntityGrid-Pocket-" + str(key)
				_connect_grid_signals(restored_pocket)
				_pocket_dimensions[key] = restored_pocket

	if _in_pocket_dimension and not _pocket_dimensions.is_empty():
		var first_key = _pocket_dimensions.keys()[0]
		_entity_grid = _pocket_dimensions[first_key]
	elif _floor_level - 1 < floors.size():
		_entity_grid = floors[_floor_level - 1]
	if _entity_grid == null:
		_entity_grid = _create_floor(_floor_level)

	var player_data = save_data.get("player", {})
	SaveManagerScript.deserialize_player(_player, player_data)
	_zorkmids_ref = _player.get_zorkmids_ref()

	var position_array = player_data.get("grid_pos", [4, 6])
	var spawn_x = int(position_array[0]) if typeof(position_array) == TYPE_ARRAY and position_array.size() >= 2 else 4
	var spawn_y = int(position_array[1]) if typeof(position_array) == TYPE_ARRAY and position_array.size() >= 2 else 6
	if _entity_grid._grid_center != null:
		OD.Math.set_grid_center(_entity_grid._grid_center.x, _entity_grid._grid_center.y)
	_entity_grid.add_entity(spawn_x, spawn_y, _player)
	add_child(_entity_grid)
	_entity_grid.add_entity(spawn_x, spawn_y, _target_cursor)
	_entity_grid.update_trap_visibility(_player.get_grid_position())
	update_fov()
	floor_changed.emit(_floor_level, _branch_name)
	return true

func _setup_player_and_scheduler():
	_turn_scheduler.init(_command_processor, OD.DungeonSettings.get_settings().get("base_turn_seconds", 0.24))
	if not _turn_scheduler.turn_completed.is_connected(_on_turn_completed):
		_turn_scheduler.turn_completed.connect(_on_turn_completed)
	if _turn_scheduler.get_parent() == null:
		add_child(_turn_scheduler)
	_player = PlayerCharacter.new()
	_player.init()
	_player.died.connect(_on_player_died)
	_zorkmids_ref = _player.get_zorkmids_ref()
	_target_cursor = TargetCursor.new()
	_target_cursor.init()

func _finish_floor_setup(settings):
	var spawn_x = _entity_grid.player_spawn_cell.x if _entity_grid.player_spawn_cell != null else settings.player_start_x
	var spawn_y = _entity_grid.player_spawn_cell.y if _entity_grid.player_spawn_cell != null else settings.player_start_y
	_entity_grid.add_entity(spawn_x, spawn_y, _player)
	add_child(_entity_grid)
	_entity_grid.add_entity(spawn_x, spawn_y, _target_cursor)
	_entity_grid.update_trap_visibility(_player.get_grid_position())
	update_fov()
	_seed_player_bag()
	floor_changed.emit(_floor_level, _branch_name)

func _on_trap_triggered(trap_result, grid_position):
	_turn_scheduler.cancel_auto_actions()
	_spawn_spell_vfx(trap_result.casts_spell, grid_position)
	_spawn_floating_text(grid_position, trap_result.trap_name + "!", Color(1.0, 0.35, 0.25))
	_log_event("You trigger a " + str(trap_result.trap_name) + "!")

func _on_teleporter_stepped(teleporter_info, _grid_position):
	if teleporter_info == null or not teleporter_info.has("target_cell"):
		return
	var destination = teleporter_info.target_cell
	_pending_interaction = null
	_turn_scheduler.cancel_auto_actions()
	var previous_position = _player.get_grid_position()
	_player.move_to(destination.x, destination.y)
	_player.idle()
	_entity_grid.move_entity(_player, previous_position, destination)
	_target_cursor.select(destination.x, destination.y)
	_entity_grid.update_trap_visibility(destination)
	update_fov()
	OD.Audio.play_sfx("teleport")
	_log_event("Teleported!")

func _toggle_pocket_dimension(_portal_position):
	_pending_interaction = null
	_turn_scheduler.cancel_auto_actions()
	_close_element_dialog()
	if _player.get_parent() != null:
		if _entity_grid != null:
			_entity_grid.unregister_entity(_player)
		_player.get_parent().remove_child(_player)
	if _target_cursor.get_parent() != null:
		_target_cursor.get_parent().remove_child(_target_cursor)
	if _entity_grid != null and _entity_grid.get_parent() == self:
		remove_child(_entity_grid)
	var target_grid = null
	var spawn_cell = null
	var label_text = ""
	var branch_label = _branch_name
	if _in_pocket_dimension:
		_in_pocket_dimension = false
		target_grid = floors[_floor_level - 1]
		spawn_cell = _saved_main_return_cell if _saved_main_return_cell != null else _resolve_floor_spawn_cell(target_grid, "down")
		label_text = "Returned to Floor " + str(_floor_level)
	else:
		var player_position = _player.get_grid_position()
		_saved_main_return_cell = Vector2i(int(player_position.x), int(player_position.y))
		var pocket_key = "floor_" + str(_floor_level)
		if not _pocket_dimensions.has(pocket_key):
			var pocket_grid = PocketDimensionScript.generate(_floor_level)
			if pocket_grid == null:
				add_child(_entity_grid)
				_entity_grid.add_entity(player_position.x, player_position.y, _player)
				_entity_grid.add_entity(player_position.x, player_position.y, _target_cursor)
				return
			pocket_grid.name = "PocketDimension-F" + str(_floor_level)
			_connect_grid_signals(pocket_grid)
			_pocket_dimensions[pocket_key] = pocket_grid
		_in_pocket_dimension = true
		target_grid = _pocket_dimensions[pocket_key]
		spawn_cell = target_grid.player_spawn_cell
		label_text = "The Pocket Dimension"
		branch_label = "The Pocket Dimension"
	_entity_grid = target_grid
	add_child(_entity_grid)
	if _entity_grid._grid_center != null:
		OD.Math.set_grid_center(_entity_grid._grid_center.x, _entity_grid._grid_center.y)
	_entity_grid.add_entity(spawn_cell.x, spawn_cell.y, _player)
	_player.idle()
	_entity_grid.add_entity(spawn_cell.x, spawn_cell.y, _target_cursor)
	_entity_grid.update_trap_visibility(_player.get_grid_position())
	update_fov()
	OD.Audio.play_sfx("portal")
	_spawn_floating_text(spawn_cell, label_text, Color(0.75, 0.55, 1.0))
	floor_changed.emit(_floor_level, branch_label)

func award_xp(amount, grid_position = null):
	if _player == null or int(amount) <= 0:
		return false
	var leveled_up = _player.add_xp(int(amount))
	if leveled_up:
		_player.play_levelup_animation()
		if OD.Audio != null:
			OD.Audio.play_sfx("levelup")
		_log_event("You have gained a level! You are now Level " + str(_player.level) + ".")
		if grid_position != null:
			_spawn_floating_text(grid_position, "Level Up! Lv " + str(_player.level), Color(1.0, 0.9, 0.25))
	return leveled_up

func _handle_trap_disarm(trap):
	var trap_affinity = max(1, _player.get_secondary_stat("trap_affinity")) if _player != null else 1
	var disarm_result = trap.attempt_disarm(trap_affinity)
	var position = trap.get_grid_position()
	if disarm_result.success:
		var trap_xp = max(1, int(trap.trap_level)) * int(OD.Database.get_tweak("trap XP scale", 10))
		_spawn_floating_text(position, "Disarmed! +" + str(trap_xp) + " XP", Color(0.45, 0.95, 0.45))
		_log_event("You disarm the trap! (+" + str(trap_xp) + " XP)")
		award_xp(trap_xp, position)
	else:
		if disarm_result.has("triggered") and disarm_result.triggered != null:
			_spawn_spell_vfx(disarm_result.triggered.casts_spell, position)
		_spawn_floating_text(position, "Trap Triggered!", Color(1.0, 0.35, 0.25))
		_log_event("You fail to disarm the trap and trigger it!")

func _resolve_spell_sfx(spell):
	if spell == null:
		return "magic"
	var animation_definition = spell.get("anim", null)
	if typeof(animation_definition) == TYPE_DICTIONARY and str(animation_definition.get("sfx", "")) != "":
		return str(animation_definition.sfx)
	var raw_definition = spell.get("raw", null)
	if typeof(raw_definition) == TYPE_DICTIONARY:
		var impact_definition = raw_definition.get("impact", null)
		if typeof(impact_definition) == TYPE_DICTIONARY and str(impact_definition.get("sfx", "")) != "":
			return str(impact_definition.sfx)
	for effect in spell.get("effects", []):
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("sfx", "")) != "":
			return str(effect.sfx)
	return "magic"

func _spawn_spell_vfx(spell_name, grid_position, play_sound = true):
	if spell_name == "" or _entity_grid == null:
		return
	var spell = OD.Database.get_spell(spell_name)
	if spell == null:
		return
	if play_sound and OD.Audio != null:
		OD.Audio.play_sfx(_resolve_spell_sfx(spell))
	if spell.anim == null or typeof(spell.anim) != TYPE_DICTIONARY:
		return
	var animation_definition = spell.anim
	if animation_definition.has("sprite") and animation_definition.has("frames"):
		var first_index = int(animation_definition.get("first", 0))
		var frame_count = int(animation_definition.frames)
		var frame_rate = int(animation_definition.get("framerate", 80))
		var vfx = OD.Load.png_sprite(animation_definition.sprite, first_index, first_index + frame_count, frame_rate)
		if vfx != null:
			var px = OD.Math.grid_to_pixel(grid_position.x, grid_position.y)
			_entity_grid.add_animation(px.x, px.y, "floating_text", vfx)
			vfx.animation_complete.connect(func():
				if is_instance_valid(vfx):
					vfx.queue_free()
			)

func _log_event(message):
	if OD.EventLog != null:
		OD.EventLog.notify(message)

func _spawn_floating_text(grid_position, text, color, scale_multiplier = 1.0):
	if _entity_grid == null:
		return
	FloatingCombatTextScript.spawn_text(self, _entity_grid.get_layer("floating_text"), grid_position, text, color, scale_multiplier)

func spawn_floating_badge(grid_position, badge_key, fallback_text = ""):
	if _entity_grid == null:
		return
	var layer_node = _entity_grid.get_layer("floating_text")
	if not FloatingCombatTextScript.spawn_badge(self, layer_node, grid_position, badge_key) and fallback_text != "":
		FloatingCombatTextScript.spawn_text(self, layer_node, grid_position, fallback_text, Color(0.95, 0.9, 0.6))

func is_dialog_open():
	return is_instance_valid(_interaction_dialog) or is_instance_valid(_crafting_dialog)

func has_interaction_dialog_open():
	return is_instance_valid(_interaction_dialog)

func close_crafting_dialog():
	if is_instance_valid(_crafting_dialog):
		_crafting_dialog.dismiss()
		_crafting_dialog = null

func open_crafting_dialog(tool_tag = ""):
	if _player == null:
		return false
	if is_instance_valid(_crafting_dialog):
		_crafting_dialog.dismiss()
		_crafting_dialog = null
		return false
	var possessed = _player.get_possessed_toolkits()
	if possessed.is_empty():
		_log_event("No crafting tools in inventory!")
		return false
	_crafting_dialog = CraftingDialogScript.new().init(_player, tool_tag, {
		on_drop_overflow = func(drop_item):
			var p_position = _player.get_grid_position()
			if p_position != null and _entity_grid != null:
				_entity_grid.add_loot_item(int(p_position.x), int(p_position.y), { kind = "item", item = drop_item }),
		on_close = func():
			_crafting_dialog = null
	})
	add_child(_crafting_dialog)
	return true

func _close_element_dialog():
	if is_instance_valid(_interaction_dialog):
		_interaction_dialog.queue_free()
		_interaction_dialog = null

func _handle_element_interaction(element, grid_coordinates):
	if element.element_type == "wizardportal" or element.element_type == "portal":
		_toggle_pocket_dimension(grid_coordinates)
		return
	if element.element_type == "custom_breakable":
		if _player != null:
			_player.face_towards(grid_coordinates)
			_player.play_attack_animation("melee")
		var break_result = element.interact()
		_entity_grid.unblock_cell(grid_coordinates.x, grid_coordinates.y)
		var smash_message = break_result.get("message", "Smashed!")
		_log_event(smash_message)
		if int(break_result.get("exp", 0)) > 0:
			award_xp(int(break_result.exp), grid_coordinates)
		return
	element.state_data["floor_level"] = _floor_level
	if element.element_type == "queststatue" and not element.used and _player != null and _player.has_method("add_quest"):
		var target_kills = 3 + _floor_level
		var quest_id = "inconsequentia_f" + str(_floor_level) + "_" + str(grid_coordinates.x) + "_" + str(grid_coordinates.y)
		var added_quest = _player.add_quest({
			id = quest_id,
			title = "Inconsequentia's Trial (Floor " + str(_floor_level) + ")",
			giver = "Statue of Inconsequentia",
			description = "Slay " + str(target_kills) + " monsters on Dungeon Level " + str(_floor_level) + " to prove your valor.",
			kind = "kill",
			floor_level = _floor_level,
			progress = 0,
			target = target_kills,
			reward_xp = 75 * _floor_level,
			reward_zorkmids = 50 * _floor_level
		})
		if added_quest:
			_log_event("New Quest: Inconsequentia's Trial (Floor " + str(_floor_level) + ")")
	_close_element_dialog()
	_interaction_dialog = ElementDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_element_dialog(
		element,
		_zorkmids_ref,
		_lutefisk_ref,
		func(): _interaction_dialog = null,
		func(): _entity_grid.unblock_cell(grid_coordinates.x, grid_coordinates.y),
		func(granted_item): _grant_loot_to_player(granted_item, grid_coordinates),
		func(discovered_recipe):
			if _player != null:
				_player.learn_recipe(discovered_recipe)
	)

func _grant_loot_to_player(item_inst, fallback_position):
	if item_inst == null or _player == null:
		return
	var add_result = _player.add_item(item_inst)
	if add_result.added:
		var item_label = str(item_inst.get("name", "Item"))
		_log_event("You put " + item_label + " in your bag.")
		return
	if _entity_grid != null:
		var drop_position = _player.get_grid_position()
		var target_cell = Vector2i(int(drop_position.x), int(drop_position.y)) if drop_position != null else fallback_position
		_entity_grid.add_loot_item(target_cell.x, target_cell.y, { kind = "item", item = item_inst })
		_log_event("Your bag is full!")

func _seed_player_bag():
	if _player == null:
		return
	var existing_items = _player.get_inventory_items()
	if not existing_items.is_empty():
		return
	var starter_names = ["Crude Iron Sword", "Lutefisk", "Potion of Healing"]
	for item_name in starter_names:
		var inst = OD.Database.create_item_instance(item_name)
		if inst != null:
			_player.add_item(inst)

func _on_loot_stepped(grid_position):
	pickup_loot_at_player(grid_position)

func _get_item_sfx(item_data, is_drop = false):
	var cat = str(item_data.get("category", "")) if typeof(item_data) == TYPE_DICTIONARY else ""
	var suffix = "_drop" if is_drop else "_get"
	match cat:
		"food", "mushroom":
			return "food" + suffix
		"potion":
			return "potion" + suffix
		"armour":
			var armor_name = str(item_data.get("name", "")).to_lower()
			if "robe" in armor_name or "cloth" in armor_name or "hat" in armor_name:
				return "cloth" + suffix
			if "leather" in armor_name or "boot" in armor_name or "glove" in armor_name:
				return "leather" + suffix
			return "metal" + suffix
		_:
			return "metal" + suffix

func pickup_loot_at_player(target_position = null):
	if _player == null or _entity_grid == null:
		return false
	var position = target_position
	if position == null:
		var p_position = _player.get_grid_position()
		if p_position == null:
			return false
		position = Vector2i(int(p_position.x), int(p_position.y))
	var loot_list = _entity_grid.get_loot_list_at(position.x, position.y)
	if loot_list.is_empty():
		return false
	var picked_any = false
	var index = loot_list.size() - 1
	while index >= 0:
		var entry = loot_list[index]
		var loot_data = entry.get("data", {})
		var kind = str(loot_data.get("kind", "item"))
		if kind == "zorkmids":
			var amt = max(1, int(loot_data.get("amount", 1)))
			_player.add_zorkmids(amt)
			_entity_grid.remove_loot_at(position.x, position.y, index)
			if OD.Audio != null:
				OD.Audio.play_sfx("money_get")
			_log_event("You pick up " + str(amt) + " Zorkmids.")
			picked_any = true
		elif kind == "lockpick":
			var lockpick_item = OD.Database.create_item_instance("Lockpick")
			if lockpick_item == null:
				lockpick_item = {
					name = "Lockpick",
					category = "misc",
					slot = "",
					level = 1,
					icon = OD.Resources.paths.loot.lockpick,
					price = 25,
					sell_price = 15,
					description = "Used to pick locked doors and chests.",
					count = 1,
					max_stack = 99
				}
			var lp_result = _player.add_item(lockpick_item)
			if lp_result.added:
				_entity_grid.remove_loot_at(position.x, position.y, index)
				if OD.Audio != null:
					OD.Audio.play_sfx("metal_get")
				_log_event("You put Lockpick in your bag.")
				picked_any = true
			else:
				if OD.Audio != null:
					OD.Audio.play_sfx("fullinventory")
				_log_event("Your bag is full!")
		else:
			var raw_item = loot_data.get("item", loot_data)
			var item_inst = raw_item
			if typeof(raw_item) == TYPE_DICTIONARY and not raw_item.has("max_stack") and raw_item.has("name"):
				var created = OD.Database.create_item_instance(str(raw_item.name), int(raw_item.get("count", 1)))
				if created != null:
					item_inst = created
			var add_result = _player.add_item(item_inst)
			if add_result.added:
				if add_result.remaining > 0:
					item_inst["count"] = add_result.remaining
					_log_event("Your bag is full!")
				else:
					_entity_grid.remove_loot_at(position.x, position.y, index)
				if OD.Audio != null:
					OD.Audio.play_sfx(_get_item_sfx(item_inst, false))
				var picked_name = str(item_inst.get("name", "Item"))
				_log_event("You put " + picked_name + " in your bag.")
				picked_any = true
			else:
				if OD.Audio != null:
					OD.Audio.play_sfx("fullinventory")
				_log_event("Your bag is full!")
		index -= 1
	return picked_any

func drop_inventory_item(inventory_index, count = -1):
	if _player == null or _entity_grid == null:
		return false
	var p_position = _player.get_grid_position()
	if p_position == null:
		return false
	var removed = _player.remove_item_at(inventory_index, count)
	if removed == null:
		return false
	_entity_grid.add_loot_item(int(p_position.x), int(p_position.y), { kind = "item", item = removed })
	if OD.Audio != null:
		OD.Audio.play_sfx(_get_item_sfx(removed, true))
	_log_event("Dropped " + str(removed.get("name", "Item")) + ".")
	return true

func drop_equipped_item(slot_name):
	if _player == null or _entity_grid == null:
		return false
	var p_position = _player.get_grid_position()
	if p_position == null:
		return false
	var equipped = _player.get_equipped_item(slot_name)
	if equipped == null:
		return false
	_player.equipment[slot_name] = null
	_player.recalculate_stats()
	_player.equipment_changed.emit()
	_entity_grid.add_loot_item(int(p_position.x), int(p_position.y), { kind = "item", item = equipped })
	if OD.Audio != null:
		OD.Audio.play_sfx(_get_item_sfx(equipped, true))
	_log_event("Dropped " + str(equipped.get("name", "Item")) + ".")
	return true

func _on_shop_alert(message, grid_position, color):
	_spawn_floating_text(grid_position, message, color)
	_log_event(message)

func _trigger_player_hit_procs(attacker_cell):
	if _player == null or not _player.has_method("on_hit_received"):
		return
	for proc_spell in _player.on_hit_received():
		SpellEngineScript.execute_spell(proc_spell, _player, attacker_cell, {
			entity_grid = _entity_grid,
			dungeon = self,
			free_cast = true
		})

func _on_player_died(cause_of_death):
	_turn_scheduler.cancel_auto_actions()
	cancel_spell_targeting()
	_close_element_dialog()
	OD.ActionQueue.clear()
	if OD.Audio != null:
		OD.Audio.play_sfx("humanoid_die")
		var has_death_open = OD.Load != null and OD.Load.exists("tunes/death-open.ogg")
		var has_death_repeat = OD.Load != null and OD.Load.exists("tunes/death-repeat.ogg")
		if has_death_open and has_death_repeat:
			var death_open = OD.Load.sfx("tunes/death-open.ogg")
			var death_repeat = OD.Load.audio("tunes/death-repeat.ogg")
			if death_open != null and death_repeat != null:
				OD.Audio.play(death_open, death_repeat)
			elif death_repeat != null:
				OD.Audio.play(death_repeat)
		elif has_death_repeat:
			var death_repeat = OD.Load.audio("tunes/death-repeat.ogg")
			if death_repeat != null:
				OD.Audio.play(death_repeat)
		elif has_death_open:
			var death_music = OD.Load.audio("tunes/death-open.ogg")
			if death_music != null:
				OD.Audio.play(death_music)
	if _player != null and is_instance_valid(_player):
		_player.play_die_animation()
		_player.modulate = Color(0.55, 0.2, 0.2, 0.65)
		var p_position = _player.get_grid_position()
		if p_position != null:
			_spawn_floating_text(Vector2i(int(p_position.x), int(p_position.y)), "You have died!", Color(1.0, 0.2, 0.2))
	var settings = OD.DungeonSettings.get_settings() if OD.DungeonSettings != null and OD.DungeonSettings.get_settings() != null else {}
	var permadeath = bool(settings.get("permadeath", false))
	var save_path = OD.DungeonSettings.get_save_file_path() if OD.DungeonSettings != null else ""
	var deleted_save = DeathManagerScript.delete_permadeath_save(save_path, permadeath)
	var score_entry = DeathManagerScript.record_high_score(_player, _floor_level, cause_of_death, _monsters_killed)
	var summary = {
		score_entry = score_entry,
		permadeath_deleted = deleted_save
	}
	player_died.emit(summary)

func on_monster_attack_player(monster, result, monster_position, player_position):
	var m_name = str(monster.get("monster_name")) if monster != null else "Monster"
	if _player != null and is_instance_valid(_player) and not _player.is_dead:
		_player.play_hit_animation()
	if player_position != null:
		var p_cell = Vector2i(int(player_position.x), int(player_position.y))
		if result.get("critical", false):
			spawn_floating_badge(p_cell, "crit", "CRIT!")
		if result.get("blocked", false):
			spawn_floating_badge(p_cell, "block", "Blocked!")
		_spawn_floating_text(p_cell, "-" + str(result.total_damage), Color(1.0, 0.28, 0.28), 1.15 if result.get("critical", false) else 1.0)
	_log_event("The " + m_name + " hits you for " + str(result.total_damage) + " damage!")
	_trigger_player_hit_procs(monster_position)

func _on_hostile_attack(attacker_name, damage, grid_position):
	_turn_scheduler.cancel_auto_actions()
	_log_event(str(attacker_name) + " hits you for " + str(damage) + " damage!")
	_trigger_player_hit_procs(grid_position)

func _handle_shopkeeper_interaction(keeper, position):
	if keeper.is_hostile:
		_resolve_player_attack(keeper, position, { kind = "melee" })
		return
	var shop = _entity_grid.shop_manager.get_shop_by_id(keeper.shop_id)
	if shop == null:
		return
	var player_position = _player.get_grid_position()
	var player_cell = Vector2i(int(player_position.x), int(player_position.y))
	_close_element_dialog()
	_interaction_dialog = ShopDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_brax_dialog(
		shop,
		_zorkmids_ref,
		_player,
		func(): _interaction_dialog = null,
		func(): _entity_grid.shop_manager.make_shop_hostile(shop, _entity_grid, player_cell),
		func(): _entity_grid.shop_manager.teleport_brax_home(shop, player_cell, _entity_grid)
	)

func _handle_shop_pedestal_interaction(pedestal, _position):
	if not pedestal.has_item():
		_log_event("Empty pedestal.")
		return
	var shop = _entity_grid.shop_manager.get_shop_by_id(pedestal.shop_id)
	var player_position = _player.get_grid_position()
	var player_cell = Vector2i(int(player_position.x), int(player_position.y))
	_close_element_dialog()
	_interaction_dialog = ShopDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_pedestal_dialog(
		pedestal,
		shop,
		_zorkmids_ref,
		_player,
		func(): _interaction_dialog = null,
		func(): _entity_grid.shop_manager.make_shop_hostile(shop, _entity_grid, player_cell),
		func(): _entity_grid.shop_manager.teleport_brax_to_shop(shop, player_cell, _entity_grid)
	)
		
