extends Control

const SaveManagerScript = preload("res://script/instance/save_manager.gd")
const DeathManagerScript = preload("res://script/instance/death_manager.gd")
const RetailSaveImporterScript = preload("res://script/instance/retail_save_importer.gd")

static func init_container():
	return Control.new()

var _log_label = null
var _log_lines = []

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_difficulty(OD.DungeonSettings.Difficulty.Medium)
	OD.DungeonSettings.set_permadeath(false)
	OD.DungeonSettings.set_hero("hero")
	OD.DungeonSettings.set_character_name("Sir Savealot")
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 3, 4, 5, 6])

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Save / Load & High Scores Verification"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	_add_btn(btn_row, "Main Menu", func(): OD.Scenes.goto(OD.Scenes.MAIN_MENU))
	_add_btn(btn_row, "Load Game Menu", func(): OD.Scenes.goto(OD.Scenes.LOAD_GAME_MENU))
	_add_btn(btn_row, "Import Saves Menu", func(): OD.Scenes.goto(OD.Scenes.IMPORT_SAVES_MENU))
	_add_btn(btn_row, "High Scores", func(): OD.Scenes.goto(OD.Scenes.HIGH_SCORES_MENU))
	_add_btn(btn_row, "Launch Game", func(): OD.Scenes.goto(OD.Scenes.GAME))

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_log_label = Label.new()
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 15)
	scroll.add_child(_log_label)

	_run_verification()

func _add_btn(parent_node, label_text, callback):
	var btn = Button.new()
	btn.text = label_text
	btn.pressed.connect(callback)
	parent_node.add_child(btn)

func _log(msg):
	_log_lines.append(msg)
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)

func _run_verification():
	var dungeon = Dungeon.new()
	dungeon._active_strategy = dungeon.FLOOR_STRATEGY.DEBUG_ROOMS
	add_child(dungeon)
	dungeon._build_ui()

	var player = dungeon.get_player()
	player.add_xp(250)
	player.add_zorkmids(77)
	player.set_hp(max(1, player.max_hp - 5))
	player.set_mp(max(0, player.max_mp - 3))
	player.spell_cooldowns["Test Spell"] = 4
	player.active_buffs.append({ name = "Test Buff", turns = 5, removable = true })
	dungeon._monsters_killed = 9
	var explored_before = dungeon.get_entity_grid().fov.explored_cells.size()

	var test_save_path = "user://saves/_test_save_roundtrip.json"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	var save_res = SaveManagerScript.save_run(dungeon, test_save_path)
	assert(save_res.ok)
	assert(FileAccess.file_exists(test_save_path))
	_log("Saved run to " + test_save_path)

	var load_res = SaveManagerScript.load_save_file(test_save_path)
	assert(load_res.ok)
	assert(load_res.data.format == SaveManagerScript.SAVE_FORMAT)
	SaveManagerScript.restore_run_settings(load_res.data, test_save_path)
	assert(OD.DungeonSettings.get_save_file_path() == test_save_path)
	assert(OD.DungeonSettings.get_pending_load_data() != null)

	var dungeon_restored = Dungeon.new()
	add_child(dungeon_restored)
	dungeon_restored._build_ui()

	var player_restored = dungeon_restored.get_player()
	assert(player_restored.character_name == "Sir Savealot")
	assert(player_restored.hp == player.hp)
	assert(player_restored.mp == player.mp)
	assert(player_restored.level == player.level)
	assert(player_restored.xp == player.xp)
	assert(player_restored.get_zorkmids() == player.get_zorkmids())
	assert(int(player_restored.spell_cooldowns.get("Test Spell", 0)) == 4)
	assert(player_restored.active_buffs.size() == 1)
	assert(dungeon_restored._monsters_killed == 9)
	assert(dungeon_restored.get_entity_grid().fov.explored_cells.size() == explored_before)
	_log("Restored dungeon & player state verified.")

	var test_scores = "user://_test_high_scores_verify.json"
	if FileAccess.file_exists(test_scores):
		DirAccess.remove_absolute(test_scores)
	var death_entry = DeathManagerScript.record_high_score(player_restored, 2, "Diggle", 9, test_scores, false)
	var win_entry = DeathManagerScript.record_high_score(player_restored, 10, "Defeated Lord Dredmor", 42, test_scores, true)
	assert(not death_entry.victory)
	assert(win_entry.victory)
	var scores = DeathManagerScript.load_high_scores(test_scores)
	assert(scores.size() == 2)
	_log("High scores (death & victory) verified.")

	DirAccess.remove_absolute(test_save_path)
	DirAccess.remove_absolute(test_scores)
	OD.DungeonSettings.clear_pending_load_data()
	OD.DungeonSettings.set_save_file_path("")

	remove_child(dungeon)
	dungeon.queue_free()
	remove_child(dungeon_restored)
	dungeon_restored.queue_free()

	var retail_dir = ProjectSettings.globalize_path("res://airef/retail-save-dir/Dungeons of Dredmor")
	var found_retail = RetailSaveImporterScript.scan_directory(retail_dir)
	assert(found_retail.size() >= 5)
	_log("Scanned " + str(found_retail.size()) + " retail saves.")

	var alex_out = "user://saves/_test_import_alex.json"
	var carl_out = "user://saves/_test_import_carl.json"
	var tipla_out = "user://saves/_test_import_tipla.json"
	var alex_res = RetailSaveImporterScript.import_save(retail_dir + "/Alexander Hami.dredmorsave", alex_out)
	assert(alex_res.ok and alex_res.name == "Alexander Hami" and alex_res.items_imported > 0)
	var carl_res = RetailSaveImporterScript.import_save(retail_dir + "/carl.dredmorsave", carl_out)
	assert(carl_res.ok and carl_res.name == "Carl" and carl_res.floor == 3 and carl_res.level > 1)
	var tipla_res = RetailSaveImporterScript.import_save(retail_dir + "/Tipla.dredmorsave", tipla_out)
	assert(tipla_res.ok and tipla_res.warnings.size() > 0)

	var corrupt_dir = "user://_test_corrupt.dredmorsave/"
	DirAccess.make_dir_recursive_absolute(corrupt_dir)
	var bad_meta = FileAccess.open(corrupt_dir + "metadata.dat", FileAccess.WRITE)
	bad_meta.store_string("GARBAGE")
	bad_meta.close()
	var corrupt_out = "user://saves/_test_import_corrupt.json"
	var corrupt_res = RetailSaveImporterScript.import_save(corrupt_dir, corrupt_out)
	assert(corrupt_res.ok and corrupt_res.warnings.size() > 0)

	var imported_load = SaveManagerScript.load_save_file(carl_out)
	assert(imported_load.ok)
	SaveManagerScript.restore_run_settings(imported_load.data, carl_out)
	var dungeon_carl = Dungeon.new()
	add_child(dungeon_carl)
	dungeon_carl._build_ui()
	assert(dungeon_carl.get_floor_level() == 3)
	assert(dungeon_carl.get_player().character_name == "Carl")
	remove_child(dungeon_carl)
	dungeon_carl.queue_free()
	_log("Retail save import (Carl floor 3, Alexander Hami, modded Tipla, corrupt fallback) verified.")

	for tmp_file in [alex_out, carl_out, tipla_out, corrupt_out]:
		if FileAccess.file_exists(tmp_file):
			DirAccess.remove_absolute(tmp_file)
	if FileAccess.file_exists(corrupt_dir + "metadata.dat"):
		DirAccess.remove_absolute(corrupt_dir + "metadata.dat")
	if DirAccess.dir_exists_absolute(corrupt_dir):
		DirAccess.remove_absolute(corrupt_dir)
	OD.DungeonSettings.clear_pending_load_data()
	OD.DungeonSettings.set_save_file_path("")

	_log("ALL SAVE/LOAD, HIGH SCORES & RETAIL IMPORT CHECKS PASSED!")
	print("SAVE_SYSTEM_VERIFIED")
