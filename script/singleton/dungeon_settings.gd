extends Node

var _settings = null

enum Difficulty {
	Easy,
	Medium,
	Hard
}

func reset():
	_settings = {
		difficulty = Difficulty.Medium,
		no_time_to_grind = false,
		permadeath = false,
		hero = 'hero',
		name = "Name",
		player_start_x = 4,
		player_start_y = 3,
		seconds_per_action = .5
	}

func set_difficulty(difficulty):
	_settings.difficulty = difficulty

func set_permadeath(enabled):
	_settings.permadeath = enabled
	
func set_no_time_to_grind(enabled):
	_settings.no_time_to_grind = enabled

func set_name(name):
	_settings.name = name

func set_hero(hero):
	_settings.hero = hero

func set_starting_skill_ids(skills):
	_settings.starting_skill_ids = skills

func get_settings():
	return _settings
