extends "res://script/instance/entity/entity.gd"

class_name PlayerCharacter

signal stats_changed
signal hp_changed(current_hp, max_hp)
signal mp_changed(current_mp, max_mp)
signal xp_changed(current_xp, xp_to_next, current_level)
signal zorkmids_changed(amount)

const PRIMARY_STAT_KEYS = [
	"burliness",
	"sagacity",
	"nimbleness",
	"caddishness",
	"savvy",
	"stubbornness"
]

const SECONDARY_STAT_BY_ID = {
	0: "hp_max",
	1: "mp_max",
	2: "melee_power",
	3: "magic_power",
	4: "crit_chance",
	5: "haywire_chance",
	6: "dodge_chance",
	7: "block_chance",
	8: "counter_chance",
	9: "enemy_dodge_reduction",
	10: "armour_absorption",
	11: "magic_resistance",
	12: "sneakiness",
	13: "health_regen_bonus",
	14: "mana_regen_bonus",
	15: "magic_reflect",
	16: "trap_affinity",
	17: "trap_sight_radius",
	18: "visual_sight_radius",
	19: "smithing_level",
	20: "tinkering_level",
	21: "alchemy_level",
	22: "resist_bonus",
	23: "wandcrafting_level"
}

const DAMAGE_TYPES = [
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

const EQUIPMENT_SLOTS = [
	"head",
	"chest",
	"legs",
	"feet",
	"hands",
	"belt",
	"neck",
	"ring_left",
	"ring_right",
	"weapon_left",
	"weapon_right",
	"missile_weapon"
]

var entity_kind = "player"

var animations = {}
var current_animation = null
var last_delta_x = 0
var last_delta_y = 0
var sight_radius = 8

var character_name = ""
var hero_kind = "hero"

var hp = 40
var max_hp = 40
var mp = 30
var max_mp = 30
var xp = 0
var xp_to_next_level = 190
var level = 1
var zorkmids_ref = { value = 150 }

var warrior_level = 0
var rogue_level = 0
var wizard_level = 0

var base_primary_stats = {}
var bonus_primary_stats = {}
var primary_stats = {}

var bonus_secondary_stats = {}
var secondary_stats = {}

var damage_bonuses = {}
var resistances = {}

var equipment = {}

func _init_stat_tables():
	base_primary_stats.clear()
	bonus_primary_stats.clear()
	primary_stats.clear()
	for stat_key in PRIMARY_STAT_KEYS:
		base_primary_stats[stat_key] = 10
		bonus_primary_stats[stat_key] = 0
		primary_stats[stat_key] = 10

	bonus_secondary_stats.clear()
	secondary_stats.clear()
	for stat_id in SECONDARY_STAT_BY_ID:
		var stat_key = SECONDARY_STAT_BY_ID[stat_id]
		bonus_secondary_stats[stat_key] = 0
		secondary_stats[stat_key] = 0

	damage_bonuses.clear()
	resistances.clear()
	for damage_type in DAMAGE_TYPES:
		damage_bonuses[damage_type] = 0
		resistances[damage_type] = 0

	equipment.clear()
	for slot_name in EQUIPMENT_SLOTS:
		equipment[slot_name] = null

func recalculate_stats():
	var prev_max_hp = max_hp
	var prev_max_mp = max_mp

	for stat_key in PRIMARY_STAT_KEYS:
		primary_stats[stat_key] = int(base_primary_stats.get(stat_key, 10)) + int(bonus_primary_stats.get(stat_key, 0))

	var burliness = primary_stats["burliness"]
	var sagacity = primary_stats["sagacity"]
	var nimbleness = primary_stats["nimbleness"]
	var caddishness = primary_stats["caddishness"]
	var savvy = primary_stats["savvy"]
	var stubbornness = primary_stats["stubbornness"]

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

	for stat_id in SECONDARY_STAT_BY_ID:
		var stat_key = SECONDARY_STAT_BY_ID[stat_id]
		var base_val = int(derived.get(stat_key, 0))
		var bonus_val = int(bonus_secondary_stats.get(stat_key, 0))
		secondary_stats[stat_key] = base_val + bonus_val

	max_hp = max(1, int(secondary_stats["hp_max"]))
	max_mp = max(0, int(secondary_stats["mp_max"]))
	sight_radius = max(1, int(secondary_stats["visual_sight_radius"]))

	if prev_max_hp > 0 and max_hp != prev_max_hp:
		hp = clamp(hp + max(0, max_hp - prev_max_hp), 0, max_hp)
	else:
		hp = clamp(hp, 0, max_hp)

	if prev_max_mp > 0 and max_mp != prev_max_mp:
		mp = clamp(mp + max(0, max_mp - prev_max_mp), 0, max_mp)
	else:
		mp = clamp(mp, 0, max_mp)

	stats_changed.emit()

func get_primary_stat(stat_key):
	return int(primary_stats.get(stat_key, 0))

func get_primary_stat_by_id(stat_id):
	var idx = int(stat_id)
	if idx < 0 or idx >= PRIMARY_STAT_KEYS.size():
		return 0
	return get_primary_stat(PRIMARY_STAT_KEYS[idx])

func add_primary_bonus(stat_key, amount):
	if not bonus_primary_stats.has(stat_key):
		return
	bonus_primary_stats[stat_key] += int(amount)
	recalculate_stats()

func get_secondary_stat(stat_key):
	return int(secondary_stats.get(stat_key, 0))

func get_secondary_stat_by_id(stat_id):
	var idx = int(stat_id)
	if not SECONDARY_STAT_BY_ID.has(idx):
		return 0
	return get_secondary_stat(SECONDARY_STAT_BY_ID[idx])

func add_secondary_bonus(stat_key, amount):
	if not bonus_secondary_stats.has(stat_key):
		return
	bonus_secondary_stats[stat_key] += int(amount)
	recalculate_stats()

func get_resistance(damage_type):
	return int(resistances.get(damage_type, 0))

func add_resistance(damage_type, amount):
	if not resistances.has(damage_type):
		return
	resistances[damage_type] += int(amount)
	stats_changed.emit()

func get_damage_bonus(damage_type):
	return int(damage_bonuses.get(damage_type, 0))

func add_damage_bonus(damage_type, amount):
	if not damage_bonuses.has(damage_type):
		return
	damage_bonuses[damage_type] += int(amount)
	stats_changed.emit()

func set_hp(value):
	hp = clamp(int(value), 0, max_hp)
	hp_changed.emit(hp, max_hp)

func modify_hp(delta_amount):
	set_hp(hp + int(delta_amount))

func set_mp(value):
	mp = clamp(int(value), 0, max_mp)
	mp_changed.emit(mp, max_mp)

func modify_mp(delta_amount):
	set_mp(mp + int(delta_amount))

func get_zorkmids():
	return int(zorkmids_ref.value)

func get_zorkmids_ref():
	return zorkmids_ref

func set_zorkmids(amount):
	zorkmids_ref.value = max(0, int(amount))
	zorkmids_changed.emit(zorkmids_ref.value)

func add_zorkmids(delta_amount):
	set_zorkmids(zorkmids_ref.value + int(delta_amount))

func add_xp(amount):
	xp = max(0, xp + int(amount))
	var leveled_up = false
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = _compute_xp_threshold(level)
		leveled_up = true
	xp_changed.emit(xp, xp_to_next_level, level)
	return leveled_up

func _compute_xp_threshold(target_level):
	var exp_n = 190
	if OD.Database != null:
		exp_n = max(1, int(OD.Database.get_tweak("experience n", 190)))
	return target_level * exp_n

func get_sight_radius():
	return sight_radius

func set_sight_radius(radius):
	var clamped = max(1, int(radius))
	bonus_secondary_stats["visual_sight_radius"] += clamped - sight_radius
	recalculate_stats()

func update_animation(delta_x, delta_y):
	if animations.is_empty():
		return
	var next_anim = current_animation
	if delta_x != 0:
		next_anim = animations.move.left if delta_x < 0 else animations.move.right
	elif delta_y != 0:
		next_anim = animations.move.up if delta_y < 0 else animations.move.down
	if next_anim != current_animation:
		if current_animation != null:
			current_animation.visible = false
		current_animation = next_anim
		if current_animation != null:
			current_animation.visible = true
	last_delta_x = delta_x
	last_delta_y = delta_y

func idle():
	if animations.is_empty():
		return
	if current_animation != null:
		current_animation.visible = false
	if last_delta_x != 0:
		if last_delta_x < 0:
			current_animation = animations.idle.left
		else:
			current_animation = animations.idle.right
	elif last_delta_y != 0:
		if last_delta_y < 0:
			current_animation = animations.idle.up
		else:
			current_animation = animations.idle.down
	if current_animation != null:
		current_animation.visible = true

func _load_sprite_animations():
	var sprite_paths = OD.Resources.paths.player.heroine if hero_kind == "heroine" else OD.Resources.paths.player.hero
	animations.move = {
		left = OD.Load.animation(sprite_paths.move.left),
		right = OD.Load.animation(sprite_paths.move.right),
		up = OD.Load.animation(sprite_paths.move.up),
		down = OD.Load.animation(sprite_paths.move.down)
	}
	animations.idle = {
		left = OD.Load.animation(sprite_paths.idle.left),
		right = OD.Load.animation(sprite_paths.idle.right),
		up = OD.Load.animation(sprite_paths.idle.up),
		down = OD.Load.animation(sprite_paths.idle.down)
	}
	for group in [animations.move, animations.idle]:
		for direction in group.values():
			direction.visible = false
			if direction.is_tall():
				direction.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
			add_child(direction)
	current_animation = animations.idle.down
	current_animation.visible = true

func init():
	_init_stat_tables()
	var settings = OD.DungeonSettings.get_settings() if OD.DungeonSettings != null else {}
	if settings != null:
		var chosen_hero = settings.get("hero", "hero")
		hero_kind = "heroine" if chosen_hero == "heroine" else "hero"
		character_name = str(settings.get("name", ""))
	else:
		hero_kind = "hero"
		character_name = ""

	level = 1
	xp = 0
	xp_to_next_level = _compute_xp_threshold(level)
	zorkmids_ref = { value = 150 }

	recalculate_stats()
	hp = max_hp
	mp = max_mp

	_load_sprite_animations()
