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
var _die_sprite_path = ""
var _palette_path = null
var _active_sprite = null
var _facing_dir = "down"

func _init_stat_tables():
	damage_profile.clear()
	resistances.clear()
	for dmg_type in CombatResolverScript.ALL_DAMAGE_TYPES:
		damage_profile[dmg_type] = 0
		resistances[dmg_type] = 0
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

func _load_directional_sprites(sprite_def, target_dict):
	if sprite_def == null or typeof(sprite_def) != TYPE_DICTIONARY:
		return
	for dir_key in ["down", "up", "left", "right"]:
		if sprite_def.has(dir_key):
			var anim = OD.Load.animation(sprite_def[dir_key], _palette_path)
			if anim != null:
				anim.visible = false
				if anim.is_tall():
					anim.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
				add_child(anim)
				target_dict[dir_key] = anim

func init(monster_def, floor_level = 1):
	_init_stat_tables()
	if monster_def == null:
		return
	monster_name = str(monster_def.get("name", "Monster"))
	monster_level = str(monster_def.get("level", "0")).to_int()
	taxa = str(monster_def.get("taxa", "Other"))
	splat_type = str(monster_def.get("splat", "blood"))

	if monster_def.has("palette") and typeof(monster_def.palette) == TYPE_DICTIONARY and monster_def.palette.has("name"):
		_palette_path = monster_def.palette.name

	if monster_def.has("sfx") and typeof(monster_def.sfx) == TYPE_DICTIONARY:
		sfx_map = monster_def.sfx.duplicate()

	if monster_def.has("dieSprite") and typeof(monster_def.dieSprite) == TYPE_DICTIONARY and monster_def.dieSprite.has("name"):
		_die_sprite_path = str(monster_def.dieSprite.name)

	var stats_def = monster_def.get("stats", {})
	var num_fig = int(stats_def.get("numFig", 2)) if typeof(stats_def) == TYPE_DICTIONARY else 2
	xp_value = int(stats_def.get("xpValue", 5 + monster_level * 5)) if typeof(stats_def) == TYPE_DICTIONARY else (5 + monster_level * 5)

	var hp_scale = float(OD.Database.get_tweak("monster HP global scale", 1.35)) if OD.Database != null else 1.35
	var hp_per_lvl = int(OD.Database.get_tweak("monster additional HP per level", 8)) if OD.Database != null else 8
	var hp_pct_per_lvl = float(OD.Database.get_tweak("monster additional HP percent per level", 0.1)) if OD.Database != null else 0.1
	var base_hp = max(4, num_fig * 4 + max(0, floor_level - 1) * hp_per_lvl)
	max_hp = max(4, int(round(float(base_hp) * hp_scale * (1.0 + float(max(0, monster_level)) * hp_pct_per_lvl))))
	hp = max_hp

	if monster_def.has("damage") and typeof(monster_def.damage) == TYPE_DICTIONARY:
		for dmg_type in CombatResolverScript.ALL_DAMAGE_TYPES:
			if monster_def.damage.has(dmg_type):
				damage_profile[dmg_type] = int(monster_def.damage[dmg_type])

	if monster_def.has("resistances") and typeof(monster_def.resistances) == TYPE_DICTIONARY:
		for dmg_type in CombatResolverScript.ALL_DAMAGE_TYPES:
			if monster_def.resistances.has(dmg_type):
				resistances[dmg_type] = int(monster_def.resistances[dmg_type])

	if monster_def.has("secondarybuff"):
		for buff in OD.DataStructure.arrayify(monster_def.secondarybuff):
			if typeof(buff) == TYPE_DICTIONARY and buff.has("id"):
				var sec_id = int(buff.id)
				if PlayerCharacter.SECONDARY_STAT_BY_ID.has(sec_id):
					var sec_key = PlayerCharacter.SECONDARY_STAT_BY_ID[sec_id]
					secondary_stats[sec_key] = int(secondary_stats.get(sec_key, 0)) + int(buff.get("amount", 0))

	_load_directional_sprites(monster_def.get("idleSprite", null), _idle_sprites)
	_load_directional_sprites(monster_def.get("attackSprite", null), _attack_sprites)
	_load_directional_sprites(monster_def.get("hitSprite", null), _hit_sprites)
	_load_directional_sprites(monster_def.get("castSpellSprite", null), _cast_sprites)

	spells.clear()
	if monster_def.has("spell"):
		for sp in OD.DataStructure.arrayify(monster_def.spell):
			if typeof(sp) == TYPE_DICTIONARY and sp.has("name"):
				var sp_name = str(sp.name)
				if sp_name != "" and not spells.has(sp_name):
					spells.append(sp_name)

	drops.clear()
	if monster_def.has("drop"):
		for dr in OD.DataStructure.arrayify(monster_def.drop):
			if typeof(dr) == TYPE_DICTIONARY and dr.has("name"):
				drops.append({
					name = str(dr.name),
					percent = int(dr.get("percent", 10))
				})

	on_hit_procs.clear()
	if monster_def.has("onhit"):
		for oh in OD.DataStructure.arrayify(monster_def.onhit):
			if typeof(oh) == TYPE_DICTIONARY and oh.has("spell"):
				on_hit_procs.append({
					spell = str(oh.spell),
					one_chance_in = max(1, int(oh.get("onechancein", 1)))
				})

	if monster_def.has("ai") and typeof(monster_def.ai) == TYPE_DICTIONARY:
		ai_aggressiveness = int(monster_def.ai.get("aggressiveness", 3))
		ai_span = max(1, int(monster_def.ai.get("span", 4)))
		ai_spell_pct = clamp(int(monster_def.ai.get("spellPercentage", 30)), 0, 100)

	if monster_def.has("sight") and typeof(monster_def.sight) == TYPE_DICTIONARY:
		sight_radius = max(2, int(monster_def.sight.get("radius", 7)))

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
			_facing_dir = "left"
		elif delta_x > 0:
			_facing_dir = "right"
	else:
		if delta_y < 0:
			_facing_dir = "up"
		else:
			_facing_dir = "down"
	_show_sprite(_idle_sprites, _facing_dir)

func _show_sprite(sprite_dict, dir_key):
	var target = sprite_dict.get(dir_key, sprite_dict.get("down", null))
	if target == null or target == _active_sprite:
		return
	if _active_sprite != null:
		_active_sprite.visible = false
	_active_sprite = target
	_active_sprite.visible = true

func play_hit_animation():
	if _hit_sprites.is_empty():
		return
	_show_sprite(_hit_sprites, _facing_dir)
	var timer = get_tree().create_timer(0.18) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(self):
				_show_sprite(_idle_sprites, _facing_dir)
		)

func play_attack_animation():
	if _attack_sprites.is_empty():
		return
	_show_sprite(_attack_sprites, _facing_dir)
	var timer = get_tree().create_timer(0.22) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(self):
				_show_sprite(_idle_sprites, _facing_dir)
		)

func play_sfx(kind):
	if sfx_map.has(kind) and OD.Audio != null:
		OD.Audio.play_sfx(str(sfx_map[kind]))

func get_die_sprite_path():
	return _die_sprite_path

func get_palette_path():
	return _palette_path

func play_cast_animation():
	if _cast_sprites.is_empty():
		play_attack_animation()
		return
	_show_sprite(_cast_sprites, _facing_dir)
	var timer = get_tree().create_timer(0.24) if is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(self):
				_show_sprite(_idle_sprites, _facing_dir)
		)

func play_die_animation_at(entity_grid, cell):
	if _die_sprite_path == "" or entity_grid == null or OD.Load == null:
		return
	var die_anim = OD.Load.animation(_die_sprite_path, _palette_path)
	if die_anim == null:
		return
	var px = OD.Math.grid_to_pixel(cell.x, cell.y)
	entity_grid.add_animation(px.x, px.y, "floating_text", die_anim)
	var timer = entity_grid.get_tree().create_timer(0.45) if entity_grid.is_inside_tree() else null
	if timer != null:
		timer.timeout.connect(func():
			if is_instance_valid(die_anim):
				die_anim.queue_free()
		)

func roll_drops():
	var rolled = []
	if OD.Database == null:
		return rolled
	for drop_entry in drops:
		var pct = clamp(int(drop_entry.get("percent", 0)), 0, 100)
		if pct >= 100 or (randi() % 100) < pct:
			var item_def = OD.Database.get_item(str(drop_entry.name))
			if item_def != null:
				rolled.append({
					kind = "item",
					item = item_def
				})
	return rolled

func _tick_spell_cooldowns():
	for key in spell_cooldowns.keys():
		var rem = int(spell_cooldowns[key]) - 1
		if rem <= 0:
			spell_cooldowns.erase(key)
		else:
			spell_cooldowns[key] = rem

func _pick_castable_spell():
	var candidates = []
	for sp_name in spells:
		if int(spell_cooldowns.get(sp_name, 0)) <= 0:
			candidates.append(sp_name)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]

func _step_toward(entity_grid, my_pos, target_pos):
	var best_cell = null
	var best_dist = 999999
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var cand = my_pos + dir
		if not entity_grid.is_walkable(cand.x, cand.y):
			continue
		var d = abs(cand.x - target_pos.x) + abs(cand.y - target_pos.y)
		if d < best_dist:
			best_dist = d
			best_cell = cand
	if best_cell == null:
		var adj_goal = null
		var adj_dist = 999999
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var cand = target_pos + dir
			if entity_grid.is_walkable(cand.x, cand.y):
				var path = entity_grid.find_path(my_pos, cand, { max_visited = 192 })
				if not path.is_empty() and path.size() < adj_dist:
					adj_dist = path.size()
					adj_goal = path[0]
		best_cell = adj_goal
	if best_cell != null:
		var dx = best_cell.x - my_pos.x
		var dy = best_cell.y - my_pos.y
		set_facing(dx, dy)
		entity_grid.move_actor_to(self, best_cell.x, best_cell.y)
		return true
	return false

func _step_away(entity_grid, my_pos, threat_pos):
	var best_cell = null
	var best_dist = abs(my_pos.x - threat_pos.x) + abs(my_pos.y - threat_pos.y)
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var cand = my_pos + dir
		if not entity_grid.is_walkable(cand.x, cand.y):
			continue
		var d = abs(cand.x - threat_pos.x) + abs(cand.y - threat_pos.y)
		if d > best_dist:
			best_dist = d
			best_cell = cand
	if best_cell != null:
		set_facing(best_cell.x - my_pos.x, best_cell.y - my_pos.y)
		entity_grid.move_actor_to(self, best_cell.x, best_cell.y)
		return true
	return false

func _roam_step(entity_grid, my_pos):
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	for dir in dirs:
		var cand = my_pos + dir
		if entity_grid.is_walkable(cand.x, cand.y):
			set_facing(dir.x, dir.y)
			entity_grid.move_actor_to(self, cand.x, cand.y)
			return true
	return false

func step_ai(entity_grid, player_pos, player, dungeon = null):
	if hp <= 0 or entity_grid == null or player_pos == null:
		return "none"
	_tick_spell_cooldowns()
	if has_status_flag("paralyze") or has_status_flag("sleep"):
		return "stunned"
	var pos_raw = get_grid_position()
	if pos_raw == null:
		return "none"
	var my_pos = Vector2i(int(pos_raw.x), int(pos_raw.y))
	var target_pos = Vector2i(int(player_pos.x), int(player_pos.y))
	var cheb_dist = max(abs(target_pos.x - my_pos.x), abs(target_pos.y - my_pos.y))

	if not alerted and cheb_dist <= sight_radius:
		if entity_grid.is_cell_visible(my_pos.x, my_pos.y) or entity_grid._has_clear_los(my_pos, target_pos):
			alerted = true

	if has_status_flag("fear"):
		if _step_away(entity_grid, my_pos, target_pos):
			return "flee"
		return "idle"

	if has_status_flag("confuse"):
		if _roam_step(entity_grid, my_pos):
			return "confused_move"
		return "idle"

	if not is_hostile or has_status_flag("pacify"):
		if (randi() % 100) < 30 and _roam_step(entity_grid, my_pos):
			return "roam"
		return "idle"

	if not alerted:
		if (randi() % 100) < 35 and _roam_step(entity_grid, my_pos):
			return "roam"
		return "idle"

	if cheb_dist == 1 and player != null and is_instance_valid(player):
		set_facing(target_pos.x - my_pos.x, target_pos.y - my_pos.y)
		play_attack_animation()
		play_sfx("attack")
		var res = CombatResolverScript.resolve_attack(self, player, { kind = "melee" })
		if res.hit and res.total_damage > 0:
			if player.has_method("modify_hp"):
				player.modify_hp(-res.total_damage)
			if dungeon != null and dungeon.has_method("on_monster_attack_player"):
				dungeon.on_monster_attack_player(self, res, my_pos, target_pos)
			for oh in on_hit_procs:
				if (randi() % int(oh.one_chance_in)) == 0:
					SpellEngineScript.execute_spell(oh.spell, self, target_pos, {
						entity_grid = entity_grid,
						dungeon = dungeon,
						free_cast = true
					})
		elif dungeon != null and dungeon.has_method("_spawn_floating_text"):
			dungeon._spawn_floating_text(target_pos, "Dodged!", Color(0.75, 0.75, 0.85))
		return "attack"

	if not spells.is_empty() and cheb_dist <= sight_radius and (randi() % 100) < ai_spell_pct:
		var chosen_spell = _pick_castable_spell()
		if chosen_spell != "":
			set_facing(target_pos.x - my_pos.x, target_pos.y - my_pos.y)
			play_cast_animation()
			play_sfx("spell")
			var sp_def = OD.Database.get_spell(chosen_spell) if OD.Database != null else null
			var cd = SpellEngineScript.get_cooldown_turns(sp_def)
			spell_cooldowns[chosen_spell] = max(2, cd)
			SpellEngineScript.execute_spell(chosen_spell, self, target_pos, {
				entity_grid = entity_grid,
				dungeon = dungeon,
				free_cast = true
			})
			return "cast:" + chosen_spell

	if not has_status_flag("lockdown"):
		if _step_toward(entity_grid, my_pos, target_pos):
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

func apply_buff(buff_def, source_spell = ""):
	if buff_def == null or typeof(buff_def) != TYPE_DICTIONARY:
		return false
	var buff_name = str(buff_def.get("name", source_spell))
	var duration = int(buff_def.get("time", buff_def.get("duration", 0)))
	var use_timer = int(buff_def.get("useTimer", buff_def.get("usetimer", 1 if duration > 0 else 0))) == 1
	for existing in active_buffs:
		if str(existing.get("name", "")) == buff_name:
			if use_timer:
				existing["remaining_turns"] = max(1, duration)
			return true
	active_buffs.append({
		name = buff_name,
		use_timer = use_timer,
		remaining_turns = max(1, duration) if use_timer else -1,
		brittle_remaining = int(buff_def.get("brittle", 0)),
		raw = buff_def
	})
	return true

func on_hit_received():
	var ii = 0
	while ii < active_buffs.size():
		var brit = int(active_buffs[ii].get("brittle_remaining", 0))
		if brit > 0:
			brit -= 1
			active_buffs[ii]["brittle_remaining"] = brit
			if brit <= 0:
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

func apply_dot(dot_def):
	if dot_def == null or typeof(dot_def) != TYPE_DICTIONARY:
		return
	active_dots.append(dot_def.duplicate(true))

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
		var rem = int(status_flags[flag_key]) - 1
		if rem <= 0:
			status_flags.erase(flag_key)
		else:
			status_flags[flag_key] = rem
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
