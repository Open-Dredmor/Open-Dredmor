extends Control

const EntityGridScript = preload("res://script/instance/entity_grid.gd")
const TurnSchedulerScript = preload("res://script/instance/turn/turn_scheduler.gd")
const CommandProcessorScript = preload("res://script/instance/command/command_processor.gd")
const RetailStrategyScript = preload("res://script/instance/room_placement/retail_strategy.gd")

static func init_container():
	return Control.new()

var _grid = null
var _player = null
var _scheduler = null
var _cmd_proc = null
var _status_label = null
var _log_label = null
var _log_lines = []

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_no_time_to_grind(false)
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 3, 4, 5, 6])
	OD.DungeonSettings.set_hero("hero")
	OD.DungeonSettings.set_character_name("Monster Hunter")

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	_setup_sandbox()

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
	title.text = "Monster AI & Spawning Verification"
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

	_add_btn(button_grid, "Spawn Diggle", func():
		var mon = _grid.spawn_monster_at("Diggle", 10, 5, 1, true)
		_log("Spawned Diggle: " + str(mon != null))
		_refresh_status()
	)
	_add_btn(button_grid, "Spawn Octo (Caster)", func():
		var mon = _grid.spawn_monster_at("Octo", 9, 5, 1, true)
		_log("Spawned Octo (spells=" + str(mon.spells if mon != null else []) + ")")
		_refresh_status()
	)
	_add_btn(button_grid, "Step Turn (AI)", func():
		_scheduler.advance_turn({ entity_grid = _grid, player = _player })
		_log("Turn " + str(_scheduler.turn_count) + " -> Monsters: " + str(_grid.get_monsters().size()))
		_refresh_status()
	)
	_add_btn(button_grid, "Force Periodic Spawn", func():
		var mon = _grid.maybe_spawn_periodic_monster(_player.get_grid_position(), 1, 25, true)
		_log("Periodic spawn -> " + (mon.monster_name if mon != null else "None"))
		_refresh_status()
	)
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
	print("MONSTER_TEST_READY")

func _setup_sandbox():
	_grid = EntityGridScript.new()
	_grid.init(0)
	_grid.resize(16, 12)
	for yy in range(12):
		for xx in range(16):
			if xx == 0 or yy == 0 or xx == 15 or yy == 11:
				_grid._wall_cells[Vector2i(xx, yy)] = true
			else:
				_grid._floor_cells[Vector2i(xx, yy)] = true
	_player = PlayerCharacter.new()
	_player.init()
	_player.add_secondary_bonus("hp_max", 200)
	_player.set_hp(_player.max_hp)
	_grid.add_entity(4, 5, _player)
	_cmd_proc = CommandProcessorScript.new()
	_scheduler = TurnSchedulerScript.new()
	_scheduler.init(_cmd_proc, 0.0)
	add_child(_scheduler)
	add_child(_grid)
	_grid.visible = false

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
	_status_label.text = "Player HP: %d/%d | Turn: %d | Monsters on grid: %d" % [
		_player.hp, _player.max_hp, _scheduler.turn_count, _grid.get_monsters().size()
	]

func _run_automated_verification():
	var octo = _grid.spawn_monster_at("Octo", 9, 5, 1, true)
	assert(octo != null and not octo.spells.is_empty())

	var treant = _grid.spawn_monster_at("Fruit Treant", 11, 5, 1, true)
	assert(treant != null and not treant.drops.is_empty())

	var diggle = _grid.spawn_monster_at("Diggle", 7, 5, 1, true)
	assert(diggle != null)
	var start_position = diggle.get_grid_position()

	_grid.update_fov(_player.get_grid_position(), 8)
	_scheduler.advance_turn({ entity_grid = _grid, player = _player })
	assert(diggle.alerted)
	var after_position = diggle.get_grid_position()
	assert(after_position.x < start_position.x)

	var hp_before = _player.hp
	for _ii in range(8):
		_scheduler.advance_turn({ entity_grid = _grid, player = _player })
	assert(_player.hp < hp_before)

	var count_before = _grid.get_monsters().size()
	OD.DungeonSettings.set_no_time_to_grind(true)
	var no_grind_spawn = _grid.maybe_spawn_periodic_monster(_player.get_grid_position(), 1, 25, false)
	assert(no_grind_spawn == null and _grid.get_monsters().size() == count_before)

	OD.DungeonSettings.set_no_time_to_grind(false)
	var periodic = _grid.maybe_spawn_periodic_monster(_player.get_grid_position(), 1, 25, false)
	assert(periodic != null and _grid.get_monsters().size() == count_before + 1)

	var retail_grid = RetailStrategyScript.generate("The Dungeon", 1)
	var floor_monsters = retail_grid.get_monsters()
	assert(floor_monsters.size() > 0)
	_log("Retail Floor 1 spawned " + str(floor_monsters.size()) + " monsters")
	retail_grid.free()

	_log("ALL MONSTER AI & SPAWNING CHECKS PASSED!")
	print("MONSTER_AI_VERIFIED")
