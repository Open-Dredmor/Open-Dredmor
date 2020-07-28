extends Node2D

func _ready():
	call_deferred("_build_ui")

func _dev_seed():
	Audio.setup(get_tree().get_root())
	Database.ingest()
	DungeonSettings.reset()
	DungeonSettings.set_difficulty(DungeonSettings.Difficulty.Medium)
	DungeonSettings.set_permadeath(false)
	DungeonSettings.set_no_time_to_grind(false)
	DungeonSettings.set_hero("heroine")
	DungeonSettings.set_name("Eyebrows")
	DungeonSettings.set_starting_skill_ids([0,1,2,3,4,5,6])

func _build_ui():
	_dev_seed()
	
	var assets = Assets.game()
	var container = get_node("/root/Container")
	
	var dungeon = Dungeon.new()
	container.add_child(dungeon)
	
	var background = Node2D.new()
	container.add_child(background)
	
	var foreground = Node2D.new()
	container.add_child(foreground)
	
	var gui = Control.new()
	container.add_child(gui)
	
	Audio.play(assets.music.default)
