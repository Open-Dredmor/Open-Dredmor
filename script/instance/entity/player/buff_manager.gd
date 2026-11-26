extends RefCounted

static func get_primary_bonus(player, stat_key):
	var total = 0
	for buff in player.active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("primary_bonuses", {}).get(stat_key, 0)) * stacks
	return total

static func get_secondary_bonus(player, stat_key):
	var total = 0
	for buff in player.active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("secondary_bonuses", {}).get(stat_key, 0)) * stacks
	return total

static func get_resistance_bonus(player, damage_type):
	var total = 0
	for buff in player.active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("resist_bonuses", {}).get(damage_type, 0)) * stacks
	return total

static func get_damage_bonus(player, damage_type):
	var total = 0
	for buff in player.active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("damage_bonuses", {}).get(damage_type, 0)) * stacks
	return total

static func has_buff(player, buff_name):
	var target_name = str(buff_name)
	for buff in player.active_buffs:
		if str(buff.get("name", "")) == target_name:
			return true
	return false

static func remove_buff_by_name(player, buff_name):
	var target_name = str(buff_name)
	var removed = false
	var ii = 0
	while ii < player.active_buffs.size():
		if str(player.active_buffs[ii].get("name", "")) == target_name:
			player.active_buffs.remove_at(ii)
			removed = true
		else:
			ii += 1
	if removed:
		player.recalculate_stats()
		player.buffs_changed.emit()
	return removed

static func dismiss_buff(player, buff_name):
	var target_name = str(buff_name)
	for buff in player.active_buffs:
		if str(buff.get("name", "")) == target_name:
			if bool(buff.get("removable", false)) and not bool(buff.get("bad", false)):
				return remove_buff_by_name(player, target_name)
			return false
	return false

static func _extract_buff_array(buff_definition, lower_key, camel_key):
	var items = []
	if buff_definition.has(lower_key):
		items.append_array(OD.DataStructure.arrayify(buff_definition.get(lower_key)))
	if buff_definition.has(camel_key):
		items.append_array(OD.DataStructure.arrayify(buff_definition.get(camel_key)))
	return items

static func apply_buff(player, buff_definition, source_spell = ""):
	if buff_definition == null or typeof(buff_definition) != TYPE_DICTIONARY:
		return false
	var buff_name = str(buff_definition.get("name", source_spell))
	var duration = int(buff_definition.get("time", buff_definition.get("duration", 0)))
	var use_timer = int(buff_definition.get("useTimer", buff_definition.get("usetimer", 1 if duration > 0 else 0))) == 1
	var allow_stack = int(buff_definition.get("allowstacking", buff_definition.get("allowStacking", buff_definition.get("stackable", 0)))) == 1
	var max_stacks = max(1, int(buff_definition.get("stacksize", 1)))
	var brittle_count = int(buff_definition.get("brittle", 0))
	var attacks_count = int(buff_definition.get("attacks", 0))

	var primary_bonuses = {}
	for primary_item in _extract_buff_array(buff_definition, "primarybuff", "primaryBuff"):
		if typeof(primary_item) == TYPE_DICTIONARY and primary_item.has("id"):
			var index = int(primary_item.id)
			if index >= 0 and index < player.PRIMARY_STAT_KEYS.size():
				var key = player.PRIMARY_STAT_KEYS[index]
				primary_bonuses[key] = int(primary_bonuses.get(key, 0)) + int(primary_item.get("amount", 0))

	var secondary_bonuses = {}
	for secondary_item in _extract_buff_array(buff_definition, "secondarybuff", "secondaryBuff"):
		if typeof(secondary_item) == TYPE_DICTIONARY and secondary_item.has("id"):
			var secondary_id = int(secondary_item.id)
			if player.SECONDARY_STAT_BY_ID.has(secondary_id):
				var key = player.SECONDARY_STAT_BY_ID[secondary_id]
				secondary_bonuses[key] = int(secondary_bonuses.get(key, 0)) + int(secondary_item.get("amount", 0))

	for sight_item in OD.DataStructure.arrayify(buff_definition.get("sightbuff", [])):
		if typeof(sight_item) == TYPE_DICTIONARY and sight_item.has("amount"):
			secondary_bonuses["visual_sight_radius"] = int(secondary_bonuses.get("visual_sight_radius", 0)) + int(sight_item.amount)

	var resist_bonuses = {}
	for resist_item in _extract_buff_array(buff_definition, "resistbuff", "resistBuff"):
		if typeof(resist_item) == TYPE_DICTIONARY:
			for damage_type in player.DAMAGE_TYPES:
				if resist_item.has(damage_type):
					resist_bonuses[damage_type] = int(resist_bonuses.get(damage_type, 0)) + int(resist_item[damage_type])

	var damage_bonuses = {}
	for damage_item in _extract_buff_array(buff_definition, "damagebuff", "damageBuff"):
		if typeof(damage_item) == TYPE_DICTIONARY:
			for damage_type in player.DAMAGE_TYPES:
				if damage_item.has(damage_type):
					damage_bonuses[damage_type] = int(damage_bonuses.get(damage_type, 0)) + int(damage_item[damage_type])

	var target_hit_procs = []
	for hit_item in _extract_buff_array(buff_definition, "targethiteffectbuff", "targetHitEffectBuff"):
		if typeof(hit_item) == TYPE_DICTIONARY and hit_item.has("name"):
			target_hit_procs.append({
				name = str(hit_item.name),
				percentage = int(hit_item.get("percentage", 100))
			})

	var player_hit_procs = []
	for player_hit_item in _extract_buff_array(buff_definition, "playerhiteffectbuff", "playerHitEffectBuff"):
		if typeof(player_hit_item) == TYPE_DICTIONARY and player_hit_item.has("name"):
			player_hit_procs.append({
				name = str(player_hit_item.name),
				percentage = int(player_hit_item.get("percentage", 100))
			})

	var description_text = ""
	if buff_definition.has("description") and typeof(buff_definition.description) == TYPE_DICTIONARY and buff_definition.description.has("text"):
		description_text = str(buff_definition.description.text)

	for existing in player.active_buffs:
		if str(existing.get("name", "")) == buff_name:
			if allow_stack and int(existing.get("stacks", 1)) < max_stacks:
				existing["stacks"] = int(existing.get("stacks", 1)) + 1
			if use_timer:
				existing["remaining_turns"] = max(1, duration)
			if brittle_count > 0:
				existing["brittle_remaining"] = brittle_count
			if attacks_count > 0:
				existing["attacks_remaining"] = attacks_count
			if int(buff_definition.get("hp_per_turn", 0)) != 0:
				existing["hp_per_turn"] = int(buff_definition.get("hp_per_turn", 0))
			if int(buff_definition.get("mp_per_turn", 0)) != 0:
				existing["mp_per_turn"] = int(buff_definition.get("mp_per_turn", 0))
			player.recalculate_stats()
			player.buffs_changed.emit()
			return true

	player.active_buffs.append({
		name = buff_name,
		description = description_text,
		icon = str(buff_definition.get("smallicon", buff_definition.get("icon", ""))),
		large_icon = str(buff_definition.get("icon", "")),
		bad = int(buff_definition.get("bad", 0)) == 1,
		removable = int(buff_definition.get("removable", 0)) == 1,
		destroy_on_move = int(buff_definition.get("destroyonmove", 0)) == 1,
		use_timer = use_timer,
		remaining_turns = max(1, duration) if use_timer else -1,
		brittle_remaining = brittle_count,
		attacks_remaining = attacks_count,
		stacks = 1,
		mana_upkeep = int(buff_definition.get("manaUpkeep", buff_definition.get("manaupkeep", 0))),
		zorkmid_upkeep = int(buff_definition.get("zorkmidUpkeep", 0)),
		hp_per_turn = int(buff_definition.get("hp_per_turn", 0)),
		mp_per_turn = int(buff_definition.get("mp_per_turn", 0)),
		primary_bonuses = primary_bonuses,
		secondary_bonuses = secondary_bonuses,
		resist_bonuses = resist_bonuses,
		damage_bonuses = damage_bonuses,
		target_hit_procs = target_hit_procs,
		player_hit_procs = player_hit_procs,
		raw = buff_definition
	})
	player.recalculate_stats()
	player.buffs_changed.emit()
	return true

static func on_attack_performed(player):
	var procs = []
	var changed = false
	var ii = 0
	while ii < player.active_buffs.size():
		var buff = player.active_buffs[ii]
		for proc in buff.get("target_hit_procs", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
		var attack_remaining = int(buff.get("attacks_remaining", 0))
		if attack_remaining > 0:
			attack_remaining -= 1
			buff["attacks_remaining"] = attack_remaining
			changed = true
			if attack_remaining <= 0:
				player.active_buffs.remove_at(ii)
				continue
		ii += 1
	for slot_name in player.PASSIVE_EQUIPMENT_SLOTS:
		var item = player.equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		for proc in item.get("target_hit_effects", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
	if changed:
		player.recalculate_stats()
		player.buffs_changed.emit()
	return procs

static func on_hit_received(player):
	var procs = []
	var changed = false
	var ii = 0
	while ii < player.active_buffs.size():
		var buff = player.active_buffs[ii]
		for proc in buff.get("player_hit_procs", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
		var brittle_remaining = int(buff.get("brittle_remaining", 0))
		if brittle_remaining > 0:
			brittle_remaining -= 1
			buff["brittle_remaining"] = brittle_remaining
			changed = true
			if brittle_remaining <= 0:
				player.active_buffs.remove_at(ii)
				continue
		ii += 1
	for slot_name in player.PASSIVE_EQUIPMENT_SLOTS:
		var item = player.equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		for proc in item.get("player_hit_effects", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
	if changed:
		player.recalculate_stats()
		player.buffs_changed.emit()
	return procs

static func on_moved(player):
	var changed = false
	var ii = 0
	while ii < player.active_buffs.size():
		if bool(player.active_buffs[ii].get("destroy_on_move", false)):
			player.active_buffs.remove_at(ii)
			changed = true
		else:
			ii += 1
	if changed:
		player.recalculate_stats()
		player.buffs_changed.emit()

static func tick_status_effects(player):
	var ticked = 0
	var buff_changed = false
	var ii = 0
	while ii < player.active_buffs.size():
		var buff = player.active_buffs[ii]
		ticked += 1
		var upkeep = int(buff.get("mana_upkeep", 0))
		if upkeep > 0:
			if player.mp >= upkeep:
				player.modify_mp(-upkeep)
			else:
				player.active_buffs.remove_at(ii)
				buff_changed = true
				continue
		var zorkmid_upkeep = int(buff.get("zorkmid_upkeep", 0))
		if zorkmid_upkeep > 0:
			if player.get_zorkmids() >= zorkmid_upkeep:
				player.add_zorkmids(-zorkmid_upkeep)
			else:
				player.active_buffs.remove_at(ii)
				buff_changed = true
				continue
		var hp_regen = int(buff.get("hp_per_turn", 0))
		if hp_regen != 0:
			player.modify_hp(hp_regen)
		var mp_regen = int(buff.get("mp_per_turn", 0))
		if mp_regen != 0:
			player.modify_mp(mp_regen)
		if buff.get("use_timer", false):
			buff["remaining_turns"] = int(buff.get("remaining_turns", 1)) - 1
			if buff["remaining_turns"] <= 0:
				player.active_buffs.remove_at(ii)
				buff_changed = true
				continue
		ii += 1
	if buff_changed:
		player.recalculate_stats()
	for flag_key in player.status_flags.keys():
		ticked += 1
		var remaining = int(player.status_flags[flag_key]) - 1
		if remaining <= 0:
			player.status_flags.erase(flag_key)
		else:
			player.status_flags[flag_key] = remaining
	var jj = 0
	while jj < player.active_dots.size():
		var dot = player.active_dots[jj]
		ticked += 1
		if dot.has("on_tick") and dot.on_tick is Callable:
			dot.on_tick.call(player, dot)
		dot["remaining_turns"] = int(dot.get("remaining_turns", 1)) - 1
		if dot["remaining_turns"] <= 0:
			player.active_dots.remove_at(jj)
		else:
			jj += 1
	if ticked > 0 or buff_changed:
		player.buffs_changed.emit()
	return ticked
