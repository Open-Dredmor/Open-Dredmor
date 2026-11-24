extends RefCounted

class_name CombatResolver

const MUNDANE_DAMAGE_TYPES = [
	"crushing",
	"slashing",
	"blasting"
]

const ALL_DAMAGE_TYPES = [
	"acidic",
	"aethereal",
	"asphyxiative",
	"blasting",
	"conflagratory",
	"crushing",
	"existential",
	"hyperborean",
	"necromantic",
	"piercing",
	"putrefying",
	"righteous",
	"slashing",
	"toxic",
	"transmutative",
	"voltaic"
]

static func _get_tweak_int(tweak_name, default_val):
	if OD.Database != null:
		return int(OD.Database.get_tweak(tweak_name, default_val))
	return int(default_val)

static func _get_stat(actor, stat_key, default_val = 0):
	if actor == null:
		return default_val
	if actor.has_method("get_secondary_stat"):
		return int(actor.get_secondary_stat(stat_key))
	if actor.get(stat_key) != null:
		return int(actor.get(stat_key))
	return default_val

static func _get_resistance(actor, damage_type):
	if actor == null:
		return 0
	if actor.has_method("get_resistance"):
		return int(actor.get_resistance(damage_type))
	if actor.get("resistances") != null and typeof(actor.resistances) == TYPE_DICTIONARY:
		return int(actor.resistances.get(damage_type, 0))
	return 0

static func _get_damage_bonus(actor, damage_type):
	if actor == null:
		return 0
	if actor.has_method("get_damage_bonus"):
		return int(actor.get_damage_bonus(damage_type))
	if actor.get("damage_bonuses") != null and typeof(actor.damage_bonuses) == TYPE_DICTIONARY:
		return int(actor.damage_bonuses.get(damage_type, 0))
	return 0

static func _extract_damage_map(weapon_or_attack):
	var dmg_map = {}
	for dmg_type in ALL_DAMAGE_TYPES:
		dmg_map[dmg_type] = 0
	if weapon_or_attack == null or typeof(weapon_or_attack) != TYPE_DICTIONARY:
		return dmg_map
	for dmg_type in ALL_DAMAGE_TYPES:
		if weapon_or_attack.has(dmg_type):
			dmg_map[dmg_type] += int(weapon_or_attack[dmg_type])
	return dmg_map

static func _roll_percent(chance_percent):
	var clamped = clamp(int(chance_percent), 0, 100)
	if clamped <= 0:
		return false
	if clamped >= 100:
		return true
	return (randi() % 100) < clamped

static func resolve_attack(attacker, defender, options = {}):
	var attack_kind = str(options.get("kind", "melee"))
	var weapon_data = options.get("weapon", null)
	var ammo_data = options.get("ammo", null)
	var force_hit = bool(options.get("force_hit", false))

	var dodge_chance = _get_stat(defender, "dodge_chance", 0)
	var enemy_dodge_reduction = _get_stat(attacker, "enemy_dodge_reduction", 0)
	var effective_dodge = max(0, dodge_chance - enemy_dodge_reduction)

	if not force_hit and attack_kind != "spell" and _roll_percent(effective_dodge):
		var miss_drop = false
		if attack_kind == "bolt":
			miss_drop = _roll_percent(_get_tweak_int("miss ammo drop percent", 10))
		elif attack_kind == "thrown":
			miss_drop = _roll_percent(_get_tweak_int("hit thrown drop percent", 35))
		return {
			hit = false,
			dodged = true,
			blocked = false,
			critical = false,
			haywire = false,
			countered = false,
			total_damage = 0,
			damage_breakdown = {},
			ammo_recovered = miss_drop,
			attack_kind = attack_kind
		}

	var dmg_map = {}
	for dmg_type in ALL_DAMAGE_TYPES:
		dmg_map[dmg_type] = 0

	if weapon_data != null:
		var w_map = _extract_damage_map(weapon_data)
		for dmg_type in ALL_DAMAGE_TYPES:
			dmg_map[dmg_type] += w_map[dmg_type]
	if ammo_data != null:
		var a_map = _extract_damage_map(ammo_data)
		for dmg_type in ALL_DAMAGE_TYPES:
			dmg_map[dmg_type] += a_map[dmg_type]

	if options.has("damage_map") and typeof(options.damage_map) == TYPE_DICTIONARY:
		for dmg_type in ALL_DAMAGE_TYPES:
			if options.damage_map.has(dmg_type):
				dmg_map[dmg_type] += int(options.damage_map[dmg_type])

	if attacker != null and attack_kind == "melee":
		if weapon_data == null and not options.has("damage_map"):
			if attacker.get("damage_profile") != null and typeof(attacker.damage_profile) == TYPE_DICTIONARY:
				for dmg_type in ALL_DAMAGE_TYPES:
					dmg_map[dmg_type] += int(attacker.damage_profile.get(dmg_type, 0))
			elif attacker.get("attack_damage") != null:
				dmg_map["crushing"] += int(attacker.attack_damage)
			else:
				dmg_map["crushing"] += 2
		for dmg_type in ALL_DAMAGE_TYPES:
			dmg_map[dmg_type] += _get_damage_bonus(attacker, dmg_type)
		var melee_power = _get_stat(attacker, "melee_power", 0)
		dmg_map["crushing"] += max(0, melee_power)
	elif attacker != null and attack_kind == "thrown":
		for dmg_type in ALL_DAMAGE_TYPES:
			dmg_map[dmg_type] += _get_damage_bonus(attacker, dmg_type)
		var thrown_power = _get_stat(attacker, "melee_power", 0)
		dmg_map["crushing"] += max(0, thrown_power)
	elif attacker != null and attack_kind == "spell":
		var magic_power = _get_stat(attacker, "magic_power", 0)
		var scale_factor = float(options.get("magic_scale", 0.35))
		var bonus_magic = int(round(float(magic_power) * scale_factor))
		if bonus_magic > 0:
			var primary_type = str(options.get("primary_damage_type", "aethereal"))
			if dmg_map.has(primary_type):
				dmg_map[primary_type] += bonus_magic

	var is_critical = false
	var is_haywire = false
	if attack_kind == "spell":
		is_haywire = _roll_percent(_get_stat(attacker, "haywire_chance", 0))
	else:
		is_critical = _roll_percent(_get_stat(attacker, "crit_chance", 0))

	if is_critical:
		for dmg_type in ALL_DAMAGE_TYPES:
			dmg_map[dmg_type] *= 2
	elif is_haywire:
		for dmg_type in ALL_DAMAGE_TYPES:
			dmg_map[dmg_type] = int(ceil(float(dmg_map[dmg_type]) * 1.5))

	var is_blocked = false
	if attack_kind != "spell":
		is_blocked = _roll_percent(_get_stat(defender, "block_chance", 0))

	var armour_absorption = _get_stat(defender, "armour_absorption", 0)
	var magic_resistance = _get_stat(defender, "magic_resistance", 0)

	var remaining_armour = max(0, armour_absorption)
	var total_damage = 0
	var breakdown = {}

	for dmg_type in ALL_DAMAGE_TYPES:
		var raw_amount = int(dmg_map[dmg_type])
		if raw_amount <= 0:
			continue
		var after_armour = raw_amount
		if MUNDANE_DAMAGE_TYPES.has(dmg_type):
			var absorbed = min(after_armour, remaining_armour)
			after_armour -= absorbed
			remaining_armour -= absorbed
		if is_blocked and MUNDANE_DAMAGE_TYPES.has(dmg_type):
			after_armour = int(floor(float(after_armour) * 0.5))
		var resist = _get_resistance(defender, dmg_type)
		var final_amount = max(0, after_armour - resist)
		if attack_kind == "spell" and magic_resistance > 0 and final_amount > 0:
			if _roll_percent(min(75, magic_resistance)):
				final_amount = int(floor(float(final_amount) * 0.5))
		if final_amount > 0:
			breakdown[dmg_type] = final_amount
			total_damage += final_amount

	var ammo_recovered = false
	if attack_kind == "bolt":
		ammo_recovered = _roll_percent(_get_tweak_int("hit ammo drop percent", 40))
	elif attack_kind == "thrown":
		ammo_recovered = _roll_percent(_get_tweak_int("hit thrown drop percent", 35))

	var can_counter = attack_kind == "melee" and not bool(options.get("is_counter", false))
	var countered = false
	if can_counter and defender != null:
		var def_hp = int(defender.get("hp")) if defender.get("hp") != null else 0
		if def_hp - total_damage > 0:
			countered = _roll_percent(_get_stat(defender, "counter_chance", 0))

	return {
		hit = true,
		dodged = false,
		blocked = is_blocked,
		critical = is_critical,
		haywire = is_haywire,
		countered = countered,
		total_damage = total_damage,
		damage_breakdown = breakdown,
		ammo_recovered = ammo_recovered,
		attack_kind = attack_kind
	}
