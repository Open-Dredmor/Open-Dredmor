extends Control

static func init_container():
	return Control.new()

var _audio_enabled_checkbox = null
var _fullscreen_checkbox = null
var _volume_sliders = {}
var _volume_labels = {}
var _keybind_buttons = {}
var _pending_keybinds = {}
var _listening_action = null

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	var settings_menu = get_node("/root/Container")
	settings_menu.set_size(OD.Settings.display_size())

	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0.2
	scroll.anchor_top = 0.08
	scroll.anchor_right = 0.8
	scroll.anchor_bottom = 0.92
	settings_menu.add_child(scroll)

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 16)
	margin.add_child(container)

	var title_label = Label.new()
	title_label.text = "Settings"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title_label)

	_audio_enabled_checkbox = CheckBox.new()
	_audio_enabled_checkbox.text = "Audio Enabled"
	_audio_enabled_checkbox.button_pressed = OD.Settings.audio_enabled()
	container.add_child(_audio_enabled_checkbox)

	_add_volume_slider(container, "master", "Master Volume", OD.Settings.master_volume_percent())
	_add_volume_slider(container, "music", "Music Volume", OD.Settings.music_volume_percent())
	_add_volume_slider(container, "sfx", "Sound (SFX) Volume", OD.Settings.sfx_volume_percent())
	_add_volume_slider(container, "dialogue", "Dialogue Volume", OD.Settings.dialogue_volume_percent())

	_fullscreen_checkbox = CheckBox.new()
	_fullscreen_checkbox.text = "Fullscreen"
	_fullscreen_checkbox.button_pressed = OD.Settings.fullscreen_enabled()
	container.add_child(_fullscreen_checkbox)

	var keybinds_header = Label.new()
	keybinds_header.text = "Keybinds (click to rebind)"
	container.add_child(keybinds_header)

	_pending_keybinds = OD.Settings.get_keybinds()
	var keybind_grid = GridContainer.new()
	keybind_grid.columns = 2
	keybind_grid.add_theme_constant_override("h_separation", 24)
	keybind_grid.add_theme_constant_override("v_separation", 8)
	container.add_child(keybind_grid)

	var action_names = _pending_keybinds.keys()
	action_names.sort()
	for action_name in action_names:
		var action_label = Label.new()
		action_label.text = action_name.replace("_", " ").capitalize()
		keybind_grid.add_child(action_label)

		var bind_btn = Button.new()
		bind_btn.custom_minimum_size = Vector2(180, 32)
		bind_btn.text = OS.get_keycode_string(_pending_keybinds[action_name])
		bind_btn.pressed.connect(_on_keybind_button_pressed.bind(action_name))
		keybind_grid.add_child(bind_btn)
		_keybind_buttons[action_name] = bind_btn

	var choose_container = HBoxContainer.new()
	choose_container.add_theme_constant_override("separation", 16)
	container.add_child(choose_container)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(160, 48)
	cancel_button.pressed.connect(_on_CancelButton_pressed)
	choose_container.add_child(cancel_button)

	var save_button = Button.new()
	save_button.text = "Save"
	save_button.custom_minimum_size = Vector2(160, 48)
	save_button.pressed.connect(_on_SaveButton_pressed)
	choose_container.add_child(save_button)

	var forget_installation_dir_button = Button.new()
	forget_installation_dir_button.text = "Forget Installation Directory"
	forget_installation_dir_button.custom_minimum_size = Vector2(260, 48)
	forget_installation_dir_button.pressed.connect(_on_ForgetInstallationDirButton_pressed)
	choose_container.add_child(forget_installation_dir_button)

func _add_volume_slider(parent, key, label_text, initial_value):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(200, 0)
	row.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_volume_slider_changed.bind(key))
	row.add_child(slider)

	var value_label = Label.new()
	value_label.text = str(int(initial_value)) + "%"
	value_label.custom_minimum_size = Vector2(56, 0)
	row.add_child(value_label)

	_volume_sliders[key] = slider
	_volume_labels[key] = value_label

func _on_volume_slider_changed(value, key):
	_volume_labels[key].text = str(int(value)) + "%"
	OD.Audio.apply_preview_volumes(
		_volume_sliders["master"].value,
		_volume_sliders["music"].value,
		_volume_sliders["sfx"].value,
		_volume_sliders["dialogue"].value
	)

func _on_keybind_button_pressed(action_name):
	if _listening_action != null and _keybind_buttons.has(_listening_action):
		_keybind_buttons[_listening_action].text = OS.get_keycode_string(_pending_keybinds[_listening_action])
	_listening_action = action_name
	_keybind_buttons[action_name].text = "Press a key..."

func _input(event):
	if _listening_action == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode != KEY_ESCAPE:
			_pending_keybinds[_listening_action] = event.keycode
		_keybind_buttons[_listening_action].text = OS.get_keycode_string(_pending_keybinds[_listening_action])
		_listening_action = null
		get_viewport().set_input_as_handled()

func _persist_settings():
	var audio_enabled = _audio_enabled_checkbox.is_pressed()
	OD.Settings.change("game", "audio_enabled", audio_enabled)
	OD.Settings.change("game", "audio_volume_master_percent", int(_volume_sliders["master"].value))
	OD.Settings.change("game", "audio_volume_music_percent", int(_volume_sliders["music"].value))
	OD.Settings.change("game", "audio_volume_sfx_percent", int(_volume_sliders["sfx"].value))
	OD.Settings.change("game", "audio_volume_dialogue_percent", int(_volume_sliders["dialogue"].value))
	OD.Settings.change("display", "fullscreen", _fullscreen_checkbox.is_pressed())
	for action_name in _pending_keybinds.keys():
		OD.Settings.change("controls", action_name, int(_pending_keybinds[action_name]))
	OD.Settings.apply_display_settings()
	OD.Settings.apply_keybinds()
	OD.Audio.apply_volume_settings()
	if not audio_enabled:
		OD.Audio.stop()

func _on_SaveButton_pressed():
	_persist_settings()
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)

func _on_CancelButton_pressed():
	OD.Audio.apply_volume_settings()
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)

func _on_ForgetInstallationDirButton_pressed():
	OD.Settings.change("open_dredmor", "dredmor_install_directory", "")
	OD.Load.clear_cache()
	OD.Scenes.goto(OD.Scenes.BOOTSTRAP)
