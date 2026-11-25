extends CanvasLayer

class_name PauseDialog

const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)

var _callbacks = {}
var _showing_settings = false
var _panel = null
var _content_vbox = null

func init(callbacks = {}):
	_callbacks = callbacks
	layer = 14
	_build_ui()
	_connect_signals()
	_rebuild_content()
	return self

func _connect_signals():
	var vp = get_viewport()
	if vp != null and not vp.size_changed.is_connected(_update_panel_bounds):
		vp.size_changed.connect(_update_panel_bounds)

func _font():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	return dialog_assets.font if dialog_assets != null else null

func _get_viewport_size():
	var vp = get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return DEFAULT_VIEWPORT_SIZE

func _style_label(lbl, font_size, font_color):
	var font_res = _font()
	if font_res != null:
		lbl.add_theme_font_override("font", font_res)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	return lbl

func _create_panel_style():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var bg_tex = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	if bg_tex != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = bg_tex
		style_box.texture_margin_left = 44
		style_box.texture_margin_right = 44
		style_box.texture_margin_top = 44
		style_box.texture_margin_bottom = 44
		style_box.content_margin_left = 36
		style_box.content_margin_right = 36
		style_box.content_margin_top = 30
		style_box.content_margin_bottom = 32
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = Color(0.14, 0.11, 0.09, 0.95)
	fallback.border_color = Color(0.6, 0.48, 0.3, 0.95)
	fallback.set_border_width_all(2)
	fallback.set_content_margin_all(24)
	return fallback

func _build_ui():
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(_panel)
	_update_panel_bounds()

	_content_vbox = VBoxContainer.new()
	_content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(_content_vbox)

func _update_panel_bounds():
	if _panel == null or not is_instance_valid(_panel):
		return
	var vp_size = _get_viewport_size()
	var panel_w = clamp(vp_size.x * 0.34, 340.0, 480.0)
	var panel_h = clamp(vp_size.y * 0.44, 280.0, 420.0)
	_panel.custom_minimum_size = Vector2(panel_w, panel_h)

func _unhandled_input(ev):
	if ev is InputEventKey and ev.is_pressed() and not ev.echo:
		if ev.keycode == KEY_ESCAPE:
			if _showing_settings:
				_showing_settings = false
				_rebuild_content()
			else:
				dismiss()
			get_viewport().set_input_as_handled()

func dismiss():
	if _callbacks.has("on_close") and _callbacks.on_close.is_valid():
		_callbacks.on_close.call()
	queue_free()

func _rebuild_content():
	if _content_vbox == null or not is_instance_valid(_content_vbox):
		return
	for child in _content_vbox.get_children():
		_content_vbox.remove_child(child)
		child.queue_free()

	if _showing_settings:
		_build_settings_view()
	else:
		_build_main_menu_view()

func _build_main_menu_view():
	var title = Label.new()
	title.text = "Game Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title, 26, Color(0.22, 0.14, 0.08))
	_content_vbox.add_child(title)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_tex = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)

	var resume_btn = OD.Chrome.parchment_button("Resume", _font(), ink_color, blank_tex, 18)
	resume_btn.pressed.connect(dismiss)
	_content_vbox.add_child(resume_btn)

	var save_btn = OD.Chrome.parchment_button("Save Game", _font(), ink_color, blank_tex, 18)
	save_btn.pressed.connect(_on_save_pressed)
	_content_vbox.add_child(save_btn)

	var settings_btn = OD.Chrome.parchment_button("Settings", _font(), ink_color, blank_tex, 18)
	settings_btn.pressed.connect(func():
		_showing_settings = true
		_rebuild_content()
	)
	_content_vbox.add_child(settings_btn)

	var main_btn = OD.Chrome.parchment_button("Main Menu", _font(), ink_color, blank_tex, 18)
	main_btn.pressed.connect(func():
		dismiss()
		OD.Scenes.goto(OD.Scenes.MAIN_MENU)
	)
	_content_vbox.add_child(main_btn)

	var quit_btn = OD.Chrome.parchment_button("Quit", _font(), ink_color, blank_tex, 18)
	quit_btn.pressed.connect(func(): OD.Scenes.quit())
	_content_vbox.add_child(quit_btn)

func _on_save_pressed():
	if _callbacks.has("on_save") and _callbacks.on_save.is_valid():
		_callbacks.on_save.call()
		return
	if OD.EventLog != null:
		OD.EventLog.notify("Save/Load will be available in the next milestone.")

func _build_settings_view():
	var title = Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title, 24, Color(0.22, 0.14, 0.08))
	_content_vbox.add_child(title)

	var master_pct = OD.Settings.master_volume_percent() if OD.Settings != null else 100
	var music_pct = OD.Settings.music_volume_percent() if OD.Settings != null else 100
	var sfx_pct = OD.Settings.sfx_volume_percent() if OD.Settings != null else 100

	_add_volume_row("Master Volume", master_pct, func(val):
		if OD.Settings != null:
			OD.Settings.change("audio", "master_volume", int(val))
		if OD.Audio != null:
			OD.Audio.apply_volume_settings()
	)
	_add_volume_row("Music Volume", music_pct, func(val):
		if OD.Settings != null:
			OD.Settings.change("audio", "music_volume", int(val))
		if OD.Audio != null:
			OD.Audio.apply_volume_settings()
	)
	_add_volume_row("SFX Volume", sfx_pct, func(val):
		if OD.Settings != null:
			OD.Settings.change("audio", "sfx_volume", int(val))
		if OD.Audio != null:
			OD.Audio.apply_volume_settings()
	)

	var fs_row = HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 10)
	_content_vbox.add_child(fs_row)

	var fs_lbl = Label.new()
	fs_lbl.text = "Fullscreen"
	fs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(fs_lbl, 16, Color(0.20, 0.12, 0.06))
	fs_row.add_child(fs_lbl)

	var fs_check = CheckButton.new()
	fs_check.button_pressed = OD.Settings.fullscreen_enabled() if OD.Settings != null else false
	fs_check.toggled.connect(func(enabled):
		if OD.Settings != null:
			OD.Settings.change("display", "fullscreen", enabled)
			OD.Settings.apply_display_settings()
	)
	fs_row.add_child(fs_check)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_tex = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)

	var back_btn = OD.Chrome.parchment_button("Back", _font(), ink_color, blank_tex, 18)
	back_btn.pressed.connect(func():
		_showing_settings = false
		_rebuild_content()
	)
	_content_vbox.add_child(back_btn)

func _add_volume_row(label_text, initial_value, on_changed):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_content_vbox.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(125, 0)
	_style_label(lbl, 15, Color(0.20, 0.12, 0.06))
	row.add_child(lbl)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = float(initial_value)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_changed)
	row.add_child(slider)
