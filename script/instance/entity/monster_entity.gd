extends "res://script/instance/entity/entity.gd"

const CombatResolverScript = preload("res://script/instance/combat/combat_resolver.gd")
const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")

var entity_kind = "monster"
var monster_name = ""
var monster_level = 0
var taxa = "Other"
var is_hostile = true
var splat_type = "blood"

var hp = 10
var max_hp = 10
var xp_value = 5

var damage_profile = {}
var resistances = {}
var secondary_stats = {}
var sfx_map = {}
var spells = []
var drops = []
var on_hit_procs = []
var ai_aggressiveness = 3
var ai_span = 4
var ai_spell_pct = 30
var sight_radius = 7
var alerted = false
var spell_cooldowns = {}
var active_buffs = []
var active_dots = []
var status_flags = {}

var _idle_sprites = {}
var _attack_sprites = {}
var _hit_sprites = {}
var _cast_sprites = {}
var _sprite_defs = {}
var _die_sprite_path = ""
var _palette_path = null
var _active_sprite = null
var _facing_direction = "down"
var _hp_bar_background = null
var _hp_bar_fill = null

func _init_stat_tables():
	damage_profile.clear()
	resistances.clear()
	for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
		damage_profile[damage_type] = 0
		resistances[damage_type] = 0
	secondary_stats = {
		crit_chance = 0,
		dodge_chance = 0,
		block_chance = 0,
		counter_chance = 0,
		enemy_dodge_reduction = 0,
		armour_absorption = 0,
		magic_resistance = 0,
		melee_power = 0
	}

func _ensure_sprite_loaded(sprite_dict, kind_key, direction_key):
	if sprite_dict.has(direction_key):
		return sprite_dict[direction_key]
	var sprite_definition = _sprite_defs.get(kind_key, null)
	if sprite_definition == null or typeof(sprite_definition) != TYPE_DICTIONARY or not sprite_definition.has(direction_key):
		return null
	var anim = OD.Load.animation(sprite_definition[direction_key], _palette_path)
	if anim != null:
		anim.visible = false
		if anim.is_tall():
			anim.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
		add_child(anim)
		sprite_dict[direction_key] = anim
	return anim

func init(monster_definition, floor_level = 1):
	_init_stat_tables()
	if monster_definition == null:
		return
	monster_name = str(monster_definition.get("name", "Monster"))
	monster_level = str(monster_definition.get("level", "0")).to_int()
	taxa = str(monster_definition.get("taxa", "Other"))
	splat_type = str(monster_definition.get("splat", "blood"))

	if monster_definition.has("palette") and typeof(monster_definition.palette) == TYPE_DICTIONARY and monster_definition.palette.has("name"):
		_palette_path = monster_definition.palette.name

	if monster_definition.has("sfx") and typeof(monster_definition.sfx) == TYPE_DICTIONARY:
		sfx_map = monster_definition.sfx.duplicate()

	if monster_definition.has("dieSprite") and typeof(monster_definition.dieSprite) == TYPE_DICTIONARY and monster_definition.dieSprite.has("name"):
		_die_sprite_path = str(monster_definition.dieSprite.name)

	var stats_definition = monster_definition.get("stats", {})
	var number_fig = int(stats_definition.get("numFig", 2)) if typeof(stats_definition) == TYPE_DICTIONARY else 2
	xp_value = int(stats_definition.get("xpValue", 5 + monster_level * 5)) if typeof(stats_definition) == TYPE_DICTIONARY else (5 + monster_level * 5)

	var hp_scale = float(OD.Database.get_tweak("monster HP global scale", 1.35)) if OD.Database != null else 1.35
	var hp_per_level = int(OD.Database.get_tweak("monster additional HP per level", 8)) if OD.Database != null else 8
	var hp_percent_per_level = float(OD.Database.get_tweak("monster additional HP percent per level", 0.1)) if OD.Database != null else 0.1
	var base_hp = max(4, number_fig * 4 + max(0, floor_level - 1) * hp_per_level)
	max_hp = max(4, int(round(float(base_hp) * hp_scale * (1.0 + float(max(0, monster_level)) * hp_percent_per_level))))
	hp = max_hp

	if monster_definition.has("damage") and typeof(monster_definition.damage) == TYPE_DICTIONARY:
		for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
			if monster_definition.damage.has(damage_type):
				damage_profile[damage_type] = int(monster_definition.damage[damage_type])

	if monster_definition.has("resistances") and typeof(monster_definition.resistances) == TYPE_DICTIONARY:
		for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
			if monster_definition.resistances.has(damage_type):
				resistances[damage_type] = int(monster_definition.resistances[damage_type])

	if monster_definition.has("secondarybuff"):
		for buff in OD.DataStructure.arrayify(monster_definition.secondarybuff):
			if typeof(buff) == TYPE_DICTIONARY and buff.has("id"):
				var sec_id = int(buff.id)
				if PlayerCharacter.SECONDARY_STAT_BY_ID.has(sec_id):
					var sec_key = PlayerCharacter.SECONDARY_STAT_BY_ID[sec_id]
					secondary_stats[sec_key] = int(secondary_stats.get(sec_key, 0)) + int(buff.get("amount", 0))

	_sprite_defs = {
		idle = monster_definition.get("idleSprite", null),
		attack = monster_definition.get("attackSprite", null),
		hit = monster_definition.get("hitSprite", null),
		cast = monster_definition.get("castSpellSprite", null)
	}
	_ensure_sprite_loaded(_idle_sprites, "idle", "down")

	spells.clear()
	if monster_definition.has("spell"):
		for sp in OD.DataStructure.arrayify(monster_definition.spell):
			if typeof(sp) == TYPE_DICTIONARY and sp.has("name"):
				var sp_name = str(sp.name)
				if sp_name != "" and not spells.has(sp_name):
					spells.append(sp_name)

	drops.clear()
	if monster_definition.has("drop"):
		for dr in OD.DataStructure.arrayify(monster_definition.drop):
			if typeof(dr) == TYPE_DICTIONARY and dr.has("name"):
				drops.append({
					name = str(dr.name),
					percent = int(dr.get("percent", 10))
				})

	on_hit_procs.clear()
	if monster_definition.has("onhit"):
		for oh in OD.DataStructure.arrayify(monster_definition.onhit):
			if typeof(oh) == TYPE_DICTIONARY and oh.has("spell"):
				on_hit_procs.append({
					spell = str(oh.spell),
					one_chance_in = max(1, int(oh.get("onechancein", 1)))
				})

	if monster_definition.has("ai") and typeof(monster_definition.ai) == TYPE_DICTIONARY:
		ai_aggressiveness = int(monster_definition.ai.get("aggressiveness", 3))
		ai_span = max(1, int(monster_definition.ai.get("span", 4)))
		ai_spell_pct = clamp(int(monster_definition.ai.get("spellPercentage", 30)), 0, 100)

	if monster_definition.has("sight") and typeof(monster_definition.sight) == TYPE_DICTIONARY:
		sight_radius = max(2, int(monster_definition.sight.get("radius", 7)))

	if _idle_sprites.has("down"):
		_active_sprite = _idle_sprites["down"]
		_active_sprite.visible = true

func get_secondary_stat(stat_key):
	return int(secondary_stats.get(stat_key, 0))

func get_resistance(damage_type):
	return int(resistances.get(damage_type, 0))

func get_xp_value():
	return xp_value

func set_facing(delta_x, delta_y):
	if abs(delta_x) >= abs(delta_y):
		if delta_x < 0:
			_facing_direction = "left"
		elif delta_x > 0:
			_facing_direction = "right"
	else:
		if delta_y < 0:
			_facing_direction = "up"
		else:
			_facing_direction = "down"
	_show_sprite(_idle_sprites, _facing_direction, "idle")

func _show_sprite(sprite_dict, direction_key, kind_key = "idle"):
	var target = _ensure_sprite_loaded(sprite_dict, kind_key, direction_key)
	if target == null:
		target = _ensure_sprite_loaded(sprite_dict, kind_key, "down")
	if target == null or target == _active_sprite:
		return
	if _active_sprite != null:
		_active_sprite.visible = false
	_active_sprite = target
	_active_sprite.visible = true

func play_hit_animation():
	modulate = Color(1.4, 0.45, 0.45, 1.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
	if _sprite_defs.get("hit", null) == null:
		return
	_show_sprite(_hit_sprites, _facing_direction, "hit")
	var timer = get_tree().create_timer(0.18) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(self):
				_show_sprite(_idle_sprites, _facing_direction, "idle")
		)

func play_attack_animation():
	if _sprite_defs.get("attack", null) == null:
		return
	_show_sprite(_attack_sprites, _facing_direction, "attack")
	var timer = get_tree().create_timer(0.22) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(self):
				_show_sprite(_idle_sprites, _facing_direction, "idle")
		)

func play_sfx(kind):
	if sfx_map.has(kind) and OD.Audio != null:
		OD.Audio.play_sfx(str(sfx_map[kind]))

func get_die_sprite_path():
	return _die_sprite_path

func get_palette_path():
	return _palette_path

func play_cast_animation():
	if _sprite_defs.get("cast", null) == null:
		play_attack_animation()
		return
	_show_sprite(_cast_sprites, _facing_direction, "cast")
	var timer = get_tree().create_timer(0.24) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(self):
				_show_sprite(_idle_sprites, _facing_direction, "idle")
		)

func play_die_animation_at(entity_grid, cell):
	if _die_sprite_path == "" or entity_grid == null or OD.Load == null:
		return
	var die_animation = OD.Load.animation(_die_sprite_path, _palette_path)
	if die_animation == null:
		return
	var px = OD.Math.grid_to_pixel(cell.x, cell.y)
	entity_grid.add_animation(px.x, px.y, "floating_text", die_animation)
	var timer = entity_grid.get_tree().create_timer(0.45) if entity_grid.is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(die_animation):
				die_animation.queue_free()
		)

func roll_drops():
	var rolled = []
	if OD.Database == null:
		return rolled
	for drop_entry in drops:
		var pct = clamp(int(drop_entry.get("percent", 0)), 0, 100)
		if pct >= 100 or (randi() % 100) < pct:
			var item_inst = OD.Database.create_item_instance(str(drop_entry.name))
			if item_inst != null:
				rolled.append({
					kind = "item",
					item = item_inst
				})
	if (randi() % 100) < 15:
		var extra_loot = OD.Database.roll_floor_loot(max(1, monster_level + 1), "", 0.06)
		if extra_loot != null:
			rolled.append(extra_loot)
	return rolled

func _tick_spell_cooldowns():
	for key in spell_cooldowns.keys():
		var remaining = int(spell_cooldowns[key]) - 1
		if remaining <= 0:
			spell_cooldowns.erase(key)
		else:
			spell_cooldowns[key] = remaining

func _pick_castable_spell():
	var candidates = []
	for sp_name in spells:
		if int(spell_cooldowns.get(sp_name, 0)) <= 0:
			candidates.append(sp_name)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]

func _step_toward(entity_grid, my_position, target_position):
	var best_cell = null
	var best_distance = 999999
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var candidate = my_position + direction
		if not entity_grid.is_walkable(candidate.x, candidate.y):
			continue
		var d = abs(candidate.x - target_position.x) + abs(candidate.y - target_position.y)
		if d < best_distance:
			best_distance = d
			best_cell = candidate
	if best_cell == null:
		var adjacent_goal = null
		var adjacent_distance = 999999
		for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var candidate = target_position + direction
			if entity_grid.is_walkable(candidate.x, candidate.y):
				var path = entity_grid.find_path(my_position, candidate, { max_visited = 192 })
				if not path.is_empty() and path.size() < adjacent_distance:
					adjacent_distance = path.size()
					adjacent_goal = path[0]
		best_cell = adjacent_goal
	if best_cell != null:
		var dx = best_cell.x - my_position.x
		var dy = best_cell.y - my_position.y
		set_facing(dx, dy)
		entity_grid.move_actor_to(self, best_cell.x, best_cell.y)
		return true
	return false

func _step_away(entity_grid, my_position, threat_position):
	var best_cell = null
	var best_distance = abs(my_position.x - threat_position.x) + abs(my_position.y - threat_position.y)
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate = my_position + direction
		if not entity_grid.is_walkable(candidate.x, candidate.y):
			continue
		var d = abs(candidate.x - threat_position.x) + abs(candidate.y - threat_position.y)
		if d > best_distance:
			best_distance = d
			best_cell = candidate
	if best_cell != null:
		set_facing(best_cell.x - my_position.x, best_cell.y - my_position.y)
		entity_grid.move_actor_to(self, best_cell.x, best_cell.y)
		return true
	return false

func _roam_step(entity_grid, my_position):
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	for direction in dirs:
		var candidate = my_position + direction
		if entity_grid.is_walkable(candidate.x, candidate.y):
			set_facing(direction.x, direction.y)
			entity_grid.move_actor_to(self, candidate.x, candidate.y)
			return true
	return false

func step_ai(entity_grid, player_position, player, dungeon = null):
	if hp <= 0 or entity_grid == null or player_position == null:
		return "none"
	_tick_spell_cooldowns()
	if has_status_flag("paralyze") or has_status_flag("sleep"):
		return "stunned"
	var position_raw = get_grid_position()
	if position_raw == null:
		return "none"
	var my_position = Vector2i(int(position_raw.x), int(position_raw.y))
	var target_position = Vector2i(int(player_position.x), int(player_position.y))
	var chebyshev_distance = max(abs(target_position.x - my_position.x), abs(target_position.y - my_position.y))

	if not alerted and chebyshev_distance <= sight_radius:
		if entity_grid.is_cell_visible(my_position.x, my_position.y) or entity_grid._has_clear_los(my_position, target_position):
			alerted = true

	if has_status_flag("fear"):
		if _step_away(entity_grid, my_position, target_position):
			return "flee"
		return "idle"

	if has_status_flag("confuse"):
		if _roam_step(entity_grid, my_position):
			return "confused_move"
		return "idle"

	if not is_hostile or has_status_flag("pacify"):
		if (randi() % 100) < 30 and _roam_step(entity_grid, my_position):
			return "roam"
		return "idle"

	if not alerted:
		if (randi() % 100) < 35 and _roam_step(entity_grid, my_position):
			return "roam"
		return "idle"

	if chebyshev_distance == 1 and player != null and is_instance_valid(player):
		set_facing(target_position.x - my_position.x, target_position.y - my_position.y)
		play_attack_animation()
		play_sfx("attack")
		var result = CombatResolverScript.resolve_attack(self, player, { kind = "melee" })
		if result.hit and result.total_damage > 0:
			if player.has_method("modify_hp"):
				player.modify_hp(-result.total_damage, monster_name)
			if dungeon != null and dungeon.has_method("on_monster_attack_player"):
				dungeon.on_monster_attack_player(self, result, my_position, target_position)
			for oh in on_hit_procs:
				if (randi() % int(oh.one_chance_in)) == 0:
					SpellEngineScript.execute_spell(oh.spell, self, target_position, {
						entity_grid = entity_grid,
						dungeon = dungeon,
						free_cast = true
					})
		elif dungeon != null and dungeon.has_method("spawn_floating_badge"):
			dungeon.spawn_floating_badge(target_position, "dodge", "Dodged!")
		elif dungeon != null and dungeon.has_method("_spawn_floating_text"):
			dungeon._spawn_floating_text(target_position, "Dodged!", Color(0.75, 0.75, 0.85))
		return "attack"

	if not spells.is_empty() and chebyshev_distance <= sight_radius and (randi() % 100) < ai_spell_pct:
		var chosen_spell = _pick_castable_spell()
		if chosen_spell != "":
			set_facing(target_position.x - my_position.x, target_position.y - my_position.y)
			play_cast_animation()
			play_sfx("spell")
			var sp_definition = OD.Database.get_spell(chosen_spell) if OD.Database != null else null
			var cooldown = SpellEngineScript.get_cooldown_turns(sp_definition)
			spell_cooldowns[chosen_spell] = max(2, cooldown)
			SpellEngineScript.execute_spell(chosen_spell, self, target_position, {
				entity_grid = entity_grid,
				dungeon = dungeon,
				free_cast = true
			})
			return "cast:" + chosen_spell

	if not has_status_flag("lockdown"):
		if _step_toward(entity_grid, my_position, target_position):
			return "chase"
	return "idle"

func has_buff(buff_name):
	var target_name = str(buff_name)
	for buff in active_buffs:
		if str(buff.get("name", "")) == target_name:
			return true
	return false

func remove_buff_by_name(buff_name):
	var target_name = str(buff_name)
	var removed = false
	var ii = 0
	while ii < active_buffs.size():
		if str(active_buffs[ii].get("name", "")) == target_name:
			active_buffs.remove_at(ii)
			removed = true
		else:
			ii += 1
	return removed

func apply_buff(buff_definition, source_spell = ""):
	if buff_definition == null or typeof(buff_definition) != TYPE_DICTIONARY:
		return false
	var buff_name = str(buff_definition.get("name", source_spell))
	var duration = int(buff_definition.get("time", buff_definition.get("duration", 0)))
	var use_timer = int(buff_definition.get("useTimer", buff_definition.get("usetimer", 1 if duration > 0 else 0))) == 1
	for existing in active_buffs:
		if str(existing.get("name", "")) == buff_name:
			if use_timer:
				existing["remaining_turns"] = max(1, duration)
			return true
	active_buffs.append({
		name = buff_name,
		use_timer = use_timer,
		remaining_turns = max(1, duration) if use_timer else -1,
		brittle_remaining = int(buff_definition.get("brittle", 0)),
		raw = buff_definition
	})
	return true

func refresh_health_bar():
	if max_hp <= 0 or hp <= 0 or hp >= max_hp:
		if _hp_bar_background != null:
			_hp_bar_background.visible = false
		return
	if _hp_bar_background == null and OD.Load != null:
		var background_texture = OD.Load.image("ui/tiny_healthbar_bg.png") if OD.Load.exists("ui/tiny_healthbar_bg.png") else null
		var fill_texture = OD.Load.image("ui/tiny_healthbar.png") if OD.Load.exists("ui/tiny_healthbar.png") else null
		if background_texture != null and fill_texture != null:
			_hp_bar_background = TextureRect.new()
			_hp_bar_background.texture = background_texture
			_hp_bar_background.size = background_texture.get_size()
			_hp_bar_background.position = Vector2(-background_texture.get_width() * 0.5, -24.0)
			_hp_bar_background.scale = Vector2(0.75, 1.0)
			_hp_bar_background.pivot_offset = Vector2(background_texture.get_width() * 0.5, 0.0)
			_hp_bar_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_hp_bar_background.z_index = 10
			add_child(_hp_bar_background)

			_hp_bar_fill = TextureRect.new()
			_hp_bar_fill.texture = fill_texture
			_hp_bar_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_hp_bar_fill.position = Vector2(2.0, 2.0)
			_hp_bar_fill.size = fill_texture.get_size()
			_hp_bar_fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_hp_bar_background.add_child(_hp_bar_fill)
	if _hp_bar_background != null and _hp_bar_fill != null:
		_hp_bar_background.visible = true
		var ratio = clamp(float(hp) / float(max(1, max_hp)), 0.0, 1.0)
		_hp_bar_fill.size.x = max(1.0, 64.0 * ratio)

func on_hit_received():
	refresh_health_bar()
	var ii = 0
	while ii < active_buffs.size():
		var brittle = int(active_buffs[ii].get("brittle_remaining", 0))
		if brittle > 0:
			brittle -= 1
			active_buffs[ii]["brittle_remaining"] = brittle
			if brittle <= 0:
				active_buffs.remove_at(ii)
				continue
		ii += 1

func set_status_flag(flag_name, turns):
	var key = str(flag_name)
	var count = int(turns)
	if count <= 0:
		status_flags.erase(key)
	else:
		status_flags[key] = max(int(status_flags.get(key, 0)), count)

func has_status_flag(flag_name):
	return int(status_flags.get(str(flag_name), 0)) > 0

func apply_dot(dot_definition):
	if dot_definition == null or typeof(dot_definition) != TYPE_DICTIONARY:
		return
	active_dots.append(dot_definition.duplicate(true))

func tick_status_effects():
	var ticked = 0
	var ii = 0
	while ii < active_buffs.size():
		var buff = active_buffs[ii]
		ticked += 1
		if buff.get("use_timer", false):
			buff["remaining_turns"] = int(buff.get("remaining_turns", 1)) - 1
			if buff["remaining_turns"] <= 0:
				active_buffs.remove_at(ii)
				continue
		ii += 1
	for flag_key in status_flags.keys():
		ticked += 1
		var remaining = int(status_flags[flag_key]) - 1
		if remaining <= 0:
			status_flags.erase(flag_key)
		else:
			status_flags[flag_key] = remaining
	var jj = 0
	while jj < active_dots.size():
		var dot = active_dots[jj]
		ticked += 1
		if dot.has("on_tick") and dot.on_tick is Callable:
			dot.on_tick.call(self, dot)
		dot["remaining_turns"] = int(dot.get("remaining_turns", 1)) - 1
		if dot["remaining_turns"] <= 0:
			active_dots.remove_at(jj)
		else:
			jj += 1
	return ticked
