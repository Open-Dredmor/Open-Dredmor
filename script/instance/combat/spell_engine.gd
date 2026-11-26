extends RefCounted

class_name SpellEngine

const EffectHandlers = preload("res://script/instance/combat/spell_effect_handlers.gd")

const MAX_TRIGGER_DEPTH = 6

const TARGETLESS_TYPES = {
	"self": true
}

static var _custom_effect_handlers = {}
static var _custom_shape_handlers = {}
static var _warned_unknown_effects = {}

static func register_effect_handler(effect_type, handler):
	_custom_effect_handlers[str(effect_type).to_lower()] = handler

static func register_target_shape(shape_name, handler):
	_custom_shape_handlers[str(shape_name).to_lower()] = handler

static func _default_effect_handlers():
	return {
		"damage": EffectHandlers.handle_damage,
		"heal": EffectHandlers.handle_heal,
		"spellpoints": EffectHandlers.handle_spellpoints,
		"drain": EffectHandlers.handle_drain,
		"drainmana": EffectHandlers.handle_drain_mana,
		"draincastermana": EffectHandlers.handle_drain_mana,
		"dot": EffectHandlers.handle_dot,
		"trigger": EffectHandlers.handle_trigger,
		"triggerfromlist": EffectHandlers.handle_trigger_from_list,
		"knock": EffectHandlers.handle_knock_or_suction,
		"suction": EffectHandlers.handle_knock_or_suction,
		"dig": EffectHandlers.handle_dig,
		"teleport": EffectHandlers.handle_teleport,
		"blink": EffectHandlers.handle_teleport,
		"targetblink": EffectHandlers.handle_teleport,
		"summon": EffectHandlers.handle_summon,
		"summonhostile": EffectHandlers.handle_summon,
		"transformmonster": EffectHandlers.handle_transform_monster,
		"paralyze": EffectHandlers.handle_status_flag,
		"confuse": EffectHandlers.handle_status_flag,
		"sleep": EffectHandlers.handle_status_flag,
		"charm": EffectHandlers.handle_status_flag,
		"fear": EffectHandlers.handle_status_flag,
		"pacify": EffectHandlers.handle_status_flag,
		"lockdown": EffectHandlers.handle_status_flag,
		"bleed": EffectHandlers.handle_status_flag,
		"corrupt": EffectHandlers.handle_status_flag,
		"oil": EffectHandlers.handle_status_flag,
		"removebuffbyname": EffectHandlers.handle_remove_buff_by_name,
		"grantxp": EffectHandlers.handle_grant_xp,
		"drunkenness": EffectHandlers.handle_drunkenness,
		"consumebooze": EffectHandlers.handle_noop
	}

static func compute_mana_cost(caster, spell_definition):
	if spell_definition == null:
		return 0
	var req = spell_definition.get("requirements", null)
	if req == null or typeof(req) != TYPE_DICTIONARY:
		return 0
	var base_mp = int(req.get("mp", 0))
	if base_mp <= 0:
		return 0
	var savvy = 10
	if caster != null and caster.has_method("get_primary_stat"):
		savvy = int(caster.get_primary_stat("savvy"))
	var savvy_bonus = float(req.get("savvybonus", req.get("savvyBonus", 0.0)))
	var min_cost = int(req.get("mincost", 1))
	var reduced = int(round(float(base_mp) - float(savvy) * savvy_bonus))
	return max(0, max(min_cost, reduced))

static func get_cooldown_turns(spell_definition):
	if spell_definition == null:
		return 0
	var raw = spell_definition.get("raw", {})
	if typeof(raw) == TYPE_DICTIONARY and raw.has("downtime"):
		return max(0, int(raw.downtime))
	return 0

static func requires_target_selection(spell_definition):
	if spell_definition == null:
		return false
	var stype = str(spell_definition.get("type", "")).to_lower()
	if TARGETLESS_TYPES.has(stype):
		return false
	var raw = spell_definition.get("raw", {})
	if typeof(raw) == TYPE_DICTIONARY and int(raw.get("self", 0)) == 1 and stype == "self":
		return false
	return true

static func can_cast(caster, spell_definition):
	if caster == null or spell_definition == null:
		return { ok = false, reason = "Invalid caster or spell" }
	var spell_name = str(spell_definition.get("name", ""))
	if caster.has_method("get_spell_cooldown"):
		var cd = int(caster.get_spell_cooldown(spell_name))
		if cd > 0:
			return { ok = false, reason = "On cooldown (" + str(cd) + " turns)" }
	var cost = compute_mana_cost(caster, spell_definition)
	if caster.get("mp") != null and int(caster.mp) < cost:
		return { ok = false, reason = "Not enough mana (" + str(cost) + " MP)" }
	return { ok = true, mana_cost = cost, cooldown = get_cooldown_turns(spell_definition) }

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
	var error = dx - dy
	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * error
		if e2 > -dy:
			error -= dy
			x0 += sx
		if e2 < dx:
			error += dx
			y0 += sy
	return cells

static func _rotate_offset(offset, direction_vec):
	if direction_vec.y < 0:
		return offset
	if direction_vec.y > 0:
		return Vector2i(-offset.x, -offset.y)
	if direction_vec.x > 0:
		return Vector2i(-offset.y, offset.x)
	if direction_vec.x < 0:
		return Vector2i(offset.y, -offset.x)
	return offset

static func _cone_cells(caster_position, target_position, max_range = 4):
	var direction_vec = Vector2(target_position.x - caster_position.x, target_position.y - caster_position.y)
	if direction_vec.length_squared() <= 0.001:
		direction_vec = Vector2(0, 1)
	var forward = direction_vec.normalized()
	var cells = []
	for distance_y in range(-max_range, max_range + 1):
		for distance_x in range(-max_range, max_range + 1):
			if distance_x == 0 and distance_y == 0:
				continue
			var candidate = Vector2i(caster_position.x + distance_x, caster_position.y + distance_y)
			var delta = Vector2(distance_x, distance_y)
			var distance = delta.length()
			if distance > float(max_range) + 0.35:
				continue
			var dot_value = delta.normalized().dot(forward)
			if dot_value >= 0.68:
				cells.append(candidate)
	return cells

static func _radius_cells(center_position, radius):
	var cells = []
	var rad = max(0, int(radius))
	for dy in range(-rad, rad + 1):
		for dx in range(-rad, rad + 1):
			if max(abs(dx), abs(dy)) <= rad:
				cells.append(Vector2i(center_position.x + dx, center_position.y + dy))
	return cells

static func resolve_target_cells(spell_definition, caster_position, target_position, entity_grid):
	if spell_definition == null:
		return []
	var origin = Vector2i(int(caster_position.x), int(caster_position.y))
	var target = Vector2i(int(target_position.x), int(target_position.y))
	var stype = str(spell_definition.get("type", "target")).to_lower()
	var raw = spell_definition.get("raw", {})
	var raw_dict = raw if typeof(raw) == TYPE_DICTIONARY else {}

	if _custom_shape_handlers.has(stype):
		return _custom_shape_handlers[stype].call(spell_definition, origin, target, entity_grid)

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
		var anchor_position = origin if anchored else target
		if tmpl == null:
			return [anchor_position]
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
		var affects_caster = bool(tmpl.get("affectscaster", tmpl.get("affects_player", false)))
		var offsets = tmpl.get("offsets", tmpl.get("affected_offsets", []))
		if affects_caster and anchored:
			out.append(anchor_position)
		for offset in offsets:
			var rotation_off = _rotate_offset(offset, cardinal) if anchored else offset
			out.append(anchor_position + rotation_off)
		if out.is_empty():
			out.append(anchor_position)
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

static func execute_spell(spell_name, caster, target_position, context = {}, trigger_depth = 0):
	if trigger_depth > MAX_TRIGGER_DEPTH:
		return { executed = false, reason = "Max trigger depth exceeded" }
	if OD.Database == null:
		return { executed = false, reason = "Database unavailable" }
	var spell_definition = OD.Database.get_spell(str(spell_name))
	if spell_definition == null:
		return { executed = false, reason = "Unknown spell: " + str(spell_name) }

	var is_root_cast = trigger_depth == 0 and not bool(context.get("free_cast", false))
	var mana_cost = 0
	var cooldown_turns = 0
	if is_root_cast:
		var check = can_cast(caster, spell_definition)
		if not check.ok:
			return { executed = false, reason = check.reason }
		mana_cost = int(check.mana_cost)
		cooldown_turns = int(check.cooldown)
		if mana_cost > 0 and caster != null and caster.has_method("modify_mp"):
			caster.modify_mp(-mana_cost)
		if cooldown_turns > 0 and caster != null and caster.has_method("set_spell_cooldown"):
			caster.set_spell_cooldown(spell_definition.name, cooldown_turns)

	var entity_grid = context.get("entity_grid", null)
	var dungeon = context.get("dungeon", null)
	var caster_position = Vector2i.ZERO
	if caster != null and caster.has_method("get_grid_position") and caster.get_grid_position() != null:
		var raw_position = caster.get_grid_position()
		caster_position = Vector2i(int(raw_position.x), int(raw_position.y))
	var target_cell = Vector2i(int(target_position.x), int(target_position.y))

	var raw = spell_definition.get("raw", {})
	var raw_dict = raw if typeof(raw) == TYPE_DICTIONARY else {}
	if is_root_cast and int(raw_dict.get("mine", 0)) == 1 and entity_grid != null:
		var mine_entry = entity_grid.place_spell_mine({
			cell = target_cell,
			spell_name = spell_definition.name,
			caster = caster,
			radius = int(raw_dict.get("mineradius", 1)),
			timer = int(raw_dict.get("mineTimer", 5)),
			permanent = int(raw_dict.get("minePermanent", 0)) == 1,
			sprite_series = str(raw_dict.get("mineSpritePNGSeries", raw_dict.get("minespritePNGSeries", ""))),
			sprite_first = int(raw_dict.get("mineSpritePNGFirst", 0)),
			sprite_num = int(raw_dict.get("mineSpritePNGNum", 0)),
			sprite_rate = int(raw_dict.get("mineSpritePNGRate", 100))
		})
		if mine_entry != null and OD.Audio != null:
			OD.Audio.play_sfx("rune_set")
		return {
			executed = true,
			spell_name = spell_definition.name,
			mana_cost = mana_cost,
			cooldown = cooldown_turns,
			mine_placed = mine_entry != null,
			affected_cells = [target_cell],
			effects_applied = ["mine"]
		}

	var cells = resolve_target_cells(spell_definition, caster_position, target_cell, entity_grid)
	var effects_applied = []

	for cell_index in range(cells.size()):
		var cell = cells[cell_index]
		if dungeon != null and dungeon.has_method("_spawn_spell_vfx"):
			dungeon._spawn_spell_vfx(spell_definition.name, cell, cell_index == 0)
		for effect in spell_definition.get("effects", []):
			if typeof(effect) == TYPE_DICTIONARY:
				var effect_result = _apply_effect(effect, spell_definition, caster, caster_position, cell, context, trigger_depth)
				if effect_result != "":
					effects_applied.append(effect_result)
		if spell_definition.get("buff", null) != null:
			_apply_spell_buff(spell_definition, caster, cell, entity_grid)
			effects_applied.append("buff")

	return {
		executed = true,
		spell_name = spell_definition.name,
		mana_cost = mana_cost,
		cooldown = cooldown_turns,
		affected_cells = cells,
		effects_applied = effects_applied
	}

static func _apply_spell_buff(spell_definition, caster, cell, entity_grid):
	var buff_definition = spell_definition.get("buff", null)
	if buff_definition == null or typeof(buff_definition) != TYPE_DICTIONARY:
		return
	var buff_self = int(buff_definition.get("self", 0)) == 1 or str(spell_definition.get("type", "")).to_lower() == "self"
	var target = caster if buff_self else EffectHandlers.get_target_actor_at(cell, entity_grid, caster, true, false)
	if target != null and target.has_method("apply_buff"):
		target.apply_buff(buff_definition, spell_definition.name)

static func _apply_effect(effect, spell_definition, caster, caster_position, cell, context, trigger_depth):
	var effect_type = str(effect.get("type", "")).to_lower()
	if _custom_effect_handlers.has(effect_type):
		return _custom_effect_handlers[effect_type].call(effect, spell_definition, caster, caster_position, cell, context, trigger_depth, execute_spell)
	var defaults = _default_effect_handlers()
	if defaults.has(effect_type):
		return defaults[effect_type].call(effect, spell_definition, caster, caster_position, cell, context, trigger_depth, execute_spell)
	if effect_type != "" and not _warned_unknown_effects.has(effect_type):
		_warned_unknown_effects[effect_type] = true
		push_warning("Unsupported spell effect type [" + effect_type + "] in spell [" + str(spell_definition.get("name", "")) + "]")
	return effect_type
