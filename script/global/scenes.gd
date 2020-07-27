extends Node

var BOOTSTRAP = "Bootstrap"
var CHARACTER_MENU = "CharacterMenu"
var DIFFICULTY_MENU = "DifficultyMenu"
var MAIN_MENU = "MainMenu"
var PRELOAD_ASSETS = "PreloadAssets"
var SETTINGS_MENU = "SettingsMenu"
var SKILLS_MENU = "SkillsMenu"
var SPRITE_TEST = "SpriteTest"

func quit():
	get_tree().quit()

func goto(scene_name):
	var scene_path = "res://scene/"+scene_name+"/"+scene_name+".tscn"
	call_deferred("_load_scene", scene_path)
	
func _load_scene(scene_path):
	return get_tree().change_scene(scene_path)

