extends Control

static func init_container():
	return Control.new()

var audio_enabled_checkbox;

func _ready():
	call_deferred("_build_gui")
	
func _build_gui():
	var settings_menu = get_node("/root/Container")
	settings_menu.set_size(OD.Settings.display_size())

	var container = VBoxContainer.new()
	container.anchor_top = .25
	container.anchor_left = .25	
	settings_menu.add_child(container)

	var audio_enabled_container = HBoxContainer.new()
	container.add_child(audio_enabled_container)

	var audio_enabled_label = Label.new()
	audio_enabled_label.text = "Audio Enabled?"
	audio_enabled_container.add_child(audio_enabled_label)
	
	audio_enabled_checkbox = CheckBox.new()
	audio_enabled_checkbox.pressed = OD.Settings.audio_enabled()
	audio_enabled_container.add_child(audio_enabled_checkbox)

	var choose_container = HBoxContainer.new()
	container.add_child(choose_container)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.rect_min_size = Vector2(200,100)
	cancel_button.connect("pressed",self,"_on_CancelButton_pressed")
	choose_container.add_child(cancel_button)
	
	var save_button = Button.new()
	save_button.text = "Save"
	save_button.rect_min_size = Vector2(200,100)
	save_button.connect("pressed",self,"_on_SaveButton_pressed")
	choose_container.add_child(save_button)
	
	var actions = VBoxContainer.new()
	container.add_child(actions)
	
	var forget_installation_dir_button = Button.new()
	forget_installation_dir_button.text = "Forget Installation Directory"
	forget_installation_dir_button.rect_min_size = Vector2(400,200)
	forget_installation_dir_button.connect("pressed",self,"_on_ForgetInstallationDirButton_pressed")
	actions.add_child(forget_installation_dir_button)

func _persist_settings():
	var audio_enabled = audio_enabled_checkbox.is_pressed()
	OD.Settings.change("game", "audio_enabled", audio_enabled)
	if ! audio_enabled:
		OD.Audio.stop()

func _on_SaveButton_pressed():
	_persist_settings()
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)

func _on_CancelButton_pressed():
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)

func _on_ForgetInstallationDirButton_pressed():
	OD.Settings.change("open_dredmor","dredmor_install_directory","")
	OD.Load.clear_cache()
	OD.Scenes.goto(OD.Scenes.BOOTSTRAP)
