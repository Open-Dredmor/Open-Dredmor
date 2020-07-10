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
		permadeath = false
	}

func set_difficulty(difficulty):
	_settings.difficulty = difficulty

func set_permadeath(enabled):
	_settings.permadeath = enabled
	
func set_no_time_to_grind(enabled):
	_settings.no_time_to_grind = enabled

func get_settings():
	return _settings
