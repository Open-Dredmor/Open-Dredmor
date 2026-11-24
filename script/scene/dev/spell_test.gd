extends Control

const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")
const EntityGridScript = preload("res://script/instance/entity_grid.gd")
const TurnSchedulerScript = preload("res://script/instance/turn/turn_scheduler.gd")
const CommandProcessorScript = preload("res://script/instance/command/command_processor.gd")

static func init_container():
	return Control.new()

var _grid = null
var _player = null
var _scheduler = null
var _cmd_proc = null
var _log_label = null
var _status_label = null
var _log_lines = []

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_starting_skill_ids([19, 20, 21, 22, 23, 24, 25])
	OD.DungeonSettings.set_hero("hero")
	OD.DungeonSettings.set_character_name("Archmage Test")

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var root_hbox = HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 20)
	margin.add_child(root_hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(400, 0)
	left_vbox.add_theme_constant_override("separation", 8)
	root_hbox.add_child(left_vbox)

	var title = Label.new()
	title.text = "Spellcasting & spellDB.xml Engine Verification"
	title.add_theme_font_size_override("font_size", 20)
	left_vbox.add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vbox.add_child(_status_label)

	var btn_grid = GridContainer.new()
	btn_grid.columns = 2
	btn_grid.add_theme_constant_override("h_separation", 8)
	btn_grid.add_theme_constant_override("v_separation", 8)
	left_vbox.add_child(btn_grid)

	_setup_sandbox()

	_add_btn(btn_grid, "Cast Weak Firebolt (Missile)", func(): _demo_cast("Weak Firebolt", Vector2i(8, 5)))
	_add_btn(btn_grid, "Cast Smoke Ray (Beam)", func(): _demo_cast("Smoke Ray", Vector2i(9, 5)))
	_add_btn(btn_grid, "Cast Acidical Projector (Cone)", func(): _demo_cast("Acidical Projector", Vector2i(9, 5)))
	_add_btn(btn_grid, "Cast Torus Blast 1 (Template)", func(): _demo_cast("Torus Blast 1", Vector2i(5, 5)))
	_add_btn(btn_grid, "Cast Toxic Spore Cloud (Mine)", func(): _demo_cast("Toxic Spore Cloud", Vector2i(7, 5)))
	_add_btn(btn_grid, "Cast Monstrous Rage (Buff)", func(): _demo_cast("Monstrous Rage", Vector2i(5, 5)))
	_add_btn(btn_grid, "Cast Knitting Tissue (Heal)", func():
		_player.modify_hp(-15)
		_demo_cast("Knitting Tissue", Vector2i(5, 5))
	)
	_add_btn(btn_grid, "Cast Digging Ray (Dig)", func(): _demo_cast("Digging Ray", Vector2i(10, 5)))
	_add_btn(btn_grid, "Cast Summon Slime (Summon)", func(): _demo_cast("Summon Slime", Vector2i(6, 6)))
	_add_btn(btn_grid, "Cast Polymorph", func(): _demo_cast("Polymorphic Injunction", Vector2i(8, 5)))
	_add_btn(btn_grid, "Advance Turn", func():
		_scheduler.advance_turn({ entity_grid = _grid, player = _player })
		_log("Turn advanced -> " + str(_scheduler.turn_count))
		_refresh_status()
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

	_run_automated_verification()
	_refresh_status()
	print("SPELL_TEST_READY")

func _setup_sandbox():
	_grid = EntityGridScript.new()
	_grid.init(0)
	_grid.resize(16, 12)
	for yy in range(12):
		for xx in range(16):
			if xx == 0 or yy == 0 or xx == 15 or yy == 11 or xx == 10:
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

func _demo_cast(spell_name, target_cell):
	var res = SpellEngineScript.execute_spell(spell_name, _player, target_cell, {
		entity_grid = _grid,
		player = _player
	})
	_log(spell_name + " -> " + str(res))
	_refresh_status()

func _log(msg):
	_log_lines.append(msg)
	if _log_lines.size() > 35:
		_log_lines.remove_at(0)
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)

func _refresh_status():
	if _status_label == null or _player == null:
		return
	_status_label.text = "HP: %d/%d | MP: %d/%d | Buffs: %d | Cooldowns: %s | Mines: %d" % [
		_player.hp, _player.max_hp, _player.mp, _player.max_mp,
		_player.active_buffs.size(), str(_player.spell_cooldowns), _grid.get_spell_mines().size()
	]

func _run_automated_verification():
	var tmpl = OD.Database.get_template("10")
	assert(tmpl != null and tmpl.affected_offsets.size() == 4)

	var diggle = _grid.spawn_monster_at("Diggle", 8, 5, 1, true)
	assert(diggle != null)
	var hp_before = diggle.hp

	var firebolt = SpellEngineScript.execute_spell("Weak Firebolt", _player, Vector2i(8, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(firebolt.executed and diggle.hp < hp_before)

	var beam_cells = SpellEngineScript.resolve_target_cells(OD.Database.get_spell("Smoke Ray"), Vector2i(5, 5), Vector2i(9, 5), _grid)
	assert(beam_cells.size() >= 3)

	var cone_cells = SpellEngineScript.resolve_target_cells(OD.Database.get_spell("Acidical Projector"), Vector2i(5, 5), Vector2i(9, 5), _grid)
	assert(cone_cells.size() >= 3)

	var tmpl_cells = SpellEngineScript.resolve_target_cells(OD.Database.get_spell("Torus Blast 1"), Vector2i(5, 5), Vector2i(5, 5), _grid)
	assert(tmpl_cells.size() >= 1)

	var buff_res = SpellEngineScript.execute_spell("Monstrous Rage", _player, Vector2i(5, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(buff_res.executed and _player.has_buff("Monstrous Rage"))

	_player.modify_hp(-10)
	var hp_hurt = _player.hp
	var heal_res = SpellEngineScript.execute_spell("Knitting Tissue", _player, Vector2i(5, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(heal_res.executed and _player.hp > hp_hurt)

	var cd_res = SpellEngineScript.execute_spell("Tortoise Maneuver", _player, Vector2i(5, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(cd_res.executed and _player.get_spell_cooldown("Tortoise Maneuver") > 0)
	var blocked_cd = SpellEngineScript.execute_spell("Tortoise Maneuver", _player, Vector2i(5, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(not blocked_cd.executed)

	var mine_res = SpellEngineScript.execute_spell("Toxic Spore Cloud", _player, Vector2i(7, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(mine_res.executed and mine_res.get("mine_placed", false) and _grid.get_spell_mines().size() == 1)

	var dig_res = SpellEngineScript.execute_spell("Digging Ray", _player, Vector2i(10, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(dig_res.executed and not _grid.is_wall(10, 5))

	var summon_res = SpellEngineScript.execute_spell("Summon Slime", _player, Vector2i(6, 6), {
		entity_grid = _grid,
		player = _player
	})
	assert(summon_res.executed and _grid.get_actor_at(6, 6) != null)

	var poly_target = _grid.spawn_monster_at("Diggle", 8, 6, 1, true)
	assert(poly_target != null)
	var poly_res = SpellEngineScript.execute_spell("Polymorphic Injunction", _player, Vector2i(8, 6), {
		entity_grid = _grid,
		player = _player
	})
	assert(poly_res.executed and _grid.get_enemy_at(8, 6) != null)

	var para_res = SpellEngineScript.execute_spell("Lightning Blast", _player, Vector2i(8, 5), {
		entity_grid = _grid,
		player = _player
	})
	assert(para_res.executed)

	_scheduler.advance_turn({ entity_grid = _grid, player = _player })
	assert(_player.get_spell_cooldown("Tortoise Maneuver") < cd_res.cooldown)

	_log("ALL SPELL ENGINE CHECKS PASSED!")
	print("SPELL_ENGINE_VERIFIED")
