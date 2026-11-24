extends "res://script/instance/entity/entity.gd"

const CombatResolverScript = preload("res://script/instance/combat/combat_resolver.gd")

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

var _idle_sprites = {}
var _attack_sprites = {}
var _hit_sprites = {}
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
	monster_level = int(monster_def.get("level", 0))
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
