extends RefCounted

const CombatResolverScript = preload("res://script/instance/combat/combat_resolver.gd")
const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")
const DeathManagerScript = preload("res://script/instance/death_manager.gd")

static func get_player_melee_weapon_damage(player):
	if player == null or player.equipment == null:
		return null
	var combined = {}
	var has_weapon = false
	for slot_name in ["weapon_right", "weapon_left"]:
		var item = player.equipment.get(slot_name, null)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var damage_source = item.get("weapon_damage", item)
			for damage_type in CombatResolverScript.ALL_DAMAGE_TYPES:
				if damage_source.has(damage_type):
					has_weapon = true
					combined[damage_type] = int(combined.get(damage_type, 0)) + int(damage_source[damage_type])
	return combined if has_weapon else null

static func handle_enemy_death(dungeon, enemy, grid_position):
	if enemy == null or dungeon == null:
		return
	dungeon._monsters_killed += 1
	var enemy_name = enemy.get("monster_name") if enemy.get("monster_name") != null else "Enemy"
	if enemy.has_method("play_sfx"):
		enemy.play_sfx("die")
	else:
		OD.Audio.play_sfx("large_die")
	var xp_gain = enemy.get_xp_value() if enemy.has_method("get_xp_value") else 10
	dungeon._spawn_floating_text(grid_position, enemy_name + " defeated! +" + str(xp_gain) + " XP", Color(0.45, 0.95, 0.45))
	dungeon._log_event("The " + enemy_name + " is defeated! (+" + str(xp_gain) + " XP)")
	if enemy.has_method("play_die_animation_at"):
		enemy.play_die_animation_at(dungeon._entity_grid, grid_position)
	dungeon.award_xp(xp_gain, grid_position)
	if dungeon._player != null and dungeon._player.has_method("advance_kill_quests"):
		var done_quests = dungeon._player.advance_kill_quests(dungeon._floor_level)
		for completed_quest in done_quests:
			var quest_title = str(completed_quest.get("title", "Quest"))
			dungeon._log_event("Quest Completed: " + quest_title + "!")
			dungeon._spawn_floating_text(grid_position, "Quest Complete!", Color(1.0, 0.88, 0.35))
	if enemy.has_method("roll_drops") and dungeon._entity_grid != null:
		for drop_data in enemy.roll_drops():
			dungeon._entity_grid.add_loot_item(grid_position.x, grid_position.y, drop_data)
	var drop_chance = int(OD.Database.get_tweak("monster loot drop chance", 3))
	if drop_chance > 0 and (randi() % drop_chance) == 0 and dungeon._entity_grid != null:
		var gold_per_level = max(1, int(OD.Database.get_tweak("gold drop per level", 3)))
		var gold_amount = randi_range(1, gold_per_level * max(1, dungeon._floor_level))
		dungeon._entity_grid.add_loot_item(grid_position.x, grid_position.y, { kind = "zorkmids", amount = gold_amount })
	if dungeon._entity_grid != null:
		dungeon._entity_grid.unregister_entity(enemy, grid_position)
	enemy.queue_free()
	if enemy_name == "Lord Dredmor":
		DeathManagerScript.record_high_score(dungeon._player, dungeon._floor_level, "Defeated Lord Dredmor", dungeon._monsters_killed, DeathManagerScript.HIGH_SCORES_PATH, true)
		dungeon._log_event("Victory! You have defeated Lord Dredmor!")

static func resolve_player_attack(dungeon, target, target_cell, options = {}):
	if dungeon == null or dungeon._player == null or target == null:
		return false
	var player = dungeon._player
	var entity_grid = dungeon._entity_grid
	var attack_opts = options.duplicate()
	var kind = str(attack_opts.get("kind", "melee"))
	if kind == "melee" and not attack_opts.has("weapon"):
		var weapon_damage = get_player_melee_weapon_damage(player)
		if weapon_damage != null:
			attack_opts["weapon"] = weapon_damage
		else:
			attack_opts["weapon"] = { crushing = 2 }
	var player_position = player.get_grid_position()
	if player_position != null:
		player.face_towards(target_cell)
	player.play_attack_animation(kind)
	var target_name = str(target.get("monster_name")) if target.get("monster_name") != null else "Enemy"
	var result = CombatResolverScript.resolve_attack(player, target, attack_opts)
	if not result.hit:
		if OD.Audio != null:
			OD.Audio.play_sfx("evade")
		dungeon.spawn_floating_badge(target_cell, "dodge", "Dodged!")
		dungeon._log_event("The " + target_name + " dodges your attack!")
		if result.ammo_recovered and entity_grid != null and attack_opts.has("ammo_item"):
			entity_grid.add_loot_item(target_cell.x, target_cell.y, attack_opts.ammo_item)
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
		dungeon.spawn_floating_badge(target_cell, "crit", "CRIT!")
	if result.blocked:
		tag_suffix += " (Blocked)"
		dungeon.spawn_floating_badge(target_cell, "block", "Blocked!")
	var damage_color = Color(1.0, 0.55, 0.15) if result.critical else Color(1.0, 0.85, 0.25)
	var damage_scale = 1.25 if result.critical else 1.0
	dungeon._spawn_floating_text(target_cell, "-" + str(result.total_damage), damage_color, damage_scale)
	dungeon._log_event("You hit the " + target_name + " for " + str(result.total_damage) + " damage!" + tag_suffix)
	if target.has_method("on_hit_received"):
		target.on_hit_received()
	if player.has_method("on_attack_performed"):
		for proc_spell in player.on_attack_performed():
			SpellEngineScript.execute_spell(proc_spell, player, target_cell, {
				entity_grid = entity_grid,
				dungeon = dungeon,
				free_cast = true
			})
	if result.ammo_recovered and entity_grid != null and attack_opts.has("ammo_item"):
		entity_grid.add_loot_item(target_cell.x, target_cell.y, attack_opts.ammo_item)
	if target.hp <= 0:
		handle_enemy_death(dungeon, target, target_cell)
		return true
	if result.countered and player_position != null:
		var counter_result = CombatResolverScript.resolve_attack(target, player, { kind = "melee", is_counter = true })
		if counter_result.hit and counter_result.total_damage > 0:
			player.modify_hp(-counter_result.total_damage, str(target.get("monster_name")))
			var player_cell = Vector2i(int(player_position.x), int(player_position.y))
			dungeon.spawn_floating_badge(player_cell, "counter", "Counter!")
			dungeon._spawn_floating_text(player_cell, "-" + str(counter_result.total_damage), Color(1.0, 0.3, 0.3))
			dungeon._log_event("The " + target_name + " counters for " + str(counter_result.total_damage) + " damage!")
			dungeon._trigger_player_hit_procs(target_cell)
	return true
