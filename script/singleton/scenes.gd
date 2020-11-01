extends Node

var BOOTSTRAP = "Bootstrap"
var CHARACTER_MENU = "character_menu"
var DIFFICULTY_MENU = "difficulty_menu"
var GAME = "game"
var INTRO_ONE = "intro_one"
var INTRO_TWO = "intro_two"
var MAIN_MENU = "main_menu"
var PRELOAD_ASSETS = "preload_assets"
var SETTINGS_MENU = "settings_menu"
var SKILLS_MENU = "skills_menu"
var SPRITE_TEST = "sprite_test"

# For debugging specific levels or gameplay features
var FIRST_SCENE = GAME 

# For experiencing the game as a player would see it
#var FIRST_SCENE = PRELOAD_ASSETS 

func quit():
	get_tree().quit()

func goto(scene_name):
	if scene_name == BOOTSTRAP:
		return call_deferred("bootstrap_again")
	var scene_path = "res://script/scene/" + scene_name + ".gd"
	call_deferred("_load_scene", scene_path)

func container():
	return get_node("/root/Container")

func bootstrap_again():
	var root = get_node('/root')	
	var last_scene = root.get_node("Container")
	root.remove_child(last_scene)
	last_scene.call_deferred("free")
	return get_tree().change_scene("res://scene/Bootstrap/Bootstrap.tscn")

func _load_scene(scene_path):
	var root = get_node('/root')	
	var last_scene = root.get_node("Container")
	root.remove_child(last_scene)
	last_scene.call_deferred("free")
	
	var scene_script = load(scene_path)
	var current_scene_logic = scene_script.new()
	var current_container = current_scene_logic.init_container()
	current_container.name = "Container"
	current_container.set_script(scene_script)
	root.add_child(current_container)
