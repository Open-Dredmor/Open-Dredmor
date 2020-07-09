extends Control

var selected_dir = null

func _ready():
	print("Reading config from "+OS.get_user_data_dir())
	Settings.load()
	var install_dir = Settings.dredmor_install_dir()
	if install_dir != null:
		Scenes.goto(Scenes.MainMenu)

func _on_DredmorPickerButton_pressed():
	$DredmorPicker.popup()
	pass

func _on_DredmorPicker_dir_selected(dir):
	# TODO Some validation around whether or not the chosen dir is actually a Dredmor installation
	# TODO Preload all assets into a bundle?
	Settings.change("open_dredmor","dredmor_install_directory",dir)
	Scenes.goto(Scenes.MainMenu)
	pass
