extends Control

var selected_dir = null
var directory_picker = null
var error_label = null
var _initial_error = ""

func _ready():
	call_deferred("_init_global_state")		

func _init_global_state():	
	print("Reading config from "+OS.get_user_data_dir())		
	OD.reset()
	OD.Settings.load()
	randomize()	
	var install_directory = OD.Settings.dredmor_install_dir()
	if install_directory == null and OD.Settings._settings != null and OD.Settings._settings.get_value("open_dredmor", "dredmor_install_directory") == null:
		var detected_directory = OD.Settings.detect_default_dredmor_dir()
		if detected_directory != "":
			OD.Settings.change("open_dredmor", "dredmor_install_directory", detected_directory)
			install_directory = OD.Settings.dredmor_install_dir()
	if install_directory != null and install_directory != "":
		var validation = OD.Settings.validate_dredmor_dir(install_directory)
		if validation.valid:
			print("Installation dir set to [" + install_directory + "], load the game.")
			await _finish_bootstrap()
			return
		_initial_error = "Configured installation directory is invalid: " + install_directory + "\nMissing: " + ", ".join(validation.missing)
		print(_initial_error)
	else:
		print("Installation dir not configured, prompt selection.")
	call_deferred("_build_gui")

func _build_gui():
		var bootstrap = get_node("/root/Container")
		bootstrap.set_anchors_preset(Control.PRESET_FULL_RECT)
		bootstrap.set_size(OD.Settings.display_size())
		
		var container = VBoxContainer.new()
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		container.anchor_top = .33
		container.anchor_left = .33
		bootstrap.add_child(container)
		
		var picker_info = Label.new()
		picker_info.text = "Please select the directory where Dungeons of Dredmor is installed."
		picker_info.custom_minimum_size = Vector2(600,100)
		container.add_child(picker_info)
		
		var choose_button = Button.new()
		choose_button.text = "Choose..."
		choose_button.pressed.connect(_on_ChooseButton_pressed)
		container.add_child(choose_button)

		error_label = Label.new()
		error_label.custom_minimum_size = Vector2(600, 120)
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		error_label.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
		error_label.text = _initial_error
		error_label.visible = _initial_error != ""
		container.add_child(error_label)
		
		directory_picker = FileDialog.new()
		directory_picker.access = FileDialog.ACCESS_FILESYSTEM
		directory_picker.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		directory_picker.size = Vector2i(800,800)
		directory_picker.dir_selected.connect(_on_DirectoryPicker_dir_selected)
		bootstrap.add_child(directory_picker)		
	
func _on_ChooseButton_pressed():
	directory_picker.popup_centered()
	pass

func _on_DirectoryPicker_dir_selected(dir):
	var validation = OD.Settings.validate_dredmor_dir(dir)
	if not validation.valid:
		error_label.text = "Invalid Dungeons of Dredmor directory: " + dir + "\nMissing required files: " + ", ".join(validation.missing)
		error_label.visible = true
		return
	error_label.visible = false
	OD.Settings.change("open_dredmor","dredmor_install_directory",dir)
	await _finish_bootstrap()

func _finish_bootstrap():
	if OD.Loading != null:
		OD.Loading.show_progress("Checking asset cache...", 5.0)
	if OD.AssetCache != null:
		await OD.AssetCache.ensure_cache()
	if OD.Loading != null:
		OD.Loading.show_progress("Starting Open Dredmor...", 100.0)
	OD.Scenes.goto(OD.Scenes.FIRST_SCENE)
