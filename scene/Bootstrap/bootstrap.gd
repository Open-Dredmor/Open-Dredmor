extends Control

var first_scene = Scenes.GAME
#var first_scene = Scenes.PRELOAD_ASSETS

var selected_dir = null
var directory_picker = null

func _ready():
	call_deferred("_init_global_state")		

func _init_global_state():
	print("Reading config from "+OS.get_user_data_dir())	
	Settings.load()
	randomize()	
	var install_dir = Settings.dredmor_install_dir()
	if install_dir != null and install_dir != "":
		print("Installation dir set to [" + install_dir + "], load the game.")
		Scenes.goto(first_scene)
	else:
		print("Installation dir not configured, prompt selection.")
		call_deferred("_build_gui")

func _build_gui():
		var bootstrap = get_node("/root/Container")
		bootstrap.set_size(Settings.display_size())
		
		var container = VBoxContainer.new()
		container.alignment = BoxContainer.ALIGN_CENTER
		container.anchor_top = .33
		container.anchor_left = .33
		bootstrap.add_child(container)
		
		var picker_info = Label.new()
		picker_info.text = "Please select the directory where Dungeons of Dredmor is installed."
		picker_info.rect_min_size = Vector2(600,300)
		container.add_child(picker_info)
		
		var choose_button = Button.new()
		choose_button.text = "Choose..."
		choose_button.connect("pressed", self, "_on_ChooseButton_pressed")
		container.add_child(choose_button)
		
		directory_picker = FileDialog.new()
		directory_picker.access = FileDialog.ACCESS_FILESYSTEM
		directory_picker.mode = FileDialog.MODE_OPEN_DIR
		directory_picker.rect_min_size = Vector2(800,800)
		directory_picker.anchor_top = .1
		directory_picker.anchor_left = .1
		directory_picker.connect("dir_selected", self, "_on_DirectoryPicker_dir_selected")
		bootstrap.add_child(directory_picker)		
	
func _on_ChooseButton_pressed():
	directory_picker.popup()
	pass

func _on_DirectoryPicker_dir_selected(dir):
	# TODO Some validation around whether or not the chosen dir is actually a Dredmor installation
	Settings.change("open_dredmor","dredmor_install_directory",dir)
	Scenes.goto(first_scene)
	pass
