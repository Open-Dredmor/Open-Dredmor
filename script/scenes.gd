extends Node

var MainMenu = "res://scene/MainMenu/MainMenu.tscn"

func goto(scene_path):
	call_deferred("_load_scene", scene_path)
	
func _load_scene(scene_path):
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	current_scene.free()
	var s = ResourceLoader.load(scene_path)
	current_scene = s.instance()
	root.add_child(current_scene)
	get_tree().set_current_scene(current_scene)	

