extends RefCounted

const CombatResolverScript = preload("res://script/instance/combat/combat_resolver.gd")

static func get_target_actor_at(cell, entity_grid, caster, affects_caster = false, self_only = false):
	if self_only:
		return caster
	if entity_grid == null:
		return caster if affects_caster else null
	var enemy = entity_grid.get_enemy_at(cell.x, cell.y)
	if enemy != null:
		return enemy
	var actor = entity_grid.get_actor_at(cell.x, cell.y)
	if actor != null:
		if actor == caster and not affects_caster:
			return null
		return actor
	if affects_caster and caster != null and caster.has_method("get_grid_position"):
		var caster_pos = caster.get_grid_position()
		if caster_pos != null and Vector2i(int(caster_pos.x), int(caster_pos.y)) == cell:
			return caster
	return null

static func _get_magic_power(caster):
	if caster != null and caster.has_method("get_secondary_stat"):
		return int(caster.get_secondary_stat("magic_power"))
	return 0

static func handle_damage(effect, spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var self_only = int(effect.get("self", 0)) == 1
	var affects_caster = int(effect.get("affectsCaster", effect.get("affectscaster", 0))) == 1
	var target = get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
	if target == null:
		return ""
	var magic_power = _get_magic_power(caster)
	var damage_map = {}
	var primary_type = "aethereal"
	var max_type_value = -1
	for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
		var base_value = int(effect.get(damage_type, 0))
		var scale_factor = float(effect.get(damage_type + "F", 0.0))
		var total_value = base_value + int(round(scale_factor * float(magic_power)))
		if total_value > 0:
			damage_map[damage_type] = total_value
			if total_value > max_type_value:
				max_type_value = total_value
				primary_type = damage_type
	if effect.has("percent") and target.get("max_hp") != null:
		var percent_damage = int(round(float(target.max_hp) * float(effect.percent) / 100.0))
		if percent_damage > 0:
			damage_map[primary_type] = int(damage_map.get(primary_type, 0)) + percent_damage
	var result = CombatResolverScript.resolve_attack(caster, target, {
		kind = "spell",
		damage_map = damage_map,
		primary_damage_type = primary_type,
		magic_scale = float(effect.get("secondaryScale", 0.0)),
		force_hit = true
	})
	if result.total_damage > 0 and target.get("hp") != null:
		if target.has_method("modify_hp"):
			target.modify_hp(-result.total_damage, spell_definition.name)
		else:
			target.hp = max(0, int(target.hp) - result.total_damage)
		if target.has_method("refresh_health_bar"):
			target.refresh_health_bar()
		if target.has_method("play_hit_animation"):
			target.play_hit_animation()
		if dungeon != null and dungeon.has_method("_spawn_floating_text"):
			dungeon._spawn_floating_text(cell, "-" + str(result.total_damage), Color(0.55, 0.85, 1.0))
		if target != caster and int(target.hp) <= 0 and dungeon != null and dungeon.has_method("_handle_enemy_death"):
			dungeon._handle_enemy_death(target, cell)
	elif result.total_damage <= 0 and dungeon != null and dungeon.has_method("spawn_floating_badge"):
		dungeon.spawn_floating_badge(cell, "resist", "Resisted!")
	return "damage"

static func handle_heal(effect, spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var self_only = int(effect.get("self", 0)) == 1
	var target = get_target_actor_at(cell, entity_grid, caster, true, self_only or str(spell_definition.get("type", "")).to_lower() == "self")
	if target == null:
		return ""
	var magic_power = _get_magic_power(caster)
	var heal_amount = int(effect.get("amount", 0)) + int(round(float(effect.get("amountF", 0.0)) * float(magic_power)))
	if heal_amount > 0:
		if target.has_method("modify_hp"):
			target.modify_hp(heal_amount)
		elif target.get("hp") != null and target.get("max_hp") != null:
			target.hp = min(int(target.max_hp), int(target.hp) + heal_amount)
		if dungeon != null and dungeon.has_method("_spawn_floating_text"):
			dungeon._spawn_floating_text(cell, "+" + str(heal_amount) + " HP", Color(0.4, 0.95, 0.45))
	return "heal"

static func handle_spellpoints(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var target = get_target_actor_at(cell, entity_grid, caster, true, true)
	if target == null:
		return ""
	var magic_power = _get_magic_power(caster)
	var mp_amount = int(effect.get("amount", 0)) + int(round(float(effect.get("amountF", 0.0)) * float(magic_power)))
	if effect.has("percent") and target.get("max_mp") != null:
		mp_amount += int(round(float(target.max_mp) * float(effect.percent) / 100.0))
	if mp_amount != 0 and target.has_method("modify_mp"):
		target.modify_mp(mp_amount)
		if mp_amount > 0 and dungeon != null and dungeon.has_method("_spawn_floating_text"):
			dungeon._spawn_floating_text(cell, "+" + str(mp_amount) + " MP", Color(0.45, 0.78, 1.0))
	return "spellpoints"

static func handle_drain(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var target = get_target_actor_at(cell, entity_grid, caster, false, false)
	if target == null:
		return ""
	var magic_power = _get_magic_power(caster)
	var damage_map = {}
	for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
		var base_value = int(effect.get(damage_type, 0))
		var scale_factor = float(effect.get(damage_type + "F", 0.0))
		var total_value = base_value + int(round(scale_factor * float(magic_power)))
		if total_value > 0:
			damage_map[damage_type] = total_value
	var result = CombatResolverScript.resolve_attack(caster, target, {
		kind = "spell",
		damage_map = damage_map,
		primary_damage_type = "necromantic",
		force_hit = true
	})
	if result.total_damage > 0:
		if target.has_method("modify_hp"):
			target.modify_hp(-result.total_damage)
		elif target.get("hp") != null:
			target.hp = max(0, int(target.hp) - result.total_damage)
		if caster != null and caster.has_method("modify_hp"):
			caster.modify_hp(max(1, result.total_damage / 2))
		if target != caster and int(target.hp) <= 0 and dungeon != null and dungeon.has_method("_handle_enemy_death"):
			dungeon._handle_enemy_death(target, cell)
	return "drain"

static func handle_drain_mana(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var effect_type = str(effect.get("type", "")).to_lower()
	var entity_grid = context.get("entity_grid", null)
	var self_only = int(effect.get("self", 0)) == 1
	var affects_caster = int(effect.get("affectsCaster", effect.get("affectscaster", 0))) == 1
	var target = caster if effect_type == "draincastermana" else get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
	if target != null and target.has_method("modify_mp"):
		target.modify_mp(-int(effect.get("amount", 0)))
	return effect_type

static func handle_dot(effect, _spell_definition, caster, _caster_position, cell, context, trigger_depth, execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var self_only = int(effect.get("self", 0)) == 1
	var affects_caster = int(effect.get("affectsCaster", effect.get("affectscaster", 0))) == 1
	var target = get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
	var dot_spell = str(effect.get("spell", ""))
	var turns = max(1, int(effect.get("amount", 1)))
	if target != null and dot_spell != "" and target.has_method("apply_dot"):
		var bound_context = context.duplicate()
		bound_context["free_cast"] = true
		target.apply_dot({
			spell = dot_spell,
			remaining_turns = turns,
			caster = caster,
			on_tick = func(ticked_actor, _dot_entry):
				var position_now = ticked_actor.get_grid_position() if ticked_actor != null and is_instance_valid(ticked_actor) and ticked_actor.has_method("get_grid_position") else cell
				var cell_now = Vector2i(int(position_now.x), int(position_now.y)) if position_now != null else cell
				execute_fn.call(dot_spell, caster, cell_now, bound_context, trigger_depth + 1)
		})
	return "dot"

static func handle_trigger(effect, _spell_definition, caster, _caster_position, cell, context, trigger_depth, execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var chance = int(effect.get("percent", effect.get("percentage", 100)))
	if chance < 100 and (randi() % 100) >= chance:
		return ""
	var req_buff = str(effect.get("requirebuffontriggername", ""))
	if int(effect.get("requirebuffontrigger", 0)) == 1 and req_buff != "":
		var check_actor = get_target_actor_at(cell, entity_grid, caster, true, false)
		if check_actor == null or not check_actor.has_method("has_buff") or not check_actor.has_buff(req_buff):
			return ""
	var not_buff = str(effect.get("requirebuffonnottriggername", ""))
	if int(effect.get("requirebuffonnottrigger", 0)) == 1 and not_buff != "":
		var check_actor_not = get_target_actor_at(cell, entity_grid, caster, true, false)
		if check_actor_not != null and check_actor_not.has_method("has_buff") and check_actor_not.has_buff(not_buff):
			return ""
	var child_spell = str(effect.get("spell", ""))
	if child_spell != "":
		var trigger_context = context.duplicate()
		trigger_context["free_cast"] = true
		execute_fn.call(child_spell, caster, cell, trigger_context, trigger_depth + 1)
	return "trigger"

static func handle_trigger_from_list(effect, _spell_definition, caster, _caster_position, cell, context, trigger_depth, execute_fn):
	var sub_spells = OD.DataStructure.arrayify(effect.get("spell", [])) if OD.DataStructure != null else []
	if not sub_spells.is_empty():
		var picked = sub_spells[randi() % sub_spells.size()]
		var picked_name = str(picked.get("name", picked)) if typeof(picked) == TYPE_DICTIONARY else str(picked)
		if picked_name != "":
			var trigger_context = context.duplicate()
			trigger_context["free_cast"] = true
			execute_fn.call(picked_name, caster, cell, trigger_context, trigger_depth + 1)
	return "triggerfromlist"

static func handle_knock_or_suction(effect, _spell_definition, caster, caster_position, cell, context, _trigger_depth, _execute_fn):
	var effect_type = str(effect.get("type", "")).to_lower()
	var entity_grid = context.get("entity_grid", null)
	var self_only = int(effect.get("self", 0)) == 1
	var affects_caster = int(effect.get("affectsCaster", effect.get("affectscaster", 0))) == 1
	var target = get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
	if target == null or entity_grid == null:
		return ""
	var steps = max(1, int(effect.get("amount", 1)))
	var delta = caster_position - cell if effect_type == "suction" else cell - caster_position
	var step_direction = Vector2i(signi(delta.x), signi(delta.y))
	if step_direction == Vector2i.ZERO:
		return ""
	var current = cell
	for _step in range(steps):
		var next_cell = current + step_direction
		if entity_grid.is_walkable(next_cell.x, next_cell.y):
			entity_grid.move_actor_to(target, next_cell.x, next_cell.y)
			current = next_cell
		else:
			break
	return effect_type

static func handle_dig(_effect, _spell_definition, _caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	if entity_grid != null and entity_grid.is_wall(cell.x, cell.y):
		entity_grid.dig_wall(cell.x, cell.y)
		if dungeon != null and dungeon.has_method("update_fov"):
			dungeon.update_fov()
	return "dig"

static func handle_teleport(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var effect_type = str(effect.get("type", "")).to_lower()
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	if entity_grid == null or caster == null:
		return ""
	var destination = entity_grid.get_random_walkable_cell() if effect_type == "teleport" else cell
	if destination != null and entity_grid.is_walkable(destination.x, destination.y):
		entity_grid.move_actor_to(caster, destination.x, destination.y)
		if dungeon != null and dungeon.has_method("update_fov"):
			dungeon.update_fov()
	return effect_type

static func handle_summon(effect, _spell_definition, _caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var effect_type = str(effect.get("type", "")).to_lower()
	var entity_grid = context.get("entity_grid", null)
	if entity_grid == null:
		return ""
	var monster_type = str(effect.get("monsterType", "Diggle"))
	var hostile = effect_type == "summonhostile"
	entity_grid.spawn_monster_at(monster_type, cell.x, cell.y, -1, hostile)
	return effect_type

static func handle_transform_monster(_effect, _spell_definition, _caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	if entity_grid == null or OD.Database == null:
		return ""
	var target = entity_grid.get_enemy_at(cell.x, cell.y)
	if target == null:
		return ""
	var new_name = "Diggle"
	if OD.Database.has_method("get_random_monster"):
		for _try in range(10):
			var picked = OD.Database.get_random_monster()
			if typeof(picked) == TYPE_DICTIONARY and picked.has("name"):
				var candidate_name = str(picked.name)
				if candidate_name != str(target.get("monster_name")) and OD.Database.get_monster(candidate_name) != null:
					new_name = candidate_name
					break
	entity_grid.replace_monster_at(target, new_name)
	return "transformmonster"

static func handle_status_flag(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var effect_type = str(effect.get("type", "")).to_lower()
	var entity_grid = context.get("entity_grid", null)
	var self_only = int(effect.get("self", 0)) == 1
	var affects_caster = int(effect.get("affectsCaster", effect.get("affectscaster", 0))) == 1
	var target = get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
	if target != null and target.has_method("set_status_flag"):
		var turns = max(1, int(effect.get("turns", effect.get("amount", 2))))
		target.set_status_flag(effect_type, turns)
		if effect_type == "charm" and target.get("is_hostile") != null:
			target.is_hostile = false
	return effect_type

static func handle_remove_buff_by_name(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var self_only = int(effect.get("self", 0)) == 1
	var target = get_target_actor_at(cell, entity_grid, caster, true, self_only)
	if target != null and target.has_method("remove_buff_by_name"):
		target.remove_buff_by_name(str(effect.get("name", "")))
	return "removebuffbyname"

static func handle_grant_xp(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var dungeon = context.get("dungeon", null)
	var xp_amount = int(effect.get("amount", 0))
	if xp_amount > 0 and dungeon != null and dungeon.has_method("award_xp"):
		dungeon.award_xp(xp_amount, cell)
	elif xp_amount > 0 and caster != null and caster.has_method("add_xp"):
		caster.add_xp(xp_amount)
	return "grantxp"

static func handle_drunkenness(effect, _spell_definition, caster, _caster_position, cell, context, _trigger_depth, _execute_fn):
	var entity_grid = context.get("entity_grid", null)
	var target = get_target_actor_at(cell, entity_grid, caster, true, true)
	var turns = max(2, int(effect.get("amount", 4)))
	if target != null and target.has_method("apply_tipsy_buff"):
		target.apply_tipsy_buff(1, turns)
	return "drunkenness"

static func handle_noop(effect, _spell_definition, _caster, _caster_position, _cell, _context, _trigger_depth, _execute_fn):
	return str(effect.get("type", "")).to_lower()
