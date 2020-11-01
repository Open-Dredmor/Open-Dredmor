extends Control

static func init_container():
	return Control.new()
	
var first_scene = OD.Scenes.MAIN_MENU

var _progress_label = null
var _progress_percent = null
var _progress_bar = null
var _gui_ready = false
var _stage_index = 0

var stages = [
	null,
	"audio",
	"database",
	"main_menu",
	"difficulty_menu",
	"skills_menu",
	"character_menu",
	"finalize"
]

func _ready():
	call_deferred("_build_gui")

func _process(_delta):
	if _gui_ready and _stage_index < stages.size():
		_progress_label.text = _preload(stages[_stage_index])
		_progress_bar.value = round(float(_stage_index + 1) / float(stages.size()) * 100)
		_stage_index += 1		
		if _stage_index == stages.size():
			OD.Scenes.goto(first_scene)			

func _build_gui():
	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())
	
	var columns = HBoxContainer.new()
	columns.anchor_bottom = 1
	columns.anchor_right = 1
	columns.alignment = BoxContainer.ALIGN_CENTER
	container.add_child(columns)
	
	var stack = VBoxContainer.new()
	stack.anchor_bottom = 1
	stack.anchor_right = 1
	stack.alignment = BoxContainer.ALIGN_CENTER
	stack.margin_left = 50
	stack.margin_right = -50
	columns.add_child(stack)
	
	var loading_label = Label.new()
	loading_label.text = "Loading..."
	loading_label.align = Label.ALIGN_CENTER
	stack.add_child(loading_label)
	
	_progress_label = Label.new()
	_progress_label.rect_min_size = Vector2(400,100)
	_progress_label.align = Label.ALIGN_CENTER
	stack.add_child(_progress_label)
	
	_progress_bar = ProgressBar.new()
	_progress_bar.rect_min_size = Vector2(400,100)
	stack.add_child(_progress_bar)
	
	_gui_ready = true		
		
func _preload(stage):
	match stage:
		null:
			return "Preparing audio manager"
		"audio":
			OD.Audio.setup(get_tree().get_root())
			return "Ingesting database files"			
		"database":
			OD.Database.ingest()
			return "Loading main menu assets"			
		"main_menu":
			OD.Assets.main_menu()
			return "Loading difficulty menu assets"
		"difficulty_menu":
			OD.Assets.difficulty_menu()
			return "Loading skills menu assets"
		"skills_menu":
			OD.Assets.skills_menu()
			return "Loading character_menu"
		"character_menu":
			OD.Assets.character_menu()
			return "Asset preload complete" 
		"finalize":
			return "Asset preload complete"
		_:
			print("Unhandled preload stage [" + stage + "]")
			OD.Scenes.quit()
			return null
