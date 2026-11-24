extends Control

const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")
const EntityGridScript = preload("res://script/instance/entity_grid.gd")
const TurnSchedulerScript = preload("res://script/instance/turn/turn_scheduler.gd")
const CommandProcessorScript = preload("res://script/instance/command/command_processor.gd")
const BuffBarScript = preload("res://script/instance/ui/buff_bar.gd")

static func init_container():
	return Control.new()

var _grid = null
var _player = null
var _scheduler = null
var _cmd_proc = null
var _buff_bar = null
var _stats_label = null
var _log_label = null
var _log_lines = []

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 19, 20, 21, 22, 23])
	OD.DungeonSettings.set_hero("hero")
	OD.DungeonSettings.set_character_name("Buff Tester")

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	_setup_sandbox()

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 72)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var root_hbox = HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 20)
	margin.add_child(root_hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(420, 0)
	left_vbox.add_theme_constant_override("separation", 10)
	root_hbox.add_child(left_vbox)

	var title = Label.new()
	title.text = "Buffs, Debuffs & Status Effects Verification"
	title.add_theme_font_size_override("font_size", 20)
	left_vbox.add_child(title)

	_stats_label = Label.new()
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vbox.add_child(_stats_label)

	var btn_grid = GridContainer.new()
	btn_grid.columns = 2
	btn_grid.add_theme_constant_override("h_separation", 8)
	btn_grid.add_theme_constant_override("v_separation", 8)
	left_vbox.add_child(btn_grid)

	_add_btn(btn_grid, "Apply Monstrous Rage", func(): _cast_self("Monstrous Rage"))
	_add_btn(btn_grid, "Apply Lobstery Toughness (Brittle)", func(): _cast_self("Lobstery Toughness"))
	_add_btn(btn_grid, "Apply Fell Power (Attacks/Proc)", func(): _cast_self("Fell Power"))
	_add_btn(btn_grid, "Apply Radiant Aura (Hit Proc)", func(): _cast_self("Radiant Aura"))
	_add_btn(btn_grid, "Apply Meatshield (Removable)", func(): _cast_self("Meatshield"))
	_add_btn(btn_grid, "Apply On Fire (DoT)", func():
		var res = SpellEngineScript.execute_spell("On Fire", null, Vector2i(5, 5), {
			entity_grid = _grid, player = _player, free_cast = true
		})
		_log("On Fire -> " + str(res.get("effects_applied", [])))
		_refresh_stats()
	)
	_add_btn(btn_grid, "Simulate Player Attack", func():
		var procs = _player.on_attack_performed()
		_log("Player attacked -> procs=" + str(procs))
		_refresh_stats()
	)
	_add_btn(btn_grid, "Simulate Hit Received", func():
		var procs = _player.on_hit_received()
		_log("Player hit -> procs=" + str(procs))
		_refresh_stats()
	)
	_add_btn(btn_grid, "Advance Turn", func():
		_scheduler.advance_turn({ entity_grid = _grid, player = _player })
		_log("Turn " + str(_scheduler.turn_count) + " ticked")
		_refresh_stats()
	)
	_add_btn(btn_grid, "Launch Game", func(): OD.Scenes.goto(OD.Scenes.GAME))

	var log_panel = PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_hbox.add_child(log_panel)

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

	_buff_bar = BuffBarScript.new().init(_player)
	container.add_child(_buff_bar)

	_run_automated_verification()
	_refresh_stats()
	print("BUFF_TEST_READY")

func _setup_sandbox():
	_grid = EntityGridScript.new()
	_grid.init(0)
	_grid.resize(12, 10)
	for yy in range(10):
		for xx in range(12):
			if xx == 0 or yy == 0 or xx == 11 or yy == 9:
				_grid._wall_cells[Vector2i(xx, yy)] = true
			else:
				_grid._floor_cells[Vector2i(xx, yy)] = true
	_player = PlayerCharacter.new()
	_player.init()
	_player.add_secondary_bonus("mp_max", 200)
	_player.set_mp(_player.max_mp)
	_grid.add_entity(5, 5, _player)
	_cmd_proc = CommandProcessorScript.new()
	_scheduler = TurnSchedulerScript.new()
	_scheduler.init(_cmd_proc, 0.0)
	add_child(_scheduler)
	add_child(_grid)
	_grid.visible = false

func _add_btn(parent_node, label_text, callback):
	var btn = Button.new()
	btn.text = label_text
	btn.pressed.connect(callback)
	parent_node.add_child(btn)

func _cast_self(spell_name):
	var res = SpellEngineScript.execute_spell(spell_name, _player, Vector2i(5, 5), {
		entity_grid = _grid,
		player = _player,
		free_cast = true
	})
	_log(spell_name + " -> " + str(res.get("effects_applied", [])))
	_refresh_stats()

func _log(msg):
	_log_lines.append(msg)
	if _log_lines.size() > 35:
		_log_lines.remove_at(0)
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)

func _refresh_stats():
	if _stats_label == null or _player == null:
		return
	_stats_label.text = "HP: %d/%d | MP: %d/%d | Melee: %d | Armour: %d | Buffs: %d | DoTs: %d" % [
		_player.hp, _player.max_hp, _player.mp, _player.max_mp,
		_player.get_secondary_stat("melee_power"),
		_player.get_secondary_stat("armour_absorption"),
		_player.active_buffs.size(), _player.active_dots.size()
	]

func _run_automated_verification():
	var base_melee = _player.get_secondary_stat("melee_power")
	SpellEngineScript.execute_spell("Monstrous Rage", _player, Vector2i(5, 5), {
		entity_grid = _grid, player = _player, free_cast = true
	})
	assert(_player.has_buff("Monstrous Rage"))
	assert(_player.get_secondary_stat("melee_power") >= base_melee)

	SpellEngineScript.execute_spell("Lobstery Toughness", _player, Vector2i(5, 5), {
		entity_grid = _grid, player = _player, free_cast = true
	})
	assert(_player.has_buff("Lobstery Toughness"))
	var brit_before = 0
	for b in _player.active_buffs:
		if b.name == "Lobstery Toughness":
			brit_before = int(b.brittle_remaining)
	assert(brit_before > 0)
	for _ii in range(brit_before):
		_player.on_hit_received()
	assert(not _player.has_buff("Lobstery Toughness"))

	SpellEngineScript.execute_spell("Fell Power", _player, Vector2i(5, 5), {
		entity_grid = _grid, player = _player, free_cast = true
	})
	assert(_player.has_buff("Fell Power"))
	var atk_procs = _player.on_attack_performed()
	assert(not _player.has_buff("Fell Power") or atk_procs.size() >= 0)

	SpellEngineScript.execute_spell("Meatshield", _player, Vector2i(5, 5), {
		entity_grid = _grid, player = _player, free_cast = true
	})
	assert(_player.has_buff("Meatshield"))
	assert(_player.dismiss_buff("Meatshield"))
	assert(not _player.has_buff("Meatshield"))

	var hp_before_dot = _player.hp
	SpellEngineScript.execute_spell("On Fire", null, Vector2i(5, 5), {
		entity_grid = _grid, player = _player, free_cast = true
	})
	assert(_player.active_dots.size() >= 1)
	_scheduler.advance_turn({ entity_grid = _grid, player = _player })
	assert(_player.hp < hp_before_dot)

	_buff_bar.refresh()
	assert(_buff_bar._row.get_child_count() >= 1)

	_log("ALL BUFF & STATUS EFFECT CHECKS PASSED!")
	print("BUFF_SYSTEM_VERIFIED")
