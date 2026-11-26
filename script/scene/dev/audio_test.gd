extends Control

static func init_container():
	return Control.new()

var _status_label = null
var _cue_input = null
var _filter_input = null
var _cue_grid = null
var _all_cues = []

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	OD.Database.ingest()
	OD.Audio.setup(get_tree().get_root())
	_all_cues = OD.Database.get_sound_cues()

	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	container.add_child(margin)

	var root_vertical_box = VBoxContainer.new()
	root_vertical_box.add_theme_constant_override("separation", 12)
	margin.add_child(root_vertical_box)

	var title_label = Label.new()
	title_label.text = "Audio Debug Scene (" + str(_all_cues.size()) + " SFX cues indexed)"
	root_vertical_box.add_child(title_label)

	_status_label = Label.new()
	_status_label.text = "Ready"
	root_vertical_box.add_child(_status_label)

	root_vertical_box.add_child(_build_settings_row())
	root_vertical_box.add_child(_build_music_row())
	root_vertical_box.add_child(_build_sfx_test_row())
	root_vertical_box.add_child(_build_filter_row())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vertical_box.add_child(scroll)

	_cue_grid = GridContainer.new()
	_cue_grid.columns = 5
	_cue_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_cue_grid)

	_populate_cue_grid("")

func _build_settings_row():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var enabled_checkbox = CheckBox.new()
	enabled_checkbox.text = "Audio Enabled"
	enabled_checkbox.button_pressed = OD.Settings.audio_enabled()
	enabled_checkbox.toggled.connect(_on_audio_enabled_toggled)
	row.add_child(enabled_checkbox)

	var master_label = Label.new()
	master_label.text = "Master %:"
	row.add_child(master_label)

	var master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.step = 5
	master_slider.value = OD.Settings.master_volume_percent()
	master_slider.custom_minimum_size = Vector2(180, 24)
	master_slider.value_changed.connect(_on_master_volume_changed)
	row.add_child(master_slider)

	var sfx_label = Label.new()
	sfx_label.text = "SFX %:"
	row.add_child(sfx_label)

	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 5
	sfx_slider.value = OD.Settings.sfx_volume_percent()
	sfx_slider.custom_minimum_size = Vector2(180, 24)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	row.add_child(sfx_slider)

	return row

func _build_music_row():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var title_button = Button.new()
	title_button.text = "Play Title Music"
	title_button.pressed.connect(func(): _play_music(OD.Resources.paths.main_menu.music, "Title"))
	row.add_child(title_button)

	var game_button = Button.new()
	game_button.text = "Play Game Music"
	game_button.pressed.connect(func(): _play_music(OD.Resources.paths.game.music, "Game"))
	row.add_child(game_button)

	var stop_button = Button.new()
	stop_button.text = "Stop All Audio"
	stop_button.pressed.connect(_on_stop_pressed)
	row.add_child(stop_button)

	return row

func _build_sfx_test_row():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	_cue_input = LineEdit.new()
	_cue_input.placeholder_text = "Cue name (e.g. click, diggle_attack)"
	_cue_input.text = "click"
	_cue_input.custom_minimum_size = Vector2(300, 0)
	_cue_input.text_submitted.connect(func(text): _play_cue(text))
	row.add_child(_cue_input)

	var play_button = Button.new()
	play_button.text = "Play Cue"
	play_button.pressed.connect(func(): _play_cue(_cue_input.text))
	row.add_child(play_button)

	var burst_button = Button.new()
	burst_button.text = "Pool Burst (5x)"
	burst_button.pressed.connect(_on_pool_burst_pressed)
	row.add_child(burst_button)

	var unknown_button = Button.new()
	unknown_button.text = "Test Unknown Cue"
	unknown_button.pressed.connect(func(): _play_cue("__nonexistent_cue__"))
	row.add_child(unknown_button)

	return row

func _build_filter_row():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var filter_label = Label.new()
	filter_label.text = "Filter cues:"
	row.add_child(filter_label)

	_filter_input = LineEdit.new()
	_filter_input.placeholder_text = "Type to filter soundfx.xml cues..."
	_filter_input.custom_minimum_size = Vector2(300, 0)
	_filter_input.text_changed.connect(_populate_cue_grid)
	row.add_child(_filter_input)

	return row

func _populate_cue_grid(filter_text):
	for child in _cue_grid.get_children():
		child.queue_free()
	var query = filter_text.strip_edges().to_lower()
	for cue_name in _all_cues:
		if query != "" and not cue_name.to_lower().contains(query):
			continue
		var button = Button.new()
		button.text = cue_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): _play_cue(cue_name))
		_cue_grid.add_child(button)

func _play_cue(cue_name):
	var trimmed = cue_name.strip_edges()
	var path = OD.Database.get_sound_path(trimmed)
	var played = OD.Audio.play_sfx(trimmed)
	_status_label.text = "SFX [" + trimmed + "] -> played=" + str(played) + " path=" + str(path)

func _play_music(music_path, label):
	var stream = OD.Load.audio(music_path)
	OD.Audio.play(stream)
	_status_label.text = "Music [" + label + "] -> " + music_path

func _on_stop_pressed():
	OD.Audio.stop()
	_status_label.text = "Stopped all audio"

func _on_pool_burst_pressed():
	var burst_cues = ["click", "swing", "door_open", "money_get", "diggle_attack"]
	var played_count = 0
	for cue_name in burst_cues:
		if OD.Audio.play_sfx(cue_name):
			played_count += 1
	_status_label.text = "Pool burst triggered " + str(played_count) + "/" + str(burst_cues.size()) + " cues"

func _on_audio_enabled_toggled(enabled):
	OD.Settings.change("game", "audio_enabled", enabled)
	if enabled:
		OD.Audio.setup(get_tree().get_root())
	else:
		OD.Audio.stop()
	_status_label.text = "Audio enabled = " + str(enabled)

func _on_master_volume_changed(value):
	OD.Settings.change("game", "audio_volume_master_percent", int(value))
	OD.Audio.apply_volume_settings()
	_status_label.text = "Master volume = " + str(int(value)) + "%"

func _on_sfx_volume_changed(value):
	OD.Settings.change("game", "audio_volume_sfx_percent", int(value))
	OD.Audio.apply_volume_settings()
	_status_label.text = "SFX volume = " + str(int(value)) + "%"
