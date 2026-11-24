extends RefCounted

class_name SpellEngine

const CombatResolverScript = preload("res://script/instance/combat/combat_resolver.gd")

const MAX_TRIGGER_DEPTH = 6

const TARGETLESS_TYPES = {
	"self": true
}

static func compute_mana_cost(caster, spell_def):
	if spell_def == null:
		return 0
	var req = spell_def.get("requirements", null)
	if req == null or typeof(req) != TYPE_DICTIONARY:
		return 0
	var base_mp = int(req.get("mp", 0))
	if base_mp <= 0:
		return 0
	var savvy = 10
	if caster != null and caster.has_method("get_primary_stat"):
		savvy = int(caster.get_primary_stat("savvy"))
	var savvy_bonus = float(req.get("savvyBonus", req.get("savvybonus", 0.0)))
	var min_cost = int(req.get("mincost", 1))
	var reduced = int(round(float(base_mp) - float(savvy) * savvy_bonus))
	return max(0, max(min_cost, reduced))

static func get_cooldown_turns(spell_def):
	if spell_def == null:
		return 0
	var raw = spell_def.get("raw", {})
	if typeof(raw) == TYPE_DICTIONARY and raw.has("downtime"):
		return max(0, int(raw.downtime))
	return 0

static func requires_target_selection(spell_def):
	if spell_def == null:
		return false
	var stype = str(spell_def.get("type", "")).to_lower()
	if TARGETLESS_TYPES.has(stype):
		return false
	var raw = spell_def.get("raw", {})
	if typeof(raw) == TYPE_DICTIONARY and int(raw.get("self", 0)) == 1 and stype == "self":
		return false
	return true

static func can_cast(caster, spell_def):
	if caster == null or spell_def == null:
		return { ok = false, reason = "Invalid caster or spell" }
	var spell_name = str(spell_def.get("name", ""))
	if caster.has_method("get_spell_cooldown"):
		var cd = int(caster.get_spell_cooldown(spell_name))
		if cd > 0:
			return { ok = false, reason = "On cooldown (" + str(cd) + " turns)" }
	var cost = compute_mana_cost(caster, spell_def)
	if caster.get("mp") != null and int(caster.mp) < cost:
		return { ok = false, reason = "Not enough mana (" + str(cost) + " MP)" }
	return { ok = true, mana_cost = cost, cooldown = get_cooldown_turns(spell_def) }

static func _line_cells(start_cell, end_cell):
	var cells = []
	var x0 = int(start_cell.x)
	var y0 = int(start_cell.y)
	var x1 = int(end_cell.x)
	var y1 = int(end_cell.y)
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	return cells

static func _rotate_offset(offset, dir_vec):
	if dir_vec.y < 0:
		return offset
	if dir_vec.y > 0:
		return Vector2i(-offset.x, -offset.y)
	if dir_vec.x > 0:
		return Vector2i(-offset.y, offset.x)
	if dir_vec.x < 0:
		return Vector2i(offset.y, -offset.x)
	return offset

static func _cone_cells(caster_pos, target_pos, max_range = 4):
	var dir_vec = Vector2(target_pos.x - caster_pos.x, target_pos.y - caster_pos.y)
	if dir_vec.length_squared() <= 0.001:
		dir_vec = Vector2(0, 1)
	var forward = dir_vec.normalized()
	var cells = []
	for dist_y in range(-max_range, max_range + 1):
		for dist_x in range(-max_range, max_range + 1):
			if dist_x == 0 and dist_y == 0:
				continue
			var cand = Vector2i(caster_pos.x + dist_x, caster_pos.y + dist_y)
			var delta = Vector2(dist_x, dist_y)
			var dist = delta.length()
			if dist > float(max_range) + 0.35:
				continue
			var dot_val = delta.normalized().dot(forward)
			if dot_val >= 0.68:
				cells.append(cand)
	return cells

static func _radius_cells(center_pos, radius):
	var cells = []
	var rad = max(0, int(radius))
	for dy in range(-rad, rad + 1):
		for dx in range(-rad, rad + 1):
			if max(abs(dx), abs(dy)) <= rad:
				cells.append(Vector2i(center_pos.x + dx, center_pos.y + dy))
	return cells

static func resolve_target_cells(spell_def, caster_pos, target_pos, entity_grid):
	if spell_def == null:
		return []
	var origin = Vector2i(int(caster_pos.x), int(caster_pos.y))
	var target = Vector2i(int(target_pos.x), int(target_pos.y))
	var stype = str(spell_def.get("type", "target")).to_lower()
	var raw = spell_def.get("raw", {})
	var raw_dict = raw if typeof(raw) == TYPE_DICTIONARY else {}

	if stype == "self":
		return [origin]

	if stype == "adjacent" or stype == "adjacentwall" or stype == "targetadjacentcorpse":
		var clamped = Vector2i(
			clamp(target.x, origin.x - 1, origin.x + 1),
			clamp(target.y, origin.y - 1, origin.y + 1)
		)
		return [clamped]

	if stype == "beam" or stype == "diggingbeam" or stype == "beammissile":
		var line = _line_cells(origin, target)
		var out = []
		for ii in range(1, line.size()):
			var cell = line[ii]
			out.append(cell)
			if stype != "diggingbeam" and entity_grid != null and entity_grid.is_wall(cell.x, cell.y):
				break
		if out.is_empty():
			out.append(target)
		return out

	if stype == "cone":
		var cone_range = int(raw_dict.get("radius", 4))
		return _cone_cells(origin, target, cone_range)

	if stype == "template":
		var template_id = str(raw_dict.get("templateID", raw_dict.get("templateid", "")))
		var tmpl = OD.Database.get_template(template_id) if OD.Database != null and template_id != "" else null
		var anchored = int(raw_dict.get("anchored", 0)) == 1
		var anchor_pos = origin if anchored else target
		if tmpl == null:
			return [anchor_pos]
		var delta = target - origin
		var cardinal = Vector2i(0, -1)
		if abs(delta.x) >= abs(delta.y):
			if delta.x > 0:
				cardinal = Vector2i(1, 0)
			elif delta.x < 0:
				cardinal = Vector2i(-1, 0)
		else:
			if delta.y > 0:
				cardinal = Vector2i(0, 1)
			elif delta.y < 0:
				cardinal = Vector2i(0, -1)
		var out = []
		if tmpl.affects_player and anchored:
			out.append(anchor_pos)
		for offset in tmpl.affected_offsets:
			var rot_off = _rotate_offset(offset, cardinal) if anchored else offset
			out.append(anchor_pos + rot_off)
		if out.is_empty():
			out.append(anchor_pos)
		return out

	if stype == "area" or stype == "fireball":
		var rad = int(raw_dict.get("radius", 2 if stype == "fireball" else 1))
		return _radius_cells(target, rad)

	if stype == "missile":
		var ray = _line_cells(origin, target)
		var impact_cell = target
		for ii in range(1, ray.size()):
			var cell = ray[ii]
			if entity_grid != null:
				if entity_grid.is_wall(cell.x, cell.y):
					impact_cell = ray[ii - 1] if ii > 1 else cell
					break
				if entity_grid.get_enemy_at(cell.x, cell.y) != null:
					impact_cell = cell
					break
			impact_cell = cell
		if raw_dict.has("radius"):
			return _radius_cells(impact_cell, int(raw_dict.get("radius", 1)))
		return [impact_cell]

	return [target]

static func execute_spell(spell_name, caster, target_pos, context = {}, trigger_depth = 0):
	if trigger_depth > MAX_TRIGGER_DEPTH:
		return { executed = false, reason = "Max trigger depth exceeded" }
	if OD.Database == null:
		return { executed = false, reason = "Database unavailable" }
	var spell_def = OD.Database.get_spell(str(spell_name))
	if spell_def == null:
		return { executed = false, reason = "Unknown spell: " + str(spell_name) }

	var is_root_cast = trigger_depth == 0 and not bool(context.get("free_cast", false))
	var mana_cost = 0
	var cooldown_turns = 0
	if is_root_cast:
		var check = can_cast(caster, spell_def)
		if not check.ok:
			return { executed = false, reason = check.reason }
		mana_cost = int(check.mana_cost)
		cooldown_turns = int(check.cooldown)
		if mana_cost > 0 and caster != null and caster.has_method("modify_mp"):
			caster.modify_mp(-mana_cost)
		if cooldown_turns > 0 and caster != null and caster.has_method("set_spell_cooldown"):
			caster.set_spell_cooldown(spell_def.name, cooldown_turns)

	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var caster_pos = Vector2i.ZERO
	if caster != null and caster.has_method("get_grid_position") and caster.get_grid_position() != null:
		var raw_pos = caster.get_grid_position()
		caster_pos = Vector2i(int(raw_pos.x), int(raw_pos.y))
	var target_cell = Vector2i(int(target_pos.x), int(target_pos.y))

	var raw = spell_def.get("raw", {})
	var raw_dict = raw if typeof(raw) == TYPE_DICTIONARY else {}
	if is_root_cast and int(raw_dict.get("mine", 0)) == 1 and entity_grid != null:
		var mine_entry = entity_grid.place_spell_mine({
			cell = target_cell,
			spell_name = spell_def.name,
			caster = caster,
			radius = int(raw_dict.get("mineradius", 1)),
			timer = int(raw_dict.get("mineTimer", 5)),
			permanent = int(raw_dict.get("minePermanent", 0)) == 1,
			sprite_series = str(raw_dict.get("mineSpritePNGSeries", raw_dict.get("minespritePNGSeries", ""))),
			sprite_first = int(raw_dict.get("mineSpritePNGFirst", 0)),
			sprite_num = int(raw_dict.get("mineSpritePNGNum", 0)),
			sprite_rate = int(raw_dict.get("mineSpritePNGRate", 100))
		})
		return {
			executed = true,
			spell_name = spell_def.name,
			mana_cost = mana_cost,
			cooldown = cooldown_turns,
			mine_placed = mine_entry != null,
			affected_cells = [target_cell],
			effects_applied = ["mine"]
		}

	var cells = resolve_target_cells(spell_def, caster_pos, target_cell, entity_grid)
	var effects_applied = []

	for cell in cells:
		if dungeon != null and dungeon.has_method("_spawn_spell_vfx"):
			dungeon._spawn_spell_vfx(spell_def.name, cell)
		for eff in spell_def.get("effects", []):
			if typeof(eff) == TYPE_DICTIONARY:
				var eff_res = _apply_effect(eff, spell_def, caster, caster_pos, cell, context, trigger_depth)
				if eff_res != "":
					effects_applied.append(eff_res)
		if spell_def.get("buff", null) != null:
			_apply_spell_buff(spell_def, caster, cell, entity_grid)
			effects_applied.append("buff")

	return {
		executed = true,
		spell_name = spell_def.name,
		mana_cost = mana_cost,
		cooldown = cooldown_turns,
		affected_cells = cells,
		effects_applied = effects_applied
	}

static func _get_target_actor_at(cell, entity_grid, caster, affects_caster = false, self_only = false):
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
		var cpos = caster.get_grid_position()
		if cpos != null and Vector2i(int(cpos.x), int(cpos.y)) == cell:
			return caster
	return null

static func _apply_spell_buff(spell_def, caster, cell, entity_grid):
	var buff_def = spell_def.get("buff", null)
	if buff_def == null or typeof(buff_def) != TYPE_DICTIONARY:
		return
	var buff_self = int(buff_def.get("self", 0)) == 1 or str(spell_def.get("type", "")).to_lower() == "self"
	var target = caster if buff_self else _get_target_actor_at(cell, entity_grid, caster, true, false)
	if target != null and target.has_method("apply_buff"):
		target.apply_buff(buff_def, spell_def.name)

static func _get_magic_power(caster):
	if caster != null and caster.has_method("get_secondary_stat"):
		return int(caster.get_secondary_stat("magic_power"))
	return 0

static func _apply_effect(eff, spell_def, caster, caster_pos, cell, context, trigger_depth):
	var etype = str(eff.get("type", "")).to_lower()
	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var self_only = int(eff.get("self", 0)) == 1
	var affects_caster = int(eff.get("affectsCaster", eff.get("affectscaster", 0))) == 1
	var magic_power = _get_magic_power(caster)

	match etype:
		"damage":
			var target = _get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
			if target == null:
				return ""
			var dmg_map = {}
			var primary_type = "aethereal"
			var max_type_val = -1
			for dmg_type in CombatResolverScript.ALL_DAMAGE_TYPES:
				var base_val = int(eff.get(dmg_type, 0))
				var scale_f = float(eff.get(dmg_type + "F", 0.0))
				var total_val = base_val + int(round(scale_f * float(magic_power)))
				if total_val > 0:
					dmg_map[dmg_type] = total_val
					if total_val > max_type_val:
						max_type_val = total_val
						primary_type = dmg_type
			if eff.has("percent") and target.get("max_hp") != null:
				var pct_dmg = int(round(float(target.max_hp) * float(eff.percent) / 100.0))
				if pct_dmg > 0:
					dmg_map[primary_type] = int(dmg_map.get(primary_type, 0)) + pct_dmg
			var res = CombatResolverScript.resolve_attack(caster, target, {
				kind = "spell",
				damage_map = dmg_map,
				primary_damage_type = primary_type,
				magic_scale = float(eff.get("secondaryScale", 0.0)),
				force_hit = true
			})
			if res.total_damage > 0 and target.get("hp") != null:
				if target.has_method("modify_hp"):
					target.modify_hp(-res.total_damage, spell_def.name)
				else:
					target.hp = max(0, int(target.hp) - res.total_damage)
				if target.has_method("play_hit_animation"):
					target.play_hit_animation()
				if dungeon != null and dungeon.has_method("_spawn_floating_text"):
					dungeon._spawn_floating_text(cell, "-" + str(res.total_damage), Color(0.55, 0.85, 1.0))
				if target != caster and int(target.hp) <= 0 and dungeon != null and dungeon.has_method("_handle_enemy_death"):
					dungeon._handle_enemy_death(target, cell)
			return "damage"

		"heal":
			var target = _get_target_actor_at(cell, entity_grid, caster, true, self_only or str(spell_def.get("type", "")).to_lower() == "self")
			if target == null:
				return ""
			var heal_amt = int(eff.get("amount", 0)) + int(round(float(eff.get("amountF", 0.0)) * float(magic_power)))
			if heal_amt > 0:
				if target.has_method("modify_hp"):
					target.modify_hp(heal_amt)
				elif target.get("hp") != null and target.get("max_hp") != null:
					target.hp = min(int(target.max_hp), int(target.hp) + heal_amt)
				if dungeon != null and dungeon.has_method("_spawn_floating_text"):
					dungeon._spawn_floating_text(cell, "+" + str(heal_amt) + " HP", Color(0.4, 0.95, 0.45))
			return "heal"

		"spellpoints":
			var target = _get_target_actor_at(cell, entity_grid, caster, true, true)
			if target == null:
				return ""
			var mp_amt = int(eff.get("amount", 0)) + int(round(float(eff.get("amountF", 0.0)) * float(magic_power)))
			if eff.has("percent") and target.get("max_mp") != null:
				mp_amt += int(round(float(target.max_mp) * float(eff.percent) / 100.0))
			if mp_amt != 0 and target.has_method("modify_mp"):
				target.modify_mp(mp_amt)
			return "spellpoints"

		"drain":
			var target = _get_target_actor_at(cell, entity_grid, caster, false, false)
			if target == null:
				return ""
			var dmg_map = {}
			for dmg_type in CombatResolverScript.ALL_DAMAGE_TYPES:
				var base_val = int(eff.get(dmg_type, 0))
				var scale_f = float(eff.get(dmg_type + "F", 0.0))
				var total_val = base_val + int(round(scale_f * float(magic_power)))
				if total_val > 0:
					dmg_map[dmg_type] = total_val
			var res = CombatResolverScript.resolve_attack(caster, target, {
				kind = "spell",
				damage_map = dmg_map,
				primary_damage_type = "necromantic",
				force_hit = true
			})
			if res.total_damage > 0:
				if target.has_method("modify_hp"):
					target.modify_hp(-res.total_damage)
				elif target.get("hp") != null:
					target.hp = max(0, int(target.hp) - res.total_damage)
				if caster != null and caster.has_method("modify_hp"):
					caster.modify_hp(max(1, res.total_damage / 2))
				if target != caster and int(target.hp) <= 0 and dungeon != null and dungeon.has_method("_handle_enemy_death"):
					dungeon._handle_enemy_death(target, cell)
			return "drain"

		"drainmana", "draincastermana":
			var target = caster if etype == "draincastermana" else _get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
			if target != null and target.has_method("modify_mp"):
				target.modify_mp(-int(eff.get("amount", 0)))
			return etype

		"dot":
			var target = _get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
			var dot_spell = str(eff.get("spell", ""))
			var turns = max(1, int(eff.get("amount", 1)))
			if target != null and dot_spell != "" and target.has_method("apply_dot"):
				var bound_context = context.duplicate()
				bound_context["free_cast"] = true
				target.apply_dot({
					spell = dot_spell,
					remaining_turns = turns,
					caster = caster,
					on_tick = func(ticked_actor, _dot_entry):
						var pos_now = ticked_actor.get_grid_position() if ticked_actor != null and is_instance_valid(ticked_actor) and ticked_actor.has_method("get_grid_position") else cell
						var c_now = Vector2i(int(pos_now.x), int(pos_now.y)) if pos_now != null else cell
						execute_spell(dot_spell, caster, c_now, bound_context, trigger_depth + 1)
				})
			return "dot"

		"trigger":
			var chance = int(eff.get("percent", eff.get("percentage", 100)))
			if chance < 100 and (randi() % 100) >= chance:
				return ""
			var req_buff = str(eff.get("requirebuffontriggername", ""))
			if int(eff.get("requirebuffontrigger", 0)) == 1 and req_buff != "":
				var check_actor = _get_target_actor_at(cell, entity_grid, caster, true, false)
				if check_actor == null or not check_actor.has_method("has_buff") or not check_actor.has_buff(req_buff):
					return ""
			var not_buff = str(eff.get("requirebuffonnottriggername", ""))
			if int(eff.get("requirebuffonnottrigger", 0)) == 1 and not_buff != "":
				var check_actor2 = _get_target_actor_at(cell, entity_grid, caster, true, false)
				if check_actor2 != null and check_actor2.has_method("has_buff") and check_actor2.has_buff(not_buff):
					return ""
			var child_spell = str(eff.get("spell", ""))
			if child_spell != "":
				var trig_ctx = context.duplicate()
				trig_ctx["free_cast"] = true
				execute_spell(child_spell, caster, cell, trig_ctx, trigger_depth + 1)
			return "trigger"

		"triggerfromlist":
			var sub_spells = OD.DataStructure.arrayify(eff.get("spell", [])) if OD.DataStructure != null else []
			if not sub_spells.is_empty():
				var picked = sub_spells[randi() % sub_spells.size()]
				var picked_name = str(picked.get("name", picked)) if typeof(picked) == TYPE_DICTIONARY else str(picked)
				if picked_name != "":
					var trig_ctx = context.duplicate()
					trig_ctx["free_cast"] = true
					execute_spell(picked_name, caster, cell, trig_ctx, trigger_depth + 1)
			return "triggerfromlist"

		"knock", "suction":
			var target = _get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
			if target == null or entity_grid == null:
				return ""
			var steps = max(1, int(eff.get("amount", 1)))
			var delta = cell - caster_pos
			if etype == "suction":
				delta = caster_pos - cell
			var step_dir = Vector2i(signi(delta.x), signi(delta.y))
			if step_dir == Vector2i.ZERO:
				return ""
			var cur = cell
			for _step in range(steps):
				var nxt = cur + step_dir
				if entity_grid.is_walkable(nxt.x, nxt.y):
					entity_grid.move_actor_to(target, nxt.x, nxt.y)
					cur = nxt
				else:
					break
			return etype

		"dig":
			if entity_grid != null and entity_grid.is_wall(cell.x, cell.y):
				entity_grid.dig_wall(cell.x, cell.y)
				if dungeon != null and dungeon.has_method("update_fov"):
					dungeon.update_fov()
			return "dig"

		"teleport", "blink", "targetblink":
			if entity_grid == null or caster == null:
				return ""
			var dest = cell
			if etype == "teleport":
				dest = entity_grid.get_random_walkable_cell()
			if dest != null and entity_grid.is_walkable(dest.x, dest.y):
				entity_grid.move_actor_to(caster, dest.x, dest.y)
				if dungeon != null and dungeon.has_method("update_fov"):
					dungeon.update_fov()
			return etype

		"summon", "summonhostile":
			if entity_grid == null:
				return ""
			var mon_type = str(eff.get("monsterType", "Diggle"))
			var hostile = etype == "summonhostile"
			entity_grid.spawn_monster_at(mon_type, cell.x, cell.y, -1, hostile)
			return etype

		"transformmonster":
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
						var cand_name = str(picked.name)
						if cand_name != str(target.get("monster_name")) and OD.Database.get_monster(cand_name) != null:
							new_name = cand_name
							break
			entity_grid.replace_monster_at(target, new_name)
			return "transformmonster"

		"paralyze", "confuse", "sleep", "charm", "fear", "pacify", "lockdown", "bleed", "corrupt", "oil":
			var target = _get_target_actor_at(cell, entity_grid, caster, affects_caster, self_only)
			if target != null and target.has_method("set_status_flag"):
				var turns = max(1, int(eff.get("turns", eff.get("amount", 2))))
				target.set_status_flag(etype, turns)
				if etype == "charm" and target.get("is_hostile") != null:
					target.is_hostile = false
			return etype

		"removebuffbyname":
			var target = _get_target_actor_at(cell, entity_grid, caster, true, self_only)
			if target != null and target.has_method("remove_buff_by_name"):
				target.remove_buff_by_name(str(eff.get("name", "")))
			return "removebuffbyname"

		"grantxp":
			var xp_amt = int(eff.get("amount", 0))
			if xp_amt > 0 and dungeon != null and dungeon.has_method("award_xp"):
				dungeon.award_xp(xp_amt, cell)
			elif xp_amt > 0 and caster != null and caster.has_method("add_xp"):
				caster.add_xp(xp_amt)
			return "grantxp"

		_:
			return etype
