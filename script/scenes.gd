extends Node

var Bootstrap = "res://scenes/Bootstrap/Bootstrap.tscn"
var DifficultyMenu = "res://scene/DifficultyMenu/DifficultyMenu.tscn"
var MainMenu = "res://scene/MainMenu/MainMenu.tscn"
var SettingsMenu = "res://scene/SettingsMenu/SettingsMenu.tscn"

func goto(scene_path):
	call_deferred("_load_scene", scene_path)
	
func _load_scene(scene_path):
	return get_tree().change_scene(scene_path)

