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
	
	var centered_container = Panel.new()
	centered_container.set_size(Settings.display_size())
	container.add_child(centered_container)
	var hbox = HBoxContainer.new()
	hbox.anchor_left = .3
	hbox.anchor_top = .2
	hbox.alignment = BoxContainer.ALIGN_CENTER
	centered_container.add_child(hbox)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGN_CENTER
	hbox.add_child(vbox)
	
	var entity_grid = EntityGrid.new()
	entity_grid.init()
	vbox.add_child(entity_grid)
	
	var dungeon = Dungeon.new()
	dungeon.init(entity_grid)
	vbox.add_child(dungeon)
	
	var gui = Control.new()
	vbox.add_child(gui)
	
	Audio.play(assets.music.default)
