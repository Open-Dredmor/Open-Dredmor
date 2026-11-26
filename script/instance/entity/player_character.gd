extends "res://script/instance/entity/entity.gd"

class_name PlayerCharacter

signal stats_changed
signal hp_changed(current_hp, max_hp)
signal mp_changed(current_mp, max_mp)
signal xp_changed(current_xp, xp_to_next, current_level)
signal leveled_up(new_level, skill_points_available)
signal skills_changed
signal skill_unlocked(skill_id, level_entry)
signal zorkmids_changed(amount)
signal buffs_changed
signal inventory_changed
signal equipment_changed
signal belt_changed
signal quests_changed
signal died(cause_of_death)

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
	"weapon_right",
	"weapon_left",
	"missile_weapon",
	"bolts",
	"thrown",
	"head",
	"chest",
	"legs",
	"feet",
	"hands",
	"ring_left",
	"ring_right",
	"neck",
	"belt"
]

const PASSIVE_EQUIPMENT_SLOTS = [
	"weapon_right",
	"weapon_left",
	"missile_weapon",
	"head",
	"chest",
	"legs",
	"feet",
	"hands",
	"ring_left",
	"ring_right",
	"neck",
	"belt"
]

const INVENTORY_COLS = 8
const INVENTORY_ROWS = 6
const INVENTORY_SIZE = 48

var entity_kind = "player"

var animations = {}
var current_animation = null
var last_delta_x = 0
var last_delta_y = 0
var sight_radius = 8
var _action_animation_token = 0

var character_name = ""
var hero_kind = "hero"

var hp = 40
var max_hp = 40
var mp = 30
var max_mp = 30
var is_dead = false
var last_damage_source = "Unknown"
var xp = 0
var xp_to_next_level = 190
var level = 1
var zorkmids_ref = { value = 150 }

var warrior_level = 0
var rogue_level = 0
var wizard_level = 0

var skill_points = 0
var chosen_skills = []
var skill_tiers_unlocked = {}
var unlocked_abilities = []
var unlocked_spells = []
var spell_cooldowns = {}
var hotbar_spells = []
var belt_items = []
var active_buffs = []
var active_dots = []
var status_flags = {}

const HOTBAR_SIZE = 10
const BELT_SIZE = 9

var base_primary_stats = {}
var bonus_primary_stats = {}
var primary_stats = {}

var bonus_secondary_stats = {}
var secondary_stats = {}

var damage_bonuses = {}
var resistances = {}

var equipment = {}
var inventory = []
var known_recipes = {}
var active_quests = []
var completed_quests = []

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

	inventory.clear()
	for ii in range(INVENTORY_SIZE):
		inventory.append(null)

func recalculate_stats():
	var previous_max_hp = max_hp
	var previous_max_mp = max_mp

	for stat_key in PRIMARY_STAT_KEYS:
		primary_stats[stat_key] = int(base_primary_stats.get(stat_key, 10)) + int(bonus_primary_stats.get(stat_key, 0)) + _get_buff_primary_bonus(stat_key) + _get_equipment_primary_bonus(stat_key)

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
		var base_value = int(derived.get(stat_key, 0))
		var bonus_value = int(bonus_secondary_stats.get(stat_key, 0))
		var buff_value = _get_buff_secondary_bonus(stat_key)
		var equip_value = _get_equipment_secondary_bonus(stat_key)
		secondary_stats[stat_key] = base_value + bonus_value + buff_value + equip_value

	max_hp = max(1, int(secondary_stats["hp_max"]))
	max_mp = max(0, int(secondary_stats["mp_max"]))
	sight_radius = max(1, int(secondary_stats["visual_sight_radius"]))

	if previous_max_hp > 0 and max_hp != previous_max_hp:
		hp = clamp(hp + max(0, max_hp - previous_max_hp), 0, max_hp)
	else:
		hp = clamp(hp, 0, max_hp)

	if previous_max_mp > 0 and max_mp != previous_max_mp:
		mp = clamp(mp + max(0, max_mp - previous_max_mp), 0, max_mp)
	else:
		mp = clamp(mp, 0, max_mp)

	stats_changed.emit()

func get_primary_stat(stat_key):
	return int(primary_stats.get(stat_key, 0))

func get_primary_stat_by_id(stat_id):
	var index = int(stat_id)
	if index < 0 or index >= PRIMARY_STAT_KEYS.size():
		return 0
	return get_primary_stat(PRIMARY_STAT_KEYS[index])

func add_primary_bonus(stat_key, amount):
	if not bonus_primary_stats.has(stat_key):
		return
	bonus_primary_stats[stat_key] += int(amount)
	recalculate_stats()

func get_secondary_stat(stat_key):
	return int(secondary_stats.get(stat_key, 0))

func get_secondary_stat_by_id(stat_id):
	var index = int(stat_id)
	if not SECONDARY_STAT_BY_ID.has(index):
		return 0
	return get_secondary_stat(SECONDARY_STAT_BY_ID[index])

func add_secondary_bonus(stat_key, amount):
	if not bonus_secondary_stats.has(stat_key):
		return
	bonus_secondary_stats[stat_key] += int(amount)
	recalculate_stats()

func get_resistance(damage_type):
	return int(resistances.get(damage_type, 0)) + _get_buff_resistance_bonus(damage_type) + _get_equipment_resistance_bonus(damage_type)

func add_resistance(damage_type, amount):
	if not resistances.has(damage_type):
		return
	resistances[damage_type] += int(amount)
	stats_changed.emit()

func get_damage_bonus(damage_type):
	return int(damage_bonuses.get(damage_type, 0)) + _get_buff_damage_bonus(damage_type) + _get_equipment_damage_bonus(damage_type)

func add_damage_bonus(damage_type, amount):
	if not damage_bonuses.has(damage_type):
		return
	damage_bonuses[damage_type] += int(amount)
	stats_changed.emit()

func set_last_damage_source(source_name):
	if str(source_name) != "":
		last_damage_source = str(source_name)

func set_hp(value):
	hp = clamp(int(value), 0, max_hp)
	hp_changed.emit(hp, max_hp)
	if hp <= 0 and not is_dead:
		is_dead = true
		died.emit(last_damage_source)

func modify_hp(delta_amount, source_name = ""):
	if int(delta_amount) < 0 and str(source_name) != "":
		last_damage_source = str(source_name)
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
	var gained = int(amount)
	if gained <= 0:
		return false
	xp = max(0, xp + gained)
	var did_level_up = false
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		skill_points += 1
		xp_to_next_level = _compute_xp_threshold(level)
		did_level_up = true
	xp_changed.emit(xp, xp_to_next_level, level)
	if did_level_up:
		leveled_up.emit(level, skill_points)
	return did_level_up

func get_skill_tier(skill_id):
	return int(skill_tiers_unlocked.get(int(skill_id), 0))

func get_skill_max_tiers(skill_id):
	var skill_entry = OD.Database.get_skill(int(skill_id)) if OD.Database != null else null
	if skill_entry == null:
		return 0
	return skill_entry.level_progression.size()

func get_next_skill_tier_entry(skill_id):
	var skill_entry = OD.Database.get_skill(int(skill_id)) if OD.Database != null else null
	if skill_entry == null:
		return null
	var current_tier = get_skill_tier(skill_id)
	if current_tier >= skill_entry.level_progression.size():
		return null
	return skill_entry.level_progression[current_tier]

func can_unlock_skill_tier(skill_id):
	var sid = int(skill_id)
	if skill_points <= 0:
		return false
	if not chosen_skills.has(sid):
		return false
	return get_skill_tier(sid) < get_skill_max_tiers(sid)

func _apply_ability_bonuses(level_entry):
	if level_entry == null:
		return
	for buff in level_entry.primary_buffs:
		if typeof(buff) != TYPE_DICTIONARY or not buff.has("id"):
			continue
		var stat_index = int(buff.id)
		if stat_index >= 0 and stat_index < PRIMARY_STAT_KEYS.size():
			var stat_key = PRIMARY_STAT_KEYS[stat_index]
			bonus_primary_stats[stat_key] += int(buff.get("amount", 0))
	for buff in level_entry.secondary_buffs:
		if typeof(buff) != TYPE_DICTIONARY or not buff.has("id"):
			continue
		var sec_id = int(buff.id)
		if SECONDARY_STAT_BY_ID.has(sec_id):
			var sec_key = SECONDARY_STAT_BY_ID[sec_id]
			bonus_secondary_stats[sec_key] += int(buff.get("amount", 0))
	for buff in level_entry.resist_buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		for damage_type in DAMAGE_TYPES:
			if buff.has(damage_type):
				resistances[damage_type] += int(buff[damage_type])
	for buff in level_entry.damage_buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		for damage_type in DAMAGE_TYPES:
			if buff.has(damage_type):
				damage_bonuses[damage_type] += int(buff[damage_type])
	for spell_ref in level_entry.spells:
		if typeof(spell_ref) == TYPE_DICTIONARY and spell_ref.has("name"):
			var spell_name = str(spell_ref.name)
			if spell_name != "" and not unlocked_spells.has(spell_name):
				unlocked_spells.append(spell_name)
				_assign_spell_to_first_empty_hotbar(spell_name)

func unlock_next_skill_tier(skill_id, free = false):
	var sid = int(skill_id)
	if not free and not can_unlock_skill_tier(sid):
		return { success = false, reason = "Cannot unlock skill tier" }
	var skill_entry = OD.Database.get_skill(sid) if OD.Database != null else null
	if skill_entry == null:
		return { success = false, reason = "Unknown skill" }
	var current_tier = get_skill_tier(sid)
	if current_tier >= skill_entry.level_progression.size():
		return { success = false, reason = "Skill already maxed" }
	var level_entry = skill_entry.level_progression[current_tier]
	if not free:
		skill_points -= 1
	skill_tiers_unlocked[sid] = current_tier + 1
	match str(skill_entry.type).to_lower():
		"warrior":
			warrior_level += 1
		"rogue":
			rogue_level += 1
		"wizard":
			wizard_level += 1
	unlocked_abilities.append({
		skill_id = sid,
		skill_name = skill_entry.name,
		tier = current_tier + 1,
		ability = level_entry
	})
	_apply_ability_bonuses(level_entry)
	recalculate_stats()
	skill_unlocked.emit(sid, level_entry)
	skills_changed.emit()
	return { success = true, skill_id = sid, tier = current_tier + 1, level_entry = level_entry }

func _init_starting_skills(skill_ids):
	chosen_skills.clear()
	skill_tiers_unlocked.clear()
	unlocked_abilities.clear()
	unlocked_spells.clear()
	warrior_level = 0
	rogue_level = 0
	wizard_level = 0
	if skill_ids == null:
		return
	for raw_id in skill_ids:
		var sid = int(raw_id)
		if chosen_skills.has(sid):
			continue
		if OD.Database != null and OD.Database.get_skill(sid) == null:
			continue
		chosen_skills.append(sid)
		skill_tiers_unlocked[sid] = 0
		unlock_next_skill_tier(sid, true)

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

func _get_facing_dir_key():
	if abs(last_delta_x) >= abs(last_delta_y):
		if last_delta_x < 0:
			return "left"
		if last_delta_x > 0:
			return "right"
	if last_delta_y < 0:
		return "up"
	return "down"

func face_towards(target_cell):
	var current_position = get_grid_position()
	if current_position == null or target_cell == null:
		return
	var delta_x = int(target_cell.x) - int(current_position.x)
	var delta_y = int(target_cell.y) - int(current_position.y)
	if delta_x == 0 and delta_y == 0:
		return
	last_delta_x = delta_x
	last_delta_y = delta_y
	idle()

func _get_or_load_action_anim(group_key, direction_key):
	if not animations.has(group_key):
		animations[group_key] = {}
	var group = animations[group_key]
	if group.has(direction_key):
		return group[direction_key]
	var sprite_paths = OD.Resources.paths.player.heroine if hero_kind == "heroine" else OD.Resources.paths.player.hero
	if not sprite_paths.has(group_key):
		return null
	var group_paths = sprite_paths[group_key]
	var resolved_key = direction_key
	if not group_paths.has(resolved_key):
		if group_paths.has("right"):
			resolved_key = "right"
		elif group_paths.has("down"):
			resolved_key = "down"
		else:
			return null
	if group.has(resolved_key):
		return group[resolved_key]
	var anim = OD.Load.animation(group_paths[resolved_key])
	if anim == null:
		return null
	anim.visible = false
	if anim.is_tall():
		anim.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
	add_child(anim)
	group[resolved_key] = anim
	return anim

func _play_action_animation(group_key, duration_sec = 0.28, return_to_idle = true):
	if animations.is_empty():
		return
	var direction_key = _get_facing_dir_key()
	var animation = _get_or_load_action_anim(group_key, direction_key)
	if animation == null:
		return
	_action_animation_token += 1
	var active_token = _action_animation_token
	if current_animation != null:
		current_animation.visible = false
	current_animation = animation
	current_animation.visible = true
	if current_animation.has_method("stop"):
		current_animation.stop()
	if current_animation.has_method("play"):
		current_animation.play()
	if not return_to_idle or not is_inside_tree():
		return
	var timer = get_tree().create_timer(duration_sec)
	timer.timeout.connect(func():
		if is_instance_valid(self) and not is_dead and _action_animation_token == active_token and not is_moving():
			idle()
	)

func _resolve_melee_attack_group():
	for slot_name in ["weapon_right", "weapon_left"]:
		var item = equipment.get(slot_name, null)
		if item != null and typeof(item) == TYPE_DICTIONARY and item.get("category", "") == "weapon":
			match int(item.get("type", -1)):
				0:
					return "attack_sword"
				1:
					return "attack_axe"
				2:
					return "attack_mace"
				3:
					return "attack_staff"
				4:
					return "attack_bow"
				5:
					return "attack_thrown"
				7:
					return "attack_dagger"
				8:
					return "attack_polearm"
	return "attack_unarm"

func play_attack_animation(attack_kind = "melee"):
	var group_key = "attack_unarm"
	if attack_kind == "bolt":
		group_key = "attack_bow"
	elif attack_kind == "thrown":
		group_key = "attack_thrown"
	else:
		group_key = _resolve_melee_attack_group()
	_play_action_animation(group_key, 0.26, true)

func play_cast_animation():
	_play_action_animation("cast", 0.28, true)

func play_hit_animation():
	if is_inside_tree():
		modulate = Color(1.4, 0.45, 0.45, 1.0)
		var flash_tween = create_tween()
		flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
	_play_action_animation("hit", 0.2, true)

func play_eat_animation():
	_play_action_animation("eat", 0.3, true)

func play_drink_animation():
	_play_action_animation("drink", 0.3, true)

func play_levelup_animation():
	_play_action_animation("levelup", 0.45, true)

func play_die_animation():
	_play_action_animation("die", 0.5, false)

func update_animation(delta_x, delta_y):
	if animations.is_empty():
		return
	var next_animation = current_animation
	if delta_x != 0:
		next_animation = animations.move.left if delta_x < 0 else animations.move.right
	elif delta_y != 0:
		next_animation = animations.move.up if delta_y < 0 else animations.move.down
	if next_animation != current_animation:
		if current_animation != null:
			current_animation.visible = false
		current_animation = next_animation
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
	skill_points = 0
	xp_to_next_level = _compute_xp_threshold(level)
	zorkmids_ref = { value = 150 }

	var starting_ids = settings.get("starting_skill_ids", []) if settings != null else []
	_init_starting_skills(starting_ids)
	recalculate_stats()
	hp = max_hp
	mp = max_mp

	_load_sprite_animations()

func _ensure_hotbar_initialized():
	while hotbar_spells.size() < HOTBAR_SIZE:
		hotbar_spells.append("")

func _assign_spell_to_first_empty_hotbar(spell_name):
	_ensure_hotbar_initialized()
	if hotbar_spells.has(spell_name):
		return
	for ii in range(HOTBAR_SIZE):
		if hotbar_spells[ii] == "":
			hotbar_spells[ii] = spell_name
			return

func get_hotbar_spells():
	_ensure_hotbar_initialized()
	return hotbar_spells.duplicate()

func get_hotbar_spell(slot_index):
	_ensure_hotbar_initialized()
	if slot_index < 0 or slot_index >= HOTBAR_SIZE:
		return ""
	return hotbar_spells[slot_index]

func set_hotbar_slot(slot_index, spell_name):
	_ensure_hotbar_initialized()
	if slot_index < 0 or slot_index >= HOTBAR_SIZE:
		return
	hotbar_spells[slot_index] = str(spell_name)
	skills_changed.emit()

func _ensure_belt_initialized():
	while belt_items.size() < BELT_SIZE:
		belt_items.append("")

func get_belt_items():
	_ensure_belt_initialized()
	return belt_items.duplicate()

func get_belt_item(slot_index):
	_ensure_belt_initialized()
	if slot_index < 0 or slot_index >= BELT_SIZE:
		return ""
	return belt_items[slot_index]

func set_belt_slot(slot_index, item_name):
	_ensure_belt_initialized()
	if slot_index < 0 or slot_index >= BELT_SIZE:
		return
	belt_items[slot_index] = str(item_name)
	belt_changed.emit()

func find_inventory_index_by_name(item_name):
	var target = str(item_name)
	if target == "":
		return -1
	for ii in range(inventory.size()):
		var item = inventory[ii]
		if item != null and typeof(item) == TYPE_DICTIONARY and str(item.get("name", "")) == target:
			return ii
	return -1

func get_inventory_count_by_name(item_name):
	var target = str(item_name)
	if target == "":
		return 0
	var total = 0
	for item in inventory:
		if item != null and typeof(item) == TYPE_DICTIONARY and str(item.get("name", "")) == target:
			total += max(1, int(item.get("stack", 1)))
	return total

func sync_belt_with_inventory():
	_ensure_belt_initialized()
	var changed = false
	for ii in range(BELT_SIZE):
		if belt_items[ii] != "" and find_inventory_index_by_name(belt_items[ii]) == -1:
			belt_items[ii] = ""
			changed = true
	var usable_categories = ["food", "potion", "mushroom", "wand", "thrown", "trap", "toolkit"]
	for item in inventory:
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		var cat = str(item.get("category", ""))
		var item_name = str(item.get("name", ""))
		if item_name == "" or not usable_categories.has(cat):
			continue
		if belt_items.has(item_name):
			continue
		var empty_index = belt_items.find("")
		if empty_index == -1:
			break
		belt_items[empty_index] = item_name
		changed = true
	if changed:
		belt_changed.emit()

func get_spell_cooldown(spell_name):
	return int(spell_cooldowns.get(str(spell_name), 0))

func set_spell_cooldown(spell_name, turns):
	var key = str(spell_name)
	var count = int(turns)
	if count <= 0:
		spell_cooldowns.erase(key)
	else:
		spell_cooldowns[key] = count

func tick_cooldowns():
	var ticked = 0
	for key in spell_cooldowns.keys():
		var remaining = int(spell_cooldowns[key]) - 1
		ticked += 1
		if remaining <= 0:
			spell_cooldowns.erase(key)
		else:
			spell_cooldowns[key] = remaining
	return ticked

func _get_buff_primary_bonus(stat_key):
	var total = 0
	for buff in active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("primary_bonuses", {}).get(stat_key, 0)) * stacks
	return total

func _get_buff_secondary_bonus(stat_key):
	var total = 0
	for buff in active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("secondary_bonuses", {}).get(stat_key, 0)) * stacks
	return total

func _get_buff_resistance_bonus(damage_type):
	var total = 0
	for buff in active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("resist_bonuses", {}).get(damage_type, 0)) * stacks
	return total

func _get_buff_damage_bonus(damage_type):
	var total = 0
	for buff in active_buffs:
		var stacks = int(buff.get("stacks", 1))
		total += int(buff.get("damage_bonuses", {}).get(damage_type, 0)) * stacks
	return total

func has_buff(buff_name):
	var target_name = str(buff_name)
	for buff in active_buffs:
		if str(buff.get("name", "")) == target_name:
			return true
	return false

func get_active_buffs():
	return active_buffs.duplicate(true)

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
	if removed:
		recalculate_stats()
		buffs_changed.emit()
	return removed

func dismiss_buff(buff_name):
	var target_name = str(buff_name)
	for buff in active_buffs:
		if str(buff.get("name", "")) == target_name:
			if bool(buff.get("removable", false)) and not bool(buff.get("bad", false)):
				return remove_buff_by_name(target_name)
			return false
	return false

func _extract_buff_array(buff_definition, lower_key, camel_key):
	var items = []
	if buff_definition.has(lower_key):
		items.append_array(OD.DataStructure.arrayify(buff_definition.get(lower_key)))
	if buff_definition.has(camel_key):
		items.append_array(OD.DataStructure.arrayify(buff_definition.get(camel_key)))
	return items

func apply_buff(buff_definition, source_spell = ""):
	if buff_definition == null or typeof(buff_definition) != TYPE_DICTIONARY:
		return false
	var buff_name = str(buff_definition.get("name", source_spell))
	var duration = int(buff_definition.get("time", buff_definition.get("duration", 0)))
	var use_timer = int(buff_definition.get("useTimer", buff_definition.get("usetimer", 1 if duration > 0 else 0))) == 1
	var allow_stack = int(buff_definition.get("allowstacking", buff_definition.get("allowStacking", buff_definition.get("stackable", 0)))) == 1
	var max_stacks = max(1, int(buff_definition.get("stacksize", 1)))
	var brittle_count = int(buff_definition.get("brittle", 0))
	var attacks_count = int(buff_definition.get("attacks", 0))

	var primary_b = {}
	for p_item in _extract_buff_array(buff_definition, "primarybuff", "primaryBuff"):
		if typeof(p_item) == TYPE_DICTIONARY and p_item.has("id"):
			var index = int(p_item.id)
			if index >= 0 and index < PRIMARY_STAT_KEYS.size():
				var key = PRIMARY_STAT_KEYS[index]
				primary_b[key] = int(primary_b.get(key, 0)) + int(p_item.get("amount", 0))

	var secondary_b = {}
	for s_item in _extract_buff_array(buff_definition, "secondarybuff", "secondaryBuff"):
		if typeof(s_item) == TYPE_DICTIONARY and s_item.has("id"):
			var sec_id = int(s_item.id)
			if SECONDARY_STAT_BY_ID.has(sec_id):
				var key = SECONDARY_STAT_BY_ID[sec_id]
				secondary_b[key] = int(secondary_b.get(key, 0)) + int(s_item.get("amount", 0))

	for sight_item in OD.DataStructure.arrayify(buff_definition.get("sightbuff", [])):
		if typeof(sight_item) == TYPE_DICTIONARY and sight_item.has("amount"):
			secondary_b["visual_sight_radius"] = int(secondary_b.get("visual_sight_radius", 0)) + int(sight_item.amount)

	var resist_b = {}
	for r_item in _extract_buff_array(buff_definition, "resistbuff", "resistBuff"):
		if typeof(r_item) == TYPE_DICTIONARY:
			for damage_type in DAMAGE_TYPES:
				if r_item.has(damage_type):
					resist_b[damage_type] = int(resist_b.get(damage_type, 0)) + int(r_item[damage_type])

	var damage_b = {}
	for d_item in _extract_buff_array(buff_definition, "damagebuff", "damageBuff"):
		if typeof(d_item) == TYPE_DICTIONARY:
			for damage_type in DAMAGE_TYPES:
				if d_item.has(damage_type):
					damage_b[damage_type] = int(damage_b.get(damage_type, 0)) + int(d_item[damage_type])

	var target_hit_procs = []
	for th_item in OD.DataStructure.arrayify(buff_definition.get("targetHitEffectBuff", [])):
		if typeof(th_item) == TYPE_DICTIONARY and th_item.has("name"):
			target_hit_procs.append({
				name = str(th_item.name),
				percentage = int(th_item.get("percentage", 100))
			})

	var player_hit_procs = []
	for ph_item in OD.DataStructure.arrayify(buff_definition.get("playerHitEffectBuff", [])):
		if typeof(ph_item) == TYPE_DICTIONARY and ph_item.has("name"):
			player_hit_procs.append({
				name = str(ph_item.name),
				percentage = int(ph_item.get("percentage", 100))
			})

	var description_text = ""
	if buff_definition.has("description") and typeof(buff_definition.description) == TYPE_DICTIONARY and buff_definition.description.has("text"):
		description_text = str(buff_definition.description.text)

	for existing in active_buffs:
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
			recalculate_stats()
			buffs_changed.emit()
			return true

	active_buffs.append({
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
		primary_bonuses = primary_b,
		secondary_bonuses = secondary_b,
		resist_bonuses = resist_b,
		damage_bonuses = damage_b,
		target_hit_procs = target_hit_procs,
		player_hit_procs = player_hit_procs,
		raw = buff_definition
	})
	recalculate_stats()
	buffs_changed.emit()
	return true

func on_attack_performed():
	var procs = []
	var changed = false
	var ii = 0
	while ii < active_buffs.size():
		var buff = active_buffs[ii]
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
				active_buffs.remove_at(ii)
				continue
		ii += 1
	for slot_name in PASSIVE_EQUIPMENT_SLOTS:
		var item = equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		for proc in item.get("target_hit_effects", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
	if changed:
		recalculate_stats()
		buffs_changed.emit()
	return procs

func on_hit_received():
	var procs = []
	var changed = false
	var ii = 0
	while ii < active_buffs.size():
		var buff = active_buffs[ii]
		for proc in buff.get("player_hit_procs", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
		var brit_rem = int(buff.get("brittle_remaining", 0))
		if brit_rem > 0:
			brit_rem -= 1
			buff["brittle_remaining"] = brit_rem
			changed = true
			if brit_rem <= 0:
				active_buffs.remove_at(ii)
				continue
		ii += 1
	for slot_name in PASSIVE_EQUIPMENT_SLOTS:
		var item = equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		for proc in item.get("player_hit_effects", []):
			var percent = clamp(int(proc.get("percentage", 100)), 0, 100)
			if percent >= 100 or (randi() % 100) < percent:
				procs.append(str(proc.name))
	if changed:
		recalculate_stats()
		buffs_changed.emit()
	return procs

func on_moved():
	var changed = false
	var ii = 0
	while ii < active_buffs.size():
		if bool(active_buffs[ii].get("destroy_on_move", false)):
			active_buffs.remove_at(ii)
			changed = true
		else:
			ii += 1
	if changed:
		recalculate_stats()
		buffs_changed.emit()

func set_status_flag(flag_name, turns):
	var key = str(flag_name)
	var count = int(turns)
	if count <= 0:
		status_flags.erase(key)
	else:
		status_flags[key] = max(int(status_flags.get(key, 0)), count)
	buffs_changed.emit()

func has_status_flag(flag_name):
	return int(status_flags.get(str(flag_name), 0)) > 0

func get_status_flags():
	return status_flags.duplicate()

func get_active_dots():
	return active_dots.duplicate(true)

func apply_dot(dot_definition):
	if dot_definition == null or typeof(dot_definition) != TYPE_DICTIONARY:
		return
	active_dots.append(dot_definition.duplicate(true))
	buffs_changed.emit()

func tick_status_effects():
	var ticked = 0
	var buff_changed = false
	var ii = 0
	while ii < active_buffs.size():
		var buff = active_buffs[ii]
		ticked += 1
		var upkeep = int(buff.get("mana_upkeep", 0))
		if upkeep > 0:
			if mp >= upkeep:
				modify_mp(-upkeep)
			else:
				active_buffs.remove_at(ii)
				buff_changed = true
				continue
		var z_upkeep = int(buff.get("zorkmid_upkeep", 0))
		if z_upkeep > 0:
			if get_zorkmids() >= z_upkeep:
				add_zorkmids(-z_upkeep)
			else:
				active_buffs.remove_at(ii)
				buff_changed = true
				continue
		var hp_regen = int(buff.get("hp_per_turn", 0))
		if hp_regen != 0:
			modify_hp(hp_regen)
		var mp_regen = int(buff.get("mp_per_turn", 0))
		if mp_regen != 0:
			modify_mp(mp_regen)
		if buff.get("use_timer", false):
			buff["remaining_turns"] = int(buff.get("remaining_turns", 1)) - 1
			if buff["remaining_turns"] <= 0:
				active_buffs.remove_at(ii)
				buff_changed = true
				continue
		ii += 1
	if buff_changed:
		recalculate_stats()
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
	if ticked > 0 or buff_changed:
		buffs_changed.emit()
	return ticked

func _get_equipment_primary_bonus(stat_key):
	var total = 0
	var stat_index = PRIMARY_STAT_KEYS.find(stat_key)
	if stat_index < 0:
		return 0
	for slot_name in PASSIVE_EQUIPMENT_SLOTS:
		var item = equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		for buff in item.get("primary_buffs", []):
			if int(buff.get("id", -1)) == stat_index:
				total += int(buff.get("amount", 0))
	return total

func _get_equipment_secondary_bonus(stat_key):
	var total = 0
	for slot_name in PASSIVE_EQUIPMENT_SLOTS:
		var item = equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		for buff in item.get("secondary_buffs", []):
			var sec_id = int(buff.get("id", -1))
			if SECONDARY_STAT_BY_ID.get(sec_id, "") == stat_key:
				total += int(buff.get("amount", 0))
	return total

func _get_equipment_resistance_bonus(damage_type):
	var total = 0
	for slot_name in PASSIVE_EQUIPMENT_SLOTS:
		var item = equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		var result_map = item.get("resist_buffs", {})
		if typeof(result_map) == TYPE_DICTIONARY and result_map.has(damage_type):
			total += int(result_map[damage_type])
	return total

func _get_equipment_damage_bonus(damage_type):
	var total = 0
	for slot_name in PASSIVE_EQUIPMENT_SLOTS:
		var item = equipment.get(slot_name, null)
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue
		var damage_map = item.get("damage_buffs", {})
		if typeof(damage_map) == TYPE_DICTIONARY and damage_map.has(damage_type):
			total += int(damage_map[damage_type])
	return total

func get_equipped_item(slot_name):
	return equipment.get(slot_name, null)

func can_equip_in_slot(item_data, slot_name):
	if item_data == null or typeof(item_data) != TYPE_DICTIONARY:
		return false
	if not equipment.has(slot_name):
		return false
	var category = str(item_data.get("category", ""))
	var item_slot = str(item_data.get("slot", ""))
	var item_type = int(item_data.get("type", -1))
	match slot_name:
		"head", "chest", "legs", "feet", "hands", "belt", "neck":
			return item_slot == slot_name
		"ring_left", "ring_right":
			return item_slot == "ring"
		"weapon_right":
			return category == "weapon" and item_type != OD.GameDataKind.WEAPON.BOW
		"weapon_left":
			return item_slot == "off_hand" or (category == "weapon" and item_type != OD.GameDataKind.WEAPON.BOW)
		"missile_weapon":
			return item_slot == "missile_weapon" or (category == "weapon" and item_type == OD.GameDataKind.WEAPON.BOW)
		"bolts":
			return category == "bolts" or item_slot == "bolts" or item_slot == "bolt"
		"thrown":
			return category == "thrown" or item_slot == "thrown"
	return false

func get_valid_slots_for_item(item_data):
	var valid = []
	for slot_name in EQUIPMENT_SLOTS:
		if can_equip_in_slot(item_data, slot_name):
			valid.append(slot_name)
	return valid

func _can_stack_items(item_a, item_b):
	if item_a == null or item_b == null:
		return false
	if typeof(item_a) != TYPE_DICTIONARY or typeof(item_b) != TYPE_DICTIONARY:
		return false
	if int(item_a.get("max_stack", 1)) <= 1:
		return false
	return str(item_a.get("name", "")) == str(item_b.get("name", ""))

func add_item(item_data):
	if item_data == null or typeof(item_data) != TYPE_DICTIONARY:
		return { added = false, remaining = 0, slot_index = -1 }
	var remaining = max(1, int(item_data.get("count", 1)))
	var max_stack = max(1, int(item_data.get("max_stack", 1)))
	var first_slot = -1
	if max_stack > 1:
		for ii in range(inventory.size()):
			var existing = inventory[ii]
			if _can_stack_items(existing, item_data):
				var current_count = int(existing.get("count", 1))
				var space = max_stack - current_count
				if space > 0:
					var to_add = min(space, remaining)
					existing["count"] = current_count + to_add
					remaining -= to_add
					if first_slot == -1:
						first_slot = ii
					if remaining <= 0:
						inventory_changed.emit()
						return { added = true, remaining = 0, slot_index = first_slot }
	for ii in range(inventory.size()):
		if inventory[ii] == null:
			var placed = item_data.duplicate(true)
			var to_place = min(max_stack, remaining)
			placed["count"] = to_place
			inventory[ii] = placed
			remaining -= to_place
			if first_slot == -1:
				first_slot = ii
			if remaining <= 0:
				inventory_changed.emit()
				return { added = true, remaining = 0, slot_index = first_slot }
	if first_slot != -1:
		inventory_changed.emit()
	return { added = (first_slot != -1), remaining = remaining, slot_index = first_slot }

func remove_item_at(slot_index, count = 1):
	if slot_index < 0 or slot_index >= inventory.size():
		return null
	var item = inventory[slot_index]
	if item == null:
		return null
	var current_count = max(1, int(item.get("count", 1)))
	var to_remove = current_count if count < 0 else min(current_count, max(1, int(count)))
	var removed = item.duplicate(true)
	removed["count"] = to_remove
	if current_count - to_remove <= 0:
		inventory[slot_index] = null
	else:
		item["count"] = current_count - to_remove
	inventory_changed.emit()
	return removed

func move_or_swap_inventory_slot(from_index, to_index):
	if from_index < 0 or from_index >= inventory.size() or to_index < 0 or to_index >= inventory.size():
		return false
	if from_index == to_index:
		return false
	var from_item = inventory[from_index]
	if from_item == null:
		return false
	var to_item = inventory[to_index]
	if _can_stack_items(from_item, to_item):
		var max_stack = max(1, int(to_item.get("max_stack", 1)))
		var space = max_stack - int(to_item.get("count", 1))
		if space > 0:
			var from_count = int(from_item.get("count", 1))
			var transfer = min(space, from_count)
			to_item["count"] = int(to_item.get("count", 1)) + transfer
			if from_count - transfer <= 0:
				inventory[from_index] = null
			else:
				from_item["count"] = from_count - transfer
			inventory_changed.emit()
			return true
	inventory[from_index] = to_item
	inventory[to_index] = from_item
	inventory_changed.emit()
	return true

func equip_from_inventory(inventory_index, target_slot = ""):
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	var item = inventory[inventory_index]
	if item == null:
		return false
	var valid_slots = get_valid_slots_for_item(item)
	if valid_slots.is_empty():
		return false
	var chosen_slot = target_slot
	if chosen_slot == "" or not (chosen_slot in valid_slots):
		chosen_slot = valid_slots[0]
		for candidate in valid_slots:
			if equipment.get(candidate, null) == null:
				chosen_slot = candidate
				break
	var previous_equipped = equipment.get(chosen_slot, null)
	if _can_stack_items(previous_equipped, item):
		var max_stack = max(1, int(previous_equipped.get("max_stack", 1)))
		var current_count = int(previous_equipped.get("count", 1))
		var add_count = int(item.get("count", 1))
		var transfer = min(max_stack - current_count, add_count)
		if transfer > 0:
			previous_equipped["count"] = current_count + transfer
			if add_count - transfer <= 0:
				inventory[inventory_index] = null
			else:
				item["count"] = add_count - transfer
			recalculate_stats()
			equipment_changed.emit()
			inventory_changed.emit()
			if OD.Audio != null:
				OD.Audio.play_sfx("metal_get")
			return true
	equipment[chosen_slot] = item
	inventory[inventory_index] = previous_equipped
	recalculate_stats()
	equipment_changed.emit()
	inventory_changed.emit()
	if OD.Audio != null:
		OD.Audio.play_sfx("metal_get")
	return true

func unequip_slot(slot_name, target_inventory_index = -1):
	if not equipment.has(slot_name):
		return false
	var equipped = equipment[slot_name]
	if equipped == null:
		return false
	if target_inventory_index >= 0 and target_inventory_index < inventory.size():
		var target_item = inventory[target_inventory_index]
		if target_item == null:
			inventory[target_inventory_index] = equipped
			equipment[slot_name] = null
			recalculate_stats()
			equipment_changed.emit()
			inventory_changed.emit()
			if OD.Audio != null:
				OD.Audio.play_sfx("metal_get")
			return true
		if can_equip_in_slot(target_item, slot_name):
			equipment[slot_name] = target_item
			inventory[target_inventory_index] = equipped
			recalculate_stats()
			equipment_changed.emit()
			inventory_changed.emit()
			if OD.Audio != null:
				OD.Audio.play_sfx("metal_get")
			return true
	var result = add_item(equipped)
	if not result.added:
		if OD.Audio != null:
			OD.Audio.play_sfx("fullinventory")
		return false
	if result.remaining > 0:
		equipped["count"] = result.remaining
	else:
		equipment[slot_name] = null
	recalculate_stats()
	equipment_changed.emit()
	inventory_changed.emit()
	if OD.Audio != null:
		OD.Audio.play_sfx("metal_get")
	return true

func consume_equipped_ammo(slot_name, amount = 1):
	if not equipment.has(slot_name):
		return null
	var ammo = equipment[slot_name]
	if ammo == null:
		return null
	var current_count = max(1, int(ammo.get("count", 1)))
	var used = min(current_count, max(1, int(amount)))
	var single = ammo.duplicate(true)
	single["count"] = used
	if current_count - used <= 0:
		equipment[slot_name] = null
	else:
		ammo["count"] = current_count - used
	equipment_changed.emit()
	return single

func sort_inventory():
	var merged = []
	for slot_item in inventory:
		if slot_item == null:
			continue
		var stacked = false
		if int(slot_item.get("max_stack", 1)) > 1:
			for existing in merged:
				if _can_stack_items(existing, slot_item):
					var max_s = int(existing.get("max_stack", 1))
					var space = max_s - int(existing.get("count", 1))
					if space > 0:
						var move_amount = min(space, int(slot_item.get("count", 1)))
						existing["count"] = int(existing.get("count", 1)) + move_amount
						slot_item["count"] = int(slot_item.get("count", 1)) - move_amount
						if int(slot_item.get("count", 1)) <= 0:
							stacked = true
							break
		if not stacked:
			merged.append(slot_item)
	merged.sort_custom(func(item_a, item_b):
		var category_a = str(item_a.get("category", ""))
		var category_b = str(item_b.get("category", ""))
		if category_a != category_b:
			return category_a < category_b
		return str(item_a.get("name", "")) < str(item_b.get("name", ""))
	)
	for ii in range(INVENTORY_SIZE):
		inventory[ii] = merged[ii] if ii < merged.size() else null
	inventory_changed.emit()

func get_inventory_items():
	var items = []
	for ii in range(inventory.size()):
		if inventory[ii] != null:
			items.append({ slot_index = ii, item = inventory[ii] })
	return items

func is_item_usable(item_data):
	if item_data == null or typeof(item_data) != TYPE_DICTIONARY:
		return false
	var cat = str(item_data.get("category", ""))
	return cat in ["food", "potion", "mushroom", "wand", "toolkit"]

func get_item_spell_name(item_data):
	if item_data == null or typeof(item_data) != TYPE_DICTIONARY:
		return ""
	var cat = str(item_data.get("category", ""))
	if cat == "potion":
		return str(item_data.get("potion_spell", ""))
	if cat == "mushroom":
		return str(item_data.get("casts_spell", ""))
	if cat == "wand":
		return str(item_data.get("wand_spell", ""))
	return ""

func apply_tipsy_buff(mp_per_turn = 1, duration = 6, icon_path = ""):
	var buff_definition = {
		name = "Tipsy",
		description = { text = "Alcohol warms the blood: +" + str(mp_per_turn) + " MP/turn, +2 Magic Power, +1 Melee Power, -1 Dodge per stack." },
		icon = icon_path if icon_path != "" else "items/booze_pilsner.png",
		smallicon = icon_path if icon_path != "" else "items/booze_pilsner.png",
		useTimer = 1,
		time = max(1, int(duration)),
		allowstacking = 1,
		stacksize = 5,
		mp_per_turn = int(mp_per_turn),
		secondaryBuff = [
			{ id = 3, amount = 2 },
			{ id = 2, amount = 1 },
			{ id = 6, amount = -1 }
		]
	}
	return apply_buff(buff_definition, "Tipsy")

func use_consumable_at(inventory_index, target_cell = Vector2i.ZERO, context = {}):
	if inventory_index < 0 or inventory_index >= inventory.size():
		return { executed = false, reason = "Invalid inventory slot" }
	var item = inventory[inventory_index]
	if item == null:
		return { executed = false, reason = "Empty slot" }
	var cat = str(item.get("category", ""))
	if not is_item_usable(item):
		return { executed = false, reason = "Item is not usable" }

	var p_position = get_grid_position()
	var self_cell = Vector2i(int(p_position.x), int(p_position.y)) if p_position != null else target_cell
	var spell_ctx = context.duplicate()
	spell_ctx["free_cast"] = true
	var spell_engine = load("res://script/instance/combat/spell_engine.gd")

	if cat == "food":
		var is_booze = bool(item.get("is_booze", false)) or int(item.get("food_mp", 0)) > 0
		var item_icon = str(item.get("icon", ""))
		var extra_spell = str(item.get("food_effect", ""))
		if is_booze:
			var total_mp = max(1, int(item.get("food_mp", 6)))
			var turns = 6
			var mp_per_turn = max(1, int(ceil(float(total_mp) / float(turns))))
			apply_tipsy_buff(mp_per_turn, turns, item_icon)
			if extra_spell != "" and spell_engine != null:
				spell_engine.execute_spell(extra_spell, self, self_cell, spell_ctx)
			remove_item_at(inventory_index, 1)
			return {
				executed = true,
				kind = "booze",
				item_name = str(item.get("name", "Booze")),
				mp_per_turn = mp_per_turn,
				turns = turns
			}
		var total_hp = max(1, int(item.get("food_hp", 1)))
		var hp_per_turn = 1 if total_hp <= 8 else 2
		var turns = max(1, int(ceil(float(total_hp) / float(hp_per_turn))))
		apply_buff({
			name = "Digestion",
			description = { text = "Restores " + str(hp_per_turn) + " HP per turn." },
			icon = item_icon if item_icon != "" else "items/food_steak.png",
			smallicon = item_icon if item_icon != "" else "items/food_steak.png",
			useTimer = 1,
			time = turns,
			hp_per_turn = hp_per_turn
		}, str(item.get("name", "Food")))
		if extra_spell != "" and spell_engine != null:
			spell_engine.execute_spell(extra_spell, self, self_cell, spell_ctx)
		remove_item_at(inventory_index, 1)
		return {
			executed = true,
			kind = "food",
			item_name = str(item.get("name", "Food")),
			hp_per_turn = hp_per_turn,
			turns = turns
		}

	if cat == "potion" or cat == "mushroom":
		var spell_name = get_item_spell_name(item)
		if spell_name == "":
			return { executed = false, reason = "No spell bound to item" }
		var result = spell_engine.execute_spell(spell_name, self, self_cell, spell_ctx)
		if not result.get("executed", false):
			return result
		remove_item_at(inventory_index, 1)
		return {
			executed = true,
			kind = cat,
			item_name = str(item.get("name", cat.capitalize())),
			spell_name = spell_name,
			spell_result = result
		}

	if cat == "wand":
		var charges = int(item.get("charges", 0))
		if charges <= 0:
			remove_item_at(inventory_index, 1)
			return { executed = false, burned_out = true, reason = "Wand has no charges left" }
		var wand_spell = str(item.get("wand_spell", ""))
		if wand_spell == "":
			return { executed = false, reason = "Wand has no spell" }
		var cast_target = target_cell if target_cell != Vector2i.ZERO else self_cell
		var result = spell_engine.execute_spell(wand_spell, self, cast_target, spell_ctx)
		if not result.get("executed", false):
			return result
		var preserve_chance = clamp(get_secondary_stat("wandcrafting_level") * 8, 0, 50)
		var preserved = preserve_chance > 0 and (randi() % 100) < preserve_chance
		if not preserved:
			charges -= 1
			item["charges"] = charges
		var burned_out = charges <= 0
		if burned_out:
			remove_item_at(inventory_index, 1)
		else:
			inventory_changed.emit()
		return {
			executed = true,
			kind = "wand",
			item_name = str(item.get("name", "Wand")),
			spell_name = wand_spell,
			remaining_charges = charges,
			preserved_charge = preserved,
			burned_out = burned_out,
			spell_result = result
		}

	if cat == "toolkit":
		var tool_tag = OD.Database.get_toolkit_tag_for_item(item) if OD.Database != null else ""
		return {
			executed = true,
			kind = "toolkit",
			tool_tag = tool_tag,
			item_name = str(item.get("name", "Toolkit"))
		}

	return { executed = false, reason = "Unsupported consumable" }

func learn_recipe(recipe_or_id):
	if typeof(recipe_or_id) == TYPE_DICTIONARY:
		if recipe_or_id.has("id"):
			known_recipes[str(recipe_or_id.id)] = true
		if recipe_or_id.has("outputs"):
			for out_entry in recipe_or_id.outputs:
				if typeof(out_entry) == TYPE_DICTIONARY and out_entry.has("name"):
					known_recipes[str(out_entry.name)] = true
	else:
		known_recipes[str(recipe_or_id)] = true

func knows_recipe(recipe):
	if recipe == null:
		return false
	if not bool(recipe.get("hidden", false)):
		return true
	if known_recipes.has(str(recipe.get("id", ""))):
		return true
	for out_entry in recipe.get("outputs", []):
		if typeof(out_entry) == TYPE_DICTIONARY and known_recipes.has(str(out_entry.get("name", ""))):
			return true
	return false

func get_crafting_skill_level(tool_tag):
	if OD.Database == null:
		return 0
	var skill_key = OD.Database.get_craft_skill_key(tool_tag)
	if skill_key == "":
		return 0
	return max(0, int(get_secondary_stat(skill_key)))

func get_possessed_toolkits():
	var found = {}
	if OD.Database == null:
		return found
	for item in inventory:
		if item == null or str(item.get("category", "")) != "toolkit":
			continue
		var tag = OD.Database.get_toolkit_tag_for_item(item)
		if tag != "" and tag != "lutefisk" and not found.has(tag):
			found[tag] = item
	return found

func has_toolkit(tool_tag):
	return get_possessed_toolkits().has(str(tool_tag))

func count_item_in_inventory(item_name):
	var total = 0
	for item in inventory:
		if item != null and str(item.get("name", "")) == str(item_name):
			total += max(1, int(item.get("count", 1)))
	return total

func _required_input_counts(recipe):
	var counts = {}
	for inp in recipe.get("inputs", []):
		var inp_name = str(inp.get("name", "")) if typeof(inp) == TYPE_DICTIONARY else str(inp)
		if inp_name != "":
			counts[inp_name] = int(counts.get(inp_name, 0)) + 1
	return counts

func can_craft_recipe(recipe, ignore_toolkit_check = false):
	if recipe == null or OD.Database == null:
		return { ok = false, reason = "Invalid recipe" }
	var tool_tag = str(recipe.get("tool", ""))
	if not ignore_toolkit_check and tool_tag != "" and not has_toolkit(tool_tag):
		return { ok = false, reason = "Missing required tool (" + tool_tag + ")" }
	var skill_level = get_crafting_skill_level(tool_tag)
	var min_skill = int(recipe.get("min_skill", 0))
	if skill_level < min_skill:
		return { ok = false, reason = "Requires skill level " + str(min_skill) + " (have " + str(skill_level) + ")" }
	var req_counts = _required_input_counts(recipe)
	for req_name in req_counts:
		var have_amount = count_item_in_inventory(req_name)
		var need_amount = int(req_counts[req_name])
		if have_amount < need_amount:
			return { ok = false, reason = "Missing " + req_name + " (" + str(have_amount) + "/" + str(need_amount) + ")" }
	return { ok = true, reason = "" }

func _consume_inventory_item_by_name(item_name, amount):
	var remaining = amount
	for index in range(inventory.size()):
		if remaining <= 0:
			break
		var item = inventory[index]
		if item == null or str(item.get("name", "")) != str(item_name):
			continue
		var cnt = max(1, int(item.get("count", 1)))
		var take = min(cnt, remaining)
		remaining -= take
		if cnt - take <= 0:
			inventory[index] = null
		else:
			item["count"] = cnt - take
	return remaining == 0

func craft_recipe(recipe, ignore_toolkit_check = false):
	var check = can_craft_recipe(recipe, ignore_toolkit_check)
	if not check.ok:
		return check
	var tool_tag = str(recipe.get("tool", ""))
	var skill_level = get_crafting_skill_level(tool_tag)
	var out_definition = OD.Database.get_craft_output_for_skill(recipe, skill_level)
	if out_definition == null:
		return { ok = false, reason = "No valid output for current skill level" }
	var out_name = str(out_definition.get("name", ""))
	var out_amount = max(1, int(out_definition.get("amount", 1)))

	var req_counts = _required_input_counts(recipe)
	for req_name in req_counts:
		_consume_inventory_item_by_name(req_name, int(req_counts[req_name]))

	var created_items = []
	var leftover_items = []
	var sample = OD.Database.create_item_instance(out_name, 1)
	if sample != null:
		if int(sample.get("max_stack", 1)) > 1:
			var stacked = OD.Database.create_item_instance(out_name, out_amount)
			var add_result = add_item(stacked)
			created_items.append(stacked)
			if not add_result.added or add_result.remaining > 0:
				var remaining_count = add_result.remaining if add_result.added else out_amount
				var drop_inst = OD.Database.create_item_instance(out_name, remaining_count)
				if drop_inst != null:
					leftover_items.append(drop_inst)
		else:
			for _ii in range(out_amount):
				var inst = OD.Database.create_item_instance(out_name, 1)
				if inst != null:
					created_items.append(inst)
					var add_result = add_item(inst)
					if not add_result.added:
						leftover_items.append(inst)

	var toolkit_info = OD.Database.get_toolkit_info(tool_tag)
	if toolkit_info != null and toolkit_info.sound != "":
		OD.Audio.play_sfx(toolkit_info.sound)
	inventory_changed.emit()
	return {
		ok = true,
		output_name = out_name,
		amount = out_amount,
		items = created_items,
		leftover_items = leftover_items
	}

func craft_from_slots(tool_tag, placed_names):
	if OD.Database == null:
		return { ok = false, reason = "Database unavailable" }
	var cleaned = []
	for entry in placed_names:
		var item_name = str(entry)
		if item_name != "":
			cleaned.append(item_name)
	if cleaned.is_empty():
		return { ok = false, reason = "Place ingredients in the slots first." }
	cleaned.sort()
	var recipes = OD.Database.get_crafts_by_tool(tool_tag)
	for recipe in recipes:
		var req_names = []
		for inp in recipe.get("inputs", []):
			var inp_name = str(inp.get("name", "")) if typeof(inp) == TYPE_DICTIONARY else str(inp)
			if inp_name != "":
				req_names.append(inp_name)
		req_names.sort()
		if req_names == cleaned:
			return craft_recipe(recipe)
	return { ok = false, reason = "No matching recipe for those ingredients." }

func get_item_encrust_slot(item):
	if item == null:
		return ""
	var item_slot = str(item.get("slot", ""))
	if item_slot == "":
		return ""
	if item_slot == "belt":
		return "waist"
	if item_slot == "off_hand":
		return "shield"
	if item_slot == "missile_weapon":
		return "ranged"
	if item_slot in ["weapon", "head", "chest", "legs", "feet", "hands", "neck", "ring"]:
		return item_slot
	return ""

func is_item_eligible_for_encrust(item, encrust_definition):
	if item == null or encrust_definition == null:
		return false
	var encrust_slot = get_item_encrust_slot(item)
	if encrust_slot == "":
		return false
	return encrust_slot in encrust_definition.get("slots", [])

func get_eligible_items_for_encrust(encrust_definition):
	var eligible = []
	var seen = {}
	if encrust_definition == null:
		return eligible
	for equip_slot in EQUIPMENT_SLOTS:
		var eq_item = equipment.get(equip_slot, null)
		if eq_item != null and not seen.has(eq_item) and is_item_eligible_for_encrust(eq_item, encrust_definition):
			seen[eq_item] = true
			eligible.append({ item = eq_item, location = "equipped", slot = equip_slot })
	for idx in range(inventory.size()):
		var inventory_item = inventory[idx]
		if inventory_item != null and not seen.has(inventory_item) and is_item_eligible_for_encrust(inventory_item, encrust_definition):
			seen[inventory_item] = true
			eligible.append({ item = inventory_item, location = "inventory", index = idx })
	return eligible

func count_item_in_inventory_excluding(item_name, excluded_item = null):
	var total = 0
	for item in inventory:
		if item == null or item == excluded_item:
			continue
		if str(item.get("name", "")) == str(item_name) or str(item.get("base_name", "")) == str(item_name):
			total += max(1, int(item.get("count", 1)))
	return total

func _consume_inventory_item_excluding(item_name, amount, excluded_item = null):
	var remaining = amount
	for index in range(inventory.size()):
		if remaining <= 0:
			break
		var item = inventory[index]
		if item == null or item == excluded_item:
			continue
		if str(item.get("name", "")) != str(item_name) and str(item.get("base_name", "")) != str(item_name):
			continue
		var cnt = max(1, int(item.get("count", 1)))
		var take = min(cnt, remaining)
		remaining -= take
		if cnt - take <= 0:
			inventory[index] = null
		else:
			item["count"] = cnt - take
	return remaining == 0

func can_encrust_item(encrust_definition, target_item, ignore_toolkit_check = false):
	if encrust_definition == null or OD.Database == null:
		return { ok = false, reason = "Invalid encrusting recipe" }
	var tool_tag = str(encrust_definition.get("tool", ""))
	if not ignore_toolkit_check and tool_tag != "" and not has_toolkit(tool_tag):
		return { ok = false, reason = "Missing required tool (" + tool_tag + ")" }
	var skill_level = get_crafting_skill_level(tool_tag)
	var min_skill = int(encrust_definition.get("min_skill", 0))
	if skill_level < min_skill:
		return { ok = false, reason = "Requires skill level " + str(min_skill) + " (have " + str(skill_level) + ")" }
	if target_item == null:
		return { ok = false, reason = "Select an eligible item to encrust" }
	if not is_item_eligible_for_encrust(target_item, encrust_definition):
		return { ok = false, reason = "Item cannot receive this encrust" }
	var req_counts = _required_input_counts(encrust_definition)
	for req_name in req_counts:
		var have_amount = count_item_in_inventory_excluding(req_name, target_item)
		var need_amount = int(req_counts[req_name])
		if have_amount < need_amount:
			return { ok = false, reason = "Missing " + req_name + " (" + str(have_amount) + "/" + str(need_amount) + ")" }
	return { ok = true, reason = "" }

func _merge_buff_list(target_list, source_list):
	for source in source_list:
		var source_id = int(source.get("id", -1))
		var source_amount = int(source.get("amount", 0))
		var merged = false
		for destination in target_list:
			if int(destination.get("id", -1)) == source_id:
				destination["amount"] = int(destination.get("amount", 0)) + source_amount
				merged = true
				break
		if not merged:
			target_list.append({ id = source_id, amount = source_amount })

func _merge_buff_map(target_map, source_map):
	for key in source_map:
		target_map[key] = int(target_map.get(key, 0)) + int(source_map[key])

func encrust_item(encrust_definition, target_item, ignore_toolkit_check = false):
	var check = can_encrust_item(encrust_definition, target_item, ignore_toolkit_check)
	if not check.ok:
		return check
	var req_counts = _required_input_counts(encrust_definition)
	for req_name in req_counts:
		_consume_inventory_item_excluding(req_name, int(req_counts[req_name]), target_item)

	var applied = target_item.get("encrusts", [])
	applied.append(str(encrust_definition.get("name", "Encrust")))
	target_item["encrusts"] = applied

	var tags = target_item.get("encrust_tags", [])
	for tag_text in encrust_definition.get("encrust_with", []):
		if not (tag_text in tags):
			tags.append(tag_text)
	target_item["encrust_tags"] = tags

	var total_instability = int(target_item.get("instability", 0)) + int(encrust_definition.get("instability", 0))
	target_item["instability"] = total_instability

	if not target_item.has("primary_buffs"):
		target_item["primary_buffs"] = []
	_merge_buff_list(target_item["primary_buffs"], encrust_definition.get("primary_buffs", []))

	if not target_item.has("secondary_buffs"):
		target_item["secondary_buffs"] = []
	_merge_buff_list(target_item["secondary_buffs"], encrust_definition.get("secondary_buffs", []))

	if not target_item.has("resist_buffs"):
		target_item["resist_buffs"] = {}
	_merge_buff_map(target_item["resist_buffs"], encrust_definition.get("resist_buffs", {}))

	if not target_item.has("damage_buffs"):
		target_item["damage_buffs"] = {}
	_merge_buff_map(target_item["damage_buffs"], encrust_definition.get("damage_buffs", {}))

	var base_nm = str(target_item.get("base_name", target_item.get("name", "Item")))
	target_item["base_name"] = base_nm
	if applied.size() == 1 and not str(target_item.get("name", "")).begins_with("Encrusted "):
		target_item["name"] = "Encrusted " + base_nm

	var unstable_added = ""
	var unstable_pool = OD.Database.get_unstable_effects()
	if total_instability >= 4 and not unstable_pool.is_empty():
		var proc_chance = min(0.85, float(total_instability) * 0.04)
		if randf() < proc_chance:
			var picked = unstable_pool[randi() % unstable_pool.size()]
			var unstable_list = target_item.get("unstable_effects", [])
			unstable_list.append(picked)
			target_item["unstable_effects"] = unstable_list
			unstable_added = str(picked.get("name", ""))

	var tool_tag = str(encrust_definition.get("tool", ""))
	var toolkit_info = OD.Database.get_toolkit_info(tool_tag)
	if toolkit_info != null and toolkit_info.sound != "":
		OD.Audio.play_sfx(toolkit_info.sound)
	recalculate_stats()
	inventory_changed.emit()
	return {
		ok = true,
		encrust_name = str(encrust_definition.get("name", "")),
		item_name = str(target_item.get("name", "")),
		instability = total_instability,
		unstable_added = unstable_added
	}

func get_active_quests():
	return active_quests.duplicate(true)

func get_completed_quests():
	return completed_quests.duplicate(true)

func add_quest(quest_data):
	if typeof(quest_data) != TYPE_DICTIONARY:
		return false
	var quest_id = str(quest_data.get("id", ""))
	if quest_id == "":
		quest_id = "quest_" + str(active_quests.size() + completed_quests.size() + 1)
	for existing in active_quests:
		if str(existing.get("id", "")) == quest_id:
			return false
	var entry = {
		id = quest_id,
		title = str(quest_data.get("title", "Inconsequentia's Task")),
		giver = str(quest_data.get("giver", "Statue of Inconsequentia")),
		description = str(quest_data.get("description", "")),
		kind = str(quest_data.get("kind", "kill")),
		floor_level = int(quest_data.get("floor_level", 1)),
		progress = int(quest_data.get("progress", 0)),
		target = max(1, int(quest_data.get("target", 1))),
		reward_xp = int(quest_data.get("reward_xp", 0)),
		reward_zorkmids = int(quest_data.get("reward_zorkmids", 0))
	}
	active_quests.append(entry)
	quests_changed.emit()
	return true

func advance_kill_quests(floor_level):
	var completed_now = []
	var changed = false
	for index in range(active_quests.size() - 1, -1, -1):
		var quest = active_quests[index]
		if str(quest.get("kind", "")) != "kill":
			continue
		if int(quest.get("floor_level", floor_level)) != int(floor_level):
			continue
		quest["progress"] = min(int(quest.get("target", 1)), int(quest.get("progress", 0)) + 1)
		changed = true
		if int(quest["progress"]) >= int(quest.get("target", 1)):
			var done_quest = quest.duplicate(true)
			done_quest["completed"] = true
			active_quests.remove_at(index)
			completed_quests.append(done_quest)
			completed_now.append(done_quest)
			if int(done_quest.get("reward_xp", 0)) > 0:
				add_xp(int(done_quest["reward_xp"]))
			if int(done_quest.get("reward_zorkmids", 0)) > 0:
				add_zorkmids(int(done_quest["reward_zorkmids"]))
	if changed:
		quests_changed.emit()
	return completed_now
