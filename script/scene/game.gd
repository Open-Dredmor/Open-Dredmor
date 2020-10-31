extends Node2D

static func init_container():
	return Node2D.new()

var moveable_container

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	# TODO Remove unless testing
	_dev_seed()
	
	var assets = Assets.game()	
	var	container = Scenes.container()
	
	var centered_container = Panel.new()
	centered_container.set_size(Settings.display_size())
	centered_container.name = "CenteredContainer"
	container.add_child(centered_container)
	var hbox = HBoxContainer.new()
	hbox.anchor_left = .3
	hbox.anchor_top = .2
	hbox.alignment = BoxContainer.ALIGN_CENTER
	hbox.name = "HBox"
	centered_container.add_child(hbox)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGN_CENTER
	vbox.name = "VBox"
	hbox.add_child(vbox)
	
	moveable_container = Node2D.new()
	moveable_container.name = "MoveableContainer"
	vbox.add_child(moveable_container)
	
	var dungeon = Dungeon.new()
	dungeon.init()
	dungeon.name = "Dungeon"
	moveable_container.add_child(dungeon)
	
	var gui = Control.new()
	gui.name = "GUI"
	moveable_container.add_child(gui)
	
	Audio.play(assets.music.default)

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

var speed = 200
var drag_enabled = false
var old_position
func _input(ev):
	if ev is InputEventKey and ev.is_pressed():
		if ev.scancode == KEY_LEFT:
			moveable_container.position.x += speed
		if ev.scancode == KEY_RIGHT:
			moveable_container.position.x -= speed
		if ev.scancode == KEY_UP:
			moveable_container.position.y += speed
		if ev.scancode == KEY_DOWN:
			moveable_container.position.y -= speed
	if ev is InputEventMouseButton:
		if ev.button_index == BUTTON_LEFT:
			drag_enabled = ev.pressed
			if ev.pressed:
				old_position = get_global_mouse_position()
		
func _physics_process(_delta):
	if old_position != null and drag_enabled:
		var new_position = get_global_mouse_position()
		var delta_position = new_position - old_position;
		moveable_container.position.x += delta_position.x
		moveable_container.position.y += delta_position.y
		old_position = new_position
