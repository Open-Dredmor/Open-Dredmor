extends RefCounted

static func init_tables(player):
	player.base_primary_stats.clear()
	player.bonus_primary_stats.clear()
	player.primary_stats.clear()
	for stat_key in player.PRIMARY_STAT_KEYS:
		player.base_primary_stats[stat_key] = 10
		player.bonus_primary_stats[stat_key] = 0
		player.primary_stats[stat_key] = 10

	player.bonus_secondary_stats.clear()
	player.secondary_stats.clear()
	for stat_id in player.SECONDARY_STAT_BY_ID:
		var stat_key = player.SECONDARY_STAT_BY_ID[stat_id]
		player.bonus_secondary_stats[stat_key] = 0
		player.secondary_stats[stat_key] = 0

	player.damage_bonuses.clear()
	player.resistances.clear()
	for damage_type in player.DAMAGE_TYPES:
		player.damage_bonuses[damage_type] = 0
		player.resistances[damage_type] = 0

	player.equipment.clear()
	for slot_name in player.EQUIPMENT_SLOTS:
		player.equipment[slot_name] = null

	player.inventory.clear()
	for ii in range(player.INVENTORY_SIZE):
		player.inventory.append(null)

static func recalculate(player):
	var previous_max_hp = player.max_hp
	var previous_max_mp = player.max_mp

	for stat_key in player.PRIMARY_STAT_KEYS:
		player.primary_stats[stat_key] = int(player.base_primary_stats.get(stat_key, 10)) + int(player.bonus_primary_stats.get(stat_key, 0)) + player._get_buff_primary_bonus(stat_key) + player._get_equipment_primary_bonus(stat_key)

	var burliness = player.primary_stats["burliness"]
	var sagacity = player.primary_stats["sagacity"]
	var nimbleness = player.primary_stats["nimbleness"]
	var caddishness = player.primary_stats["caddishness"]
	var savvy = player.primary_stats["savvy"]
	var stubbornness = player.primary_stats["stubbornness"]

	var derived = {
		hp_max = 20 + burliness * 2,
		mp_max = 10 + sagacity * 2,
		melee_power = int(floor(burliness / 2.0)),
		magic_power = int(floor(sagacity / 2.0)),
		crit_chance = int(floor(caddishness / 2.0)),
		haywire_chance = int(floor(savvy / 2.0)),
		dodge_chance = int(floor(nimbleness / 2.0)),
		block_chance = int(floor((burliness + stubbornness) / 4.0)),
		counter_chance = int(floor((nimbleness + caddishness) / 4.0)),
		enemy_dodge_reduction = int(floor(nimbleness / 3.0)),
		armour_absorption = 0,
		magic_resistance = int(floor(stubbornness / 2.0)),
		sneakiness = int(floor((nimbleness + savvy) / 2.0)),
		health_regen_bonus = 0,
		mana_regen_bonus = 0,
		magic_reflect = 0,
		trap_affinity = 0,
		trap_sight_radius = 1,
		visual_sight_radius = 8,
		smithing_level = 0,
		tinkering_level = 0,
		alchemy_level = 0,
		resist_bonus = 0,
		wandcrafting_level = 0
	}

	for stat_id in player.SECONDARY_STAT_BY_ID:
		var stat_key = player.SECONDARY_STAT_BY_ID[stat_id]
		var base_value = int(derived.get(stat_key, 0))
		var bonus_value = int(player.bonus_secondary_stats.get(stat_key, 0))
		var buff_value = player._get_buff_secondary_bonus(stat_key)
		var equip_value = player._get_equipment_secondary_bonus(stat_key)
		player.secondary_stats[stat_key] = base_value + bonus_value + buff_value + equip_value

	player.max_hp = max(1, int(player.secondary_stats["hp_max"]))
	player.max_mp = max(0, int(player.secondary_stats["mp_max"]))
	player.sight_radius = max(1, int(player.secondary_stats["visual_sight_radius"]))

	if previous_max_hp > 0 and player.max_hp != previous_max_hp:
		player.hp = clamp(player.hp + max(0, player.max_hp - previous_max_hp), 0, player.max_hp)
	else:
		player.hp = clamp(player.hp, 0, player.max_hp)

	if previous_max_mp > 0 and player.max_mp != previous_max_mp:
		player.mp = clamp(player.mp + max(0, player.max_mp - previous_max_mp), 0, player.max_mp)
	else:
		player.mp = clamp(player.mp, 0, player.max_mp)

	player.stats_changed.emit()
