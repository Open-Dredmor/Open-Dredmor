extends Node

var MainMenu = "res://scene/MainMenu/MainMenu.tscn"
var DifficultyMenu = "res://scene/DifficultyMenu/DifficultyMenu.tscn"

func goto(scene_path):
	call_deferred("_load_scene", scene_path)
	
func _load_scene(scene_path):
	return get_tree().change_scene(scene_path)

