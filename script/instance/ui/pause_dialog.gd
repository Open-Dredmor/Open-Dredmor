extends CanvasLayer

class_name PauseDialog

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

var _callbacks = {}
var _showing_settings = false
var _panel = null
var _content_box = null

func init(callbacks = {}):
	_callbacks = callbacks
	layer = 14
	_build_ui()
	_connect_signals()
	_rebuild_content()
	return self

func _connect_signals():
	var viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_panel_bounds):
		viewport.size_changed.connect(_update_panel_bounds)

func _create_panel_style():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var background_texture = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	return UiHelpers.create_panel_style(
		background_texture,
		44,
		{ left = 36, right = 36, top = 30, bottom = 32 },
		Color(0.14, 0.11, 0.09, 0.95),
		Color(0.6, 0.48, 0.3, 0.95),
		2,
		24
	)

func _build_ui():
	var overlay = UiHelpers.create_modal_overlay(self, 0.55)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.backdrop.add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(_panel)
	_update_panel_bounds()

	_content_box = VBoxContainer.new()
	_content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_box.add_theme_constant_override("separation", 12)
	_panel.add_child(_content_box)

func _update_panel_bounds():
	if _panel == null or not is_instance_valid(_panel):
		return
	var current_viewport_size = UiHelpers.viewport_size(self)
	var panel_width = clamp(current_viewport_size.x * 0.34, 340.0, 480.0)
	var panel_height = clamp(current_viewport_size.y * 0.44, 280.0, 420.0)
	_panel.custom_minimum_size = Vector2(panel_width, panel_height)

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _showing_settings:
				_showing_settings = false
				_rebuild_content()
			else:
				dismiss()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M and not _showing_settings:
			dismiss()
			get_viewport().set_input_as_handled()

func dismiss():
	UiHelpers.invoke_callback(_callbacks, "on_close")
	queue_free()

func _rebuild_content():
	if _content_box == null or not is_instance_valid(_content_box):
		return
	UiHelpers.clear_children(_content_box)

	if _showing_settings:
		_build_settings_view()
	else:
		_build_main_menu_view()

func _build_main_menu_view():
	var title = Label.new()
	title.text = "Game Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiHelpers.style_label(title, 26, Color(0.22, 0.14, 0.08))
	_content_box.add_child(title)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)
	var font = UiHelpers.dialog_font()

	var resume_button = OD.Chrome.parchment_button("Resume", font, ink_color, blank_texture, 18)
	resume_button.pressed.connect(dismiss)
	_content_box.add_child(resume_button)

	var save_button = OD.Chrome.parchment_button("Save Game", font, ink_color, blank_texture, 18)
	save_button.pressed.connect(_on_save_pressed)
	_content_box.add_child(save_button)

	var save_quit_button = OD.Chrome.parchment_button("Save & Quit", font, ink_color, blank_texture, 18)
	save_quit_button.pressed.connect(_on_save_and_quit_pressed)
	_content_box.add_child(save_quit_button)

	var settings_button = OD.Chrome.parchment_button("Settings", font, ink_color, blank_texture, 18)
	settings_button.pressed.connect(func():
		_showing_settings = true
		_rebuild_content()
	)
	_content_box.add_child(settings_button)

	var main_button = OD.Chrome.parchment_button("Main Menu", font, ink_color, blank_texture, 18)
	main_button.pressed.connect(func():
		dismiss()
		OD.Scenes.goto(OD.Scenes.MAIN_MENU)
	)
	_content_box.add_child(main_button)

	var quit_button = OD.Chrome.parchment_button("Quit", font, ink_color, blank_texture, 18)
	quit_button.pressed.connect(func(): OD.Scenes.quit())
	_content_box.add_child(quit_button)

func _on_save_pressed():
	if _callbacks.has("on_save") and _callbacks.on_save.is_valid():
		var result = _callbacks.on_save.call()
		if typeof(result) == TYPE_DICTIONARY and result.get("ok", false):
			dismiss()
		return
	if OD.EventLog != null:
		OD.EventLog.notify("Save/Load is unavailable in this scene.")

func _on_save_and_quit_pressed():
	if _callbacks.has("on_save_and_quit") and _callbacks.on_save_and_quit.is_valid():
		_callbacks.on_save_and_quit.call()
		return
	dismiss()
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)

func _build_settings_view():
	var title = Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiHelpers.style_label(title, 24, Color(0.22, 0.14, 0.08))
	_content_box.add_child(title)

	var master_percent = OD.Settings.master_volume_percent() if OD.Settings != null else 100
	var music_percent = OD.Settings.music_volume_percent() if OD.Settings != null else 100
	var sfx_percent = OD.Settings.sfx_volume_percent() if OD.Settings != null else 100

	_add_volume_row("Master Volume", master_percent, func(value):
		if OD.Settings != null:
			OD.Settings.change("audio", "master_volume", int(value))
		if OD.Audio != null:
			OD.Audio.apply_volume_settings()
	)
	_add_volume_row("Music Volume", music_percent, func(value):
		if OD.Settings != null:
			OD.Settings.change("audio", "music_volume", int(value))
		if OD.Audio != null:
			OD.Audio.apply_volume_settings()
	)
	_add_volume_row("SFX Volume", sfx_percent, func(value):
		if OD.Settings != null:
			OD.Settings.change("audio", "sfx_volume", int(value))
		if OD.Audio != null:
			OD.Audio.apply_volume_settings()
	)

	var fullscreen_row = HBoxContainer.new()
	fullscreen_row.add_theme_constant_override("separation", 10)
	_content_box.add_child(fullscreen_row)

	var fullscreen_label = Label.new()
	fullscreen_label.text = "Fullscreen"
	fullscreen_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiHelpers.style_label(fullscreen_label, 16, Color(0.20, 0.12, 0.06))
	fullscreen_row.add_child(fullscreen_label)

	var fullscreen_check = CheckButton.new()
	fullscreen_check.button_pressed = OD.Settings.fullscreen_enabled() if OD.Settings != null else false
	fullscreen_check.toggled.connect(func(enabled):
		if OD.Settings != null:
			OD.Settings.change("display", "fullscreen", enabled)
			OD.Settings.apply_display_settings()
	)
	fullscreen_row.add_child(fullscreen_check)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)

	var back_button = OD.Chrome.parchment_button("Back", UiHelpers.dialog_font(), ink_color, blank_texture, 18)
	back_button.pressed.connect(func():
		_showing_settings = false
		_rebuild_content()
	)
	_content_box.add_child(back_button)

func _add_volume_row(label_text, initial_value, on_changed):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_content_box.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(125, 0)
	UiHelpers.style_label(label, 15, Color(0.20, 0.12, 0.06))
	row.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = float(initial_value)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_changed)
	row.add_child(slider)
