extends Node

# Create a scene where this can be configured

var DungeonsOfDredmorInstallationDir = "D:/bin/steam/steamapps/common/Dungeons of Dredmor/"

func load_image(relative_path):
	var img = Image.new()
	var absolute_path = DungeonsOfDredmorInstallationDir + relative_path
	img.load(absolute_path)
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	return texture

func _ready():
		call_deferred("_load_scene")
	
func _load_scene():
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	current_scene.free()
	var s = ResourceLoader.load("res://MainMenu/MainMenu.tscn")

	current_scene = s.instance()

	root.add_child(current_scene)

	get_tree().set_current_scene(current_scene)	

