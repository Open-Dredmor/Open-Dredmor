extends Control

const DeathManagerScript = preload("res://script/instance/death_manager.gd")

static func init_container():
	return Control.new()

var _player = null
var _status_label = null
var _log_label = null
var _log_lines = []

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 3, 4, 5, 6])
	OD.DungeonSettings.set_hero("hero")
	OD.DungeonSettings.set_character_name("Sir Permadeath")

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	_player = PlayerCharacter.new()
	_player.init()
	_player.visible = false
	add_child(_player)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var root_horizontal_box = HBoxContainer.new()
	root_horizontal_box.add_theme_constant_override("separation", 20)
	margin.add_child(root_horizontal_box)

	var left_vertical_box = VBoxContainer.new()
	left_vertical_box.custom_minimum_size = Vector2(400, 0)
	left_vertical_box.add_theme_constant_override("separation", 10)
	root_horizontal_box.add_child(left_vertical_box)

	var title = Label.new()
	title.text = "Player Death, Permadeath & High Scores"
	title.add_theme_font_size_override("font_size", 20)
	left_vertical_box.add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vertical_box.add_child(_status_label)

	var button_grid = GridContainer.new()
	button_grid.columns = 2
	button_grid.add_theme_constant_override("h_separation", 8)
	button_grid.add_theme_constant_override("v_separation", 8)
	left_vertical_box.add_child(button_grid)

	_add_btn(button_grid, "Trigger Lethal Hit", func():
		_player.is_dead = false
		_player.set_hp(_player.max_hp)
		_player.modify_hp(-999, "Lord Dredmor")
		var entry = DeathManagerScript.record_high_score(_player, 3, _player.last_damage_source, 12)
		_log("Recorded High Score: " + str(entry))
		_refresh_status()
	)
	_add_btn(button_grid, "View High Scores", func(): OD.Scenes.goto(OD.Scenes.HIGH_SCORES_MENU))
	_add_btn(button_grid, "Main Menu", func(): OD.Scenes.goto(OD.Scenes.MAIN_MENU))
	_add_btn(button_grid, "Launch Game", func(): OD.Scenes.goto(OD.Scenes.GAME))

	var log_panel = PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_horizontal_box.add_child(log_panel)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_panel.add_child(scroll)

	_log_label = Label.new()
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 15)
	scroll.add_child(_log_label)

	_run_automated_verification()
	_refresh_status()
	print("DEATH_TEST_READY")

func _add_btn(parent_node, label_text, callback):
	var button = Button.new()
	button.text = label_text
	button.pressed.connect(callback)
	parent_node.add_child(button)

func _log(message):
	_log_lines.append(message)
	if _log_lines.size() > 35:
		_log_lines.remove_at(0)
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)

func _refresh_status():
	if _status_label == null or _player == null:
		return
	_status_label.text = "Hero: %s | HP: %d/%d | Dead: %s | Cause: %s" % [
		_player.character_name, _player.hp, _player.max_hp, str(_player.is_dead), _player.last_damage_source
	]

func _run_automated_verification():
	var died_causes = []
	_player.died.connect(func(cause): died_causes.append(cause))

	var test_save = "user://test_permadeath_save.json"
	var f_keep = FileAccess.open(test_save, FileAccess.WRITE)
	f_keep.store_string("{}")
	f_keep.close()
	assert(not DeathManagerScript.delete_permadeath_save(test_save, false))
	assert(FileAccess.file_exists(test_save))

	assert(DeathManagerScript.delete_permadeath_save(test_save, true))
	assert(not FileAccess.file_exists(test_save))

	_player.add_xp(250)
	_player.modify_hp(-9999, "Diggle")
	assert(_player.is_dead and _player.hp == 0)
	assert(died_causes.size() == 1 and died_causes[0] == "Diggle")

	var test_scores_path = "user://test_high_scores.json"
	if FileAccess.file_exists(test_scores_path):
		DirAccess.remove_absolute(test_scores_path)
	var recorded = DeathManagerScript.record_high_score(_player, 2, "Diggle", 7, test_scores_path)
	assert(recorded.name == "Sir Permadeath" and recorded.level >= 2 and recorded.cause_of_death == "Diggle")
	assert(recorded.score > 0 and recorded.skills.size() == 7)
	var loaded = DeathManagerScript.load_high_scores(test_scores_path)
	assert(loaded.size() == 1 and loaded[0].name == "Sir Permadeath")
	DirAccess.remove_absolute(test_scores_path)

	_log("ALL DEATH, PERMADEATH & HIGH SCORE CHECKS PASSED!")
	print("DEATH_SYSTEM_VERIFIED")
