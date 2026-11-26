extends Control

static func init_container():
	return Control.new()

const INK_COLOR = Color(0.16, 0.10, 0.06)
const HEADER_INK = Color(0.28, 0.12, 0.05)

var _fullscreen_checkbox = null
var _graphical_cursor_checkbox = null
var _skip_intro_checkbox = null
var _volume_sliders = {}
var _volume_labels = {}
var _keybind_buttons = {}
var _gamepad_buttons = {}
var _pending_keybinds = {}
var _pending_gamepad_binds = {}
var _listening_action = null
var _listening_mode = ""
var _font_result = null
var _blank_texture = null

func _ready():
	call_deferred("_build_gui")

func _create_parchment_style(background_texture):
	if background_texture != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = background_texture
		style_box.texture_margin_left = 32
		style_box.texture_margin_right = 32
		style_box.texture_margin_top = 32
		style_box.texture_margin_bottom = 32
		style_box.content_margin_left = 40
		style_box.content_margin_right = 40
		style_box.content_margin_top = 34
		style_box.content_margin_bottom = 34
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = Color(0.86, 0.79, 0.67, 1.0)
	fallback.border_color = Color(0.45, 0.34, 0.24, 1.0)
	fallback.set_border_width_all(3)
	fallback.set_content_margin_all(28)
	return fallback

func _style_label(label, font_size, color = INK_COLOR):
	if _font_result != null:
		label.add_theme_font_override("font", _font_result)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style_checkbox(check):
	if _font_result != null:
		check.add_theme_font_override("font", _font_result)
	check.add_theme_font_size_override("font_size", 20)
	check.add_theme_color_override("font_color", INK_COLOR)
	check.add_theme_color_override("font_hover_color", INK_COLOR)
	check.add_theme_color_override("font_pressed_color", INK_COLOR)
	check.add_theme_color_override("font_focus_color", INK_COLOR)
	check.add_theme_color_override("font_hover_pressed_color", INK_COLOR)
	var transparent = StyleBoxFlat.new()
	transparent.bg_color = Color(0, 0, 0, 0)
	check.add_theme_stylebox_override("normal", transparent)
	check.add_theme_stylebox_override("hover", transparent)
	check.add_theme_stylebox_override("pressed", transparent)
	check.add_theme_stylebox_override("focus", transparent)
	check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	OD.Chrome.attach_focus_ring(check)

func _style_slider(slider):
	var track = StyleBoxFlat.new()
	track.bg_color = Color(0.46, 0.36, 0.25, 0.85)
	track.border_color = Color(0.28, 0.20, 0.12, 1.0)
	track.set_border_width_all(1)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.68, 0.50, 0.22, 1.0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	OD.Chrome.attach_focus_ring(slider)

func _build_gui():
	var load_assets = OD.Assets.load_game_menu()
	var dialog_assets = OD.Assets.dialog()
	_font_result = dialog_assets.font if dialog_assets != null and dialog_assets.font != null else load_assets.fonts.default
	_blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var parchment_background = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null

	var settings_menu = get_node("/root/Container")
	settings_menu.set_size(OD.Settings.display_size())

	if OD.Load.exists("ui/menus/bg_stonetile.png"):
		var background_tile = TextureRect.new()
		background_tile.texture = OD.Load.image("ui/menus/bg_stonetile.png")
		background_tile.stretch_mode = TextureRect.STRETCH_TILE
		background_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		settings_menu.add_child(background_tile)

	var header_background = TextureRect.new()
	header_background.texture = load_assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.size = Vector2(OD.Settings.display_size().x, header_background.texture.get_height())
	settings_menu.add_child(header_background)

	var back_button = OD.Chrome.button(load_assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.offset_left = 0
	back_button.offset_top = 0
	back_button.pressed.connect(_on_CancelButton_pressed)
	settings_menu.add_child(back_button)

	var header_title = Label.new()
	header_title.text = "Settings"
	header_title.anchor_left = 0.5
	header_title.offset_left = -160
	header_title.offset_top = 12
	header_title.custom_minimum_size = Vector2(320, 48)
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_result != null:
		header_title.add_theme_font_override("font", _font_result)
	header_title.add_theme_font_size_override("font_size", 34)
	header_title.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80))
	header_title.add_theme_constant_override("outline_size", 3)
	header_title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03))
	settings_menu.add_child(header_title)

	var done_button = OD.Chrome.button(load_assets.textures.done_button)
	done_button.anchor_left = 1
	done_button.anchor_top = 0
	done_button.offset_left = -done_button.texture_normal.get_width()
	done_button.offset_top = 0
	done_button.pressed.connect(_on_SaveButton_pressed)
	settings_menu.add_child(done_button)

	var panel = PanelContainer.new()
	panel.anchor_left = 0.16
	panel.anchor_top = 0.14
	panel.anchor_right = 0.84
	panel.anchor_bottom = 0.93
	panel.add_theme_stylebox_override("panel", _create_parchment_style(parchment_background))
	settings_menu.add_child(panel)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 14)
	scroll.add_child(container)

	var audio_header = Label.new()
	audio_header.text = "Audio & Display"
	_style_label(audio_header, 24, HEADER_INK)
	container.add_child(audio_header)

	_add_volume_slider(container, "master", "Master Volume", OD.Settings.master_volume_percent())
	_add_volume_slider(container, "music", "Music Volume", OD.Settings.music_volume_percent())
	_add_volume_slider(container, "sfx", "Sound (SFX) Volume", OD.Settings.sfx_volume_percent())
	_add_volume_slider(container, "dialogue", "Dialogue Volume", OD.Settings.dialogue_volume_percent())

	_fullscreen_checkbox = CheckBox.new()
	_fullscreen_checkbox.text = "Fullscreen"
	_fullscreen_checkbox.button_pressed = OD.Settings.fullscreen_enabled()
	_style_checkbox(_fullscreen_checkbox)
	container.add_child(_fullscreen_checkbox)

	_graphical_cursor_checkbox = CheckBox.new()
	_graphical_cursor_checkbox.text = "Use Graphical Cursor"
	_graphical_cursor_checkbox.button_pressed = OD.Settings.graphical_cursor_enabled()
	_style_checkbox(_graphical_cursor_checkbox)
	container.add_child(_graphical_cursor_checkbox)

	_skip_intro_checkbox = CheckBox.new()
	_skip_intro_checkbox.text = "Skip Intro Story Screens"
	_skip_intro_checkbox.button_pressed = OD.Settings.skip_intro_enabled()
	_style_checkbox(_skip_intro_checkbox)
	container.add_child(_skip_intro_checkbox)

	var keybinds_header = Label.new()
	keybinds_header.text = "Keybinds (click to rebind)"
	_style_label(keybinds_header, 24, HEADER_INK)
	container.add_child(keybinds_header)

	_pending_keybinds = OD.Settings.get_keybinds()
	_pending_gamepad_binds = OD.Settings.get_gamepad_binds()
	var keybind_grid = GridContainer.new()
	keybind_grid.columns = 3
	keybind_grid.add_theme_constant_override("h_separation", 24)
	keybind_grid.add_theme_constant_override("v_separation", 8)
	container.add_child(keybind_grid)

	for column_title in ["Action", "Keyboard", "Gamepad"]:
		var header_label = Label.new()
		header_label.text = column_title
		_style_label(header_label, 20, HEADER_INK)
		keybind_grid.add_child(header_label)

	var action_names = _pending_keybinds.keys()
	action_names.sort()
	for action_name in action_names:
		var action_label = Label.new()
		action_label.text = action_name.replace("_", " ").capitalize()
		action_label.custom_minimum_size = Vector2(200, 0)
		_style_label(action_label, 19)
		keybind_grid.add_child(action_label)

		var bind_button = OD.Chrome.parchment_button(
			OS.get_keycode_string(_pending_keybinds[action_name]),
			_font_result,
			INK_COLOR,
			_blank_texture,
			18
		)
		bind_button.custom_minimum_size = Vector2(180, 34)
		bind_button.pressed.connect(_on_keybind_button_pressed.bind(action_name, "keyboard"))
		keybind_grid.add_child(bind_button)
		_keybind_buttons[action_name] = bind_button

		var gamepad_code = _pending_gamepad_binds.get(action_name, -1)
		var gamepad_text = OD.Settings.gamepad_button_name(gamepad_code) if gamepad_code >= 0 else "Unbound"
		var gamepad_button = OD.Chrome.parchment_button(
			gamepad_text,
			_font_result,
			INK_COLOR,
			_blank_texture,
			18
		)
		gamepad_button.custom_minimum_size = Vector2(180, 34)
		gamepad_button.disabled = gamepad_code < 0
		gamepad_button.pressed.connect(_on_keybind_button_pressed.bind(action_name, "gamepad"))
		keybind_grid.add_child(gamepad_button)
		_gamepad_buttons[action_name] = gamepad_button

	var choose_container = HBoxContainer.new()
	choose_container.add_theme_constant_override("separation", 16)
	container.add_child(choose_container)

	var cancel_button = OD.Chrome.parchment_button("Cancel", _font_result, INK_COLOR, _blank_texture, 18)
	cancel_button.custom_minimum_size = Vector2(150, 40)
	cancel_button.pressed.connect(_on_CancelButton_pressed)
	choose_container.add_child(cancel_button)

	var save_button = OD.Chrome.parchment_button("Save", _font_result, INK_COLOR, _blank_texture, 18)
	save_button.custom_minimum_size = Vector2(150, 40)
	save_button.pressed.connect(_on_SaveButton_pressed)
	choose_container.add_child(save_button)

	var forget_installation_direction_button = OD.Chrome.parchment_button("Forget Installation Directory", _font_result, INK_COLOR, _blank_texture, 18)
	forget_installation_direction_button.custom_minimum_size = Vector2(280, 40)
	forget_installation_direction_button.pressed.connect(_on_ForgetInstallationDirButton_pressed)
	choose_container.add_child(forget_installation_direction_button)

	_volume_sliders["master"].call_deferred("grab_focus")

func _unhandled_input(event):
	if _listening_action != null:
		return
	if (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_CancelButton_pressed()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		get_viewport().set_input_as_handled()
		_on_SaveButton_pressed()

func _add_volume_slider(parent, key, label_text, initial_value):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(210, 0)
	_style_label(label, 19)
	row.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(slider)
	slider.value_changed.connect(_on_volume_slider_changed.bind(key))
	row.add_child(slider)

	var value_label = Label.new()
	value_label.text = str(int(initial_value)) + "%"
	value_label.custom_minimum_size = Vector2(60, 0)
	_style_label(value_label, 19)
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

func _restore_listening_button_text():
	if _listening_action == null:
		return
	if _listening_mode == "gamepad" and _gamepad_buttons.has(_listening_action):
		_gamepad_buttons[_listening_action].text = OD.Settings.gamepad_button_name(_pending_gamepad_binds[_listening_action])
	elif _keybind_buttons.has(_listening_action):
		_keybind_buttons[_listening_action].text = OS.get_keycode_string(_pending_keybinds[_listening_action])

func _on_keybind_button_pressed(action_name, mode = "keyboard"):
	_restore_listening_button_text()
	_listening_action = action_name
	_listening_mode = mode
	if mode == "gamepad":
		_gamepad_buttons[action_name].text = "Press a button..."
	else:
		_keybind_buttons[action_name].text = "Press a key..."

func _input(event):
	if _listening_action == null:
		return
	if _listening_mode == "gamepad":
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_restore_listening_button_text()
			_listening_action = null
			_listening_mode = ""
			get_viewport().set_input_as_handled()
			return
		if event is InputEventJoypadButton and event.pressed:
			_pending_gamepad_binds[_listening_action] = event.button_index
			_restore_listening_button_text()
			_listening_action = null
			_listening_mode = ""
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode != KEY_ESCAPE:
			_pending_keybinds[_listening_action] = event.keycode
		_restore_listening_button_text()
		_listening_action = null
		_listening_mode = ""
		get_viewport().set_input_as_handled()

func _persist_settings():
	OD.Settings.change("game", "audio_volume_master_percent", int(_volume_sliders["master"].value))
	OD.Settings.change("game", "audio_volume_music_percent", int(_volume_sliders["music"].value))
	OD.Settings.change("game", "audio_volume_sfx_percent", int(_volume_sliders["sfx"].value))
	OD.Settings.change("game", "audio_volume_dialogue_percent", int(_volume_sliders["dialogue"].value))
	OD.Settings.change("display", "fullscreen", _fullscreen_checkbox.is_pressed())
	OD.Settings.change("display", "graphical_cursor", _graphical_cursor_checkbox.is_pressed())
	OD.Settings.change("game", "skip_intro", _skip_intro_checkbox.is_pressed())
	for action_name in _pending_keybinds.keys():
		OD.Settings.change("controls", action_name, int(_pending_keybinds[action_name]))
	for action_name in _pending_gamepad_binds.keys():
		OD.Settings.change("gamepad_controls", action_name, int(_pending_gamepad_binds[action_name]))
	OD.Settings.apply_display_settings()
	OD.Settings.apply_keybinds()
	OD.Audio.apply_volume_settings()

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
