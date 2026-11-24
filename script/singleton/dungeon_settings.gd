extends Node

var _settings = null
var _packs_initialized = false

enum Difficulty {
	Easy,
	Medium,
	Hard
}

func reset():
	var default_packs = []
	if OD.Settings != null and OD.Settings._settings != null:
		for pack_info in OD.Settings.get_available_content_packs():
			if pack_info.kind == "expansion":
				default_packs.append(pack_info.id)
	_settings = {
		difficulty = Difficulty.Medium,
		no_time_to_grind = false,
		permadeath = false,
		hero = null,
		name = "",
		starting_skill_ids = [],
		player_start_x = 4,
		player_start_y = 6,
		seconds_per_action = .5,
		active_packs = default_packs
	}

func set_difficulty(difficulty):
	_settings.difficulty = difficulty

func set_permadeath(enabled):
	_settings.permadeath = enabled
	
func set_no_time_to_grind(enabled):
	_settings.no_time_to_grind = enabled

func set_character_name(character_name):
	_settings.name = character_name

func set_hero(hero):
	_settings.hero = hero

func set_starting_skill_ids(skills):
	_settings.starting_skill_ids = skills

func set_active_packs(pack_ids):
	_packs_initialized = true
	_settings.active_packs = pack_ids.duplicate()

func has_initialized_packs():
	return _packs_initialized

func get_active_packs():
	return _settings.active_packs

func get_settings():
	return _settings
