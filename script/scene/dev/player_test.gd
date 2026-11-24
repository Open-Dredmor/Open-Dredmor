extends Control

static func init_container():
	return Control.new()

var _hero_player = null
var _heroine_player = null
var _active_player = null
var _stats_label = null
var _current_dir = Vector2i(0, 1)
var _is_moving = false

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	var root_hbox = HBoxContainer.new()
	root_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_hbox.add_theme_constant_override("separation", 24)
	container.add_child(root_hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(460, 0)
	left_vbox.add_theme_constant_override("separation", 12)
	root_hbox.add_child(left_vbox)

	var title_label = Label.new()
	title_label.text = "PlayerCharacter Verification (Hero & Heroine)"
	title_label.add_theme_font_size_override("font_size", 22)
	left_vbox.add_child(title_label)

	var preview_panel = Panel.new()
	preview_panel.custom_minimum_size = Vector2(440, 220)
	left_vbox.add_child(preview_panel)

	var sprite_stage = Node2D.new()
	preview_panel.add_child(sprite_stage)

	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 4, 19, 20, 21])
	OD.DungeonSettings.set_hero("hero")
	OD.DungeonSettings.set_character_name("Sir Eyebrows")
	_hero_player = PlayerCharacter.new()
	_hero_player.init()
	_hero_player.position = Vector2(140, 110)
	_hero_player.scale = Vector2(2.0, 2.0)
	sprite_stage.add_child(_hero_player)

	OD.DungeonSettings.set_hero("heroine")
	OD.DungeonSettings.set_character_name("Lady Eyebrows")
	_heroine_player = PlayerCharacter.new()
	_heroine_player.init()
	_heroine_player.position = Vector2(300, 110)
	_heroine_player.scale = Vector2(2.0, 2.0)
	sprite_stage.add_child(_heroine_player)

	_active_player = _heroine_player

	var sprite_controls = HBoxContainer.new()
	sprite_controls.add_theme_constant_override("separation", 8)
	left_vbox.add_child(sprite_controls)

	for dir_info in [
		{ label = "Down", vec = Vector2i(0, 1) },
		{ label = "Up", vec = Vector2i(0, -1) },
		{ label = "Left", vec = Vector2i(-1, 0) },
		{ label = "Right", vec = Vector2i(1, 0) }
	]:
		var btn = Button.new()
		btn.text = dir_info.label
		var target_vec = dir_info.vec
		btn.pressed.connect(func():
			_current_dir = target_vec
			_apply_sprite_state()
		)
		sprite_controls.add_child(btn)

	var toggle_move_btn = Button.new()
	toggle_move_btn.text = "Toggle Move/Idle"
	toggle_move_btn.pressed.connect(func():
		_is_moving = not _is_moving
		_apply_sprite_state()
	)
	left_vbox.add_child(toggle_move_btn)

	var select_hbox = HBoxContainer.new()
	select_hbox.add_theme_constant_override("separation", 8)
	left_vbox.add_child(select_hbox)

	var select_hero_btn = Button.new()
	select_hero_btn.text = "Inspect Hero"
	select_hero_btn.pressed.connect(func():
		_active_player = _hero_player
		_refresh_stats()
	)
	select_hbox.add_child(select_hero_btn)

	var select_heroine_btn = Button.new()
	select_heroine_btn.text = "Inspect Heroine"
	select_heroine_btn.pressed.connect(func():
		_active_player = _heroine_player
		_refresh_stats()
	)
	select_hbox.add_child(select_heroine_btn)

	var action_grid = GridContainer.new()
	action_grid.columns = 2
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	left_vbox.add_child(action_grid)

	_add_action_btn(action_grid, "+4 Burliness", func(): _active_player.add_primary_bonus("burliness", 4))
	_add_action_btn(action_grid, "-10 HP", func(): _active_player.modify_hp(-10))
	_add_action_btn(action_grid, "-5 MP", func(): _active_player.modify_mp(-5))
	_add_action_btn(action_grid, "+250 XP", func(): _active_player.add_xp(250))
	_add_action_btn(action_grid, "+50 Zorkmids", func(): _active_player.add_zorkmids(50))
	_add_action_btn(action_grid, "+3 Conflagratory Res", func(): _active_player.add_resistance("conflagratory", 3))
	_add_action_btn(action_grid, "Unlock Next Skill Tier", func():
		for sid in _active_player.chosen_skills:
			if _active_player.can_unlock_skill_tier(sid):
				_active_player.unlock_next_skill_tier(sid)
				break
	)

	var quick_game_btn = Button.new()
	quick_game_btn.text = "Launch Quick Game"
	quick_game_btn.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.QUICK_GAME))
	left_vbox.add_child(quick_game_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_hbox.add_child(scroll)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 15)
	scroll.add_child(_stats_label)

	_apply_sprite_state()
	_refresh_stats()
	print("PLAYER_TEST_READY")

func _add_action_btn(parent_node, title, callback):
	var btn = Button.new()
	btn.text = title
	btn.pressed.connect(func():
		callback.call()
		_refresh_stats()
	)
	parent_node.add_child(btn)

func _apply_sprite_state():
	for player in [_hero_player, _heroine_player]:
		if player == null:
			continue
		player.update_animation(_current_dir.x, _current_dir.y)
		if not _is_moving:
			player.idle()

func _refresh_stats():
	if _active_player == null or _stats_label == null:
		return
	var lines = []
	lines.append("=== " + _active_player.character_name + " (" + _active_player.hero_kind + ") ===")
	lines.append("Level: " + str(_active_player.level) + " | XP: " + str(_active_player.xp) + " / " + str(_active_player.xp_to_next_level) + " | Skill Points: " + str(_active_player.skill_points))
	lines.append("Archetypes: Warrior=" + str(_active_player.warrior_level) + " Rogue=" + str(_active_player.rogue_level) + " Wizard=" + str(_active_player.wizard_level))
	lines.append("HP: " + str(_active_player.hp) + " / " + str(_active_player.max_hp) + " | MP: " + str(_active_player.mp) + " / " + str(_active_player.max_mp))
	lines.append("Zorkmids: " + str(_active_player.get_zorkmids()))
	lines.append("")
	lines.append("--- Chosen Skills (" + str(_active_player.chosen_skills.size()) + ") ---")
	for sid in _active_player.chosen_skills:
		var skill_entry = OD.Database.get_skill(sid)
		var sname = skill_entry.name if skill_entry != null else str(sid)
		var tier = _active_player.get_skill_tier(sid)
		var max_t = _active_player.get_skill_max_tiers(sid)
		lines.append("  " + sname + ": Tier " + str(tier) + "/" + str(max_t))
	lines.append("Unlocked Spells: " + (", ".join(_active_player.unlocked_spells) if not _active_player.unlocked_spells.is_empty() else "None"))
	lines.append("")
	lines.append("--- Primary Stats (6) ---")
	for stat_key in PlayerCharacter.PRIMARY_STAT_KEYS:
		lines.append("  " + stat_key + ": " + str(_active_player.get_primary_stat(stat_key)))
	lines.append("")
	lines.append("--- Secondary Stats (" + str(PlayerCharacter.SECONDARY_STAT_BY_ID.size()) + ") ---")
	var sec_ids = PlayerCharacter.SECONDARY_STAT_BY_ID.keys()
	sec_ids.sort()
	for stat_id in sec_ids:
		var stat_key = PlayerCharacter.SECONDARY_STAT_BY_ID[stat_id]
		lines.append("  [" + str(stat_id) + "] " + stat_key + ": " + str(_active_player.get_secondary_stat(stat_key)))
	lines.append("")
	lines.append("--- Elemental Resistances / Damage Bonuses (16) ---")
	for dmg_type in PlayerCharacter.DAMAGE_TYPES:
		lines.append("  " + dmg_type + ": res=" + str(_active_player.get_resistance(dmg_type)) + ", dmg=" + str(_active_player.get_damage_bonus(dmg_type)))
	_stats_label.text = "\n".join(lines)
