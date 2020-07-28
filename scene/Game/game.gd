extends Node2D

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	var assets = Assets.game()
	var container = get_node("/root/Container")
	#container.set_size(Settings.display_size())	
	
	var background = Node2D.new()
	container.add_child(background)
	
	var foreground = Node2D.new()
	container.add_child(foreground)
	
	var gui = Control.new()
	container.add_child(gui)
	
	Audio.play(assets.music.default)
