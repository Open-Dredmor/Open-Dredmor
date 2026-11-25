extends CanvasLayer

class_name SkillTreeDialog

const FloatingWindowScript = preload("res://script/instance/ui/floating_window.gd")
const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")

const TOME_BG_TEX = "ui/gameplay/skilltome_bg.png"
const LEARN_BTN_TEXS = {
	normal = "ui/gameplay/skilltome_learn0.png",
	hover = "ui/gameplay/skilltome_learn1.png",
	pressed = "ui/gameplay/skilltome_learn1.png"
}
const CLOSE_BTN_TEXS = {
	normal = "ui/gameplay/xclose_copper0.png",
	hover = "ui/gameplay/xclose_copper1.png",
	pressed = "ui/gameplay/xclose_copper2.png"
}

const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)
const TOOLTIP_OFFSET = Vector2(16, 16)
const TOOLTIP_SCREEN_MARGIN = 8

var _player = null
var _callbacks = {}
var _active_tab = "skills"

var _window = null
var _panel = null
var _points_label = null
var _skills_tab_btn = null
var _spells_tab_btn = null
var _content_vbox = null
var _tooltip_panel = null
var _tooltip_label = null

func init(player, callbacks = {}, initial_tab = "skills"):
	_player = player
	_callbacks = callbacks
	_active_tab = initial_tab if initial_tab in ["skills", "spells"] else "skills"
	layer = 12
	_build_ui()
	_connect_signals()
	refresh()
	return self

func _connect_signals():
	if _player == null:
		return
	if _player.has_signal("skills_changed") and not _player.skills_changed.is_connected(refresh):
		_player.skills_changed.connect(refresh)
	if _player.has_signal("leveled_up") and not _player.leveled_up.is_connected(_on_player_leveled_up):
		_player.leveled_up.connect(_on_player_leveled_up)
	var vp = get_viewport()
	if vp != null and not vp.size_changed.is_connected(_update_panel_bounds):
		vp.size_changed.connect(_update_panel_bounds)

func _on_player_leveled_up(_new_level, _points):
	refresh()

func _font():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	return dialog_assets.font if dialog_assets != null else null

func _load_tex(path):
	if path == "" or OD.Load == null:
		return null
	if OD.Load.exists(path):
		return OD.Load.image(path)
	return null

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

func _make_texture_button(paths_dict, min_size):
	var btn = TextureButton.new()
	btn.custom_minimum_size = min_size
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if paths_dict.has("normal"):
		btn.texture_normal = _load_tex(paths_dict.normal)
	if paths_dict.has("hover"):
		btn.texture_hover = _load_tex(paths_dict.hover)
	if paths_dict.has("pressed"):
		btn.texture_pressed = _load_tex(paths_dict.pressed)
	return btn

func _create_panel_style():
	var bg_tex = _load_tex(TOME_BG_TEX)
	if bg_tex != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = bg_tex
		style_box.texture_margin_left = 52
		style_box.texture_margin_right = 52
		style_box.texture_margin_top = 48
		style_box.texture_margin_bottom = 48
		style_box.content_margin_left = 44
		style_box.content_margin_right = 44
		style_box.content_margin_top = 38
		style_box.content_margin_bottom = 38
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = Color(0.16, 0.13, 0.10, 0.96)
	fallback.border_color = Color(0.62, 0.50, 0.32, 0.95)
	fallback.set_border_width_all(3)
	fallback.set_content_margin_all(28)
	return fallback

func _build_ui():
	var vp_size = _get_viewport_size()
	var panel_w = clamp(vp_size.x * 0.62, 560.0, 860.0)
	var panel_h = clamp(vp_size.y * 0.72, 420.0, 620.0)

	_window = FloatingWindowScript.new()
	_window.min_window_size = Vector2(480.0, 360.0)
	_window.size = Vector2(panel_w, panel_h)
	_window.position = Vector2((vp_size.x - panel_w) * 0.5, max(24.0, (vp_size.y - panel_h) * 0.45))
	add_child(_window)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	_window.add_child(_panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(root_vbox)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = "Skill Tome & Spellbook"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(title_lbl, 24, Color(0.22, 0.14, 0.08))
	header.add_child(title_lbl)

	_points_label = Label.new()
	_style_label(_points_label, 18, Color(0.45, 0.25, 0.05))
	header.add_child(_points_label)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_tex = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)

	_skills_tab_btn = OD.Chrome.parchment_button("Skill Trees", _font(), ink_color, blank_tex, 16)
	_skills_tab_btn.pressed.connect(func(): _switch_tab("skills"))
	header.add_child(_skills_tab_btn)

	_spells_tab_btn = OD.Chrome.parchment_button("Spellbook", _font(), ink_color, blank_tex, 16)
	_spells_tab_btn.pressed.connect(func(): _switch_tab("spells"))
	header.add_child(_spells_tab_btn)

	var close_btn = _make_texture_button(CLOSE_BTN_TEXS, Vector2(24, 24))
	close_btn.pressed.connect(dismiss)
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(_content_vbox)

	_build_tooltip()

func _build_tooltip():
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 50
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.94)
	style.border_color = Color(0.68, 0.56, 0.34, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_tooltip_panel.add_theme_stylebox_override("panel", style)
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.custom_minimum_size = Vector2(240, 0)
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_tooltip_label, 14, Color(0.95, 0.92, 0.85))
	_tooltip_panel.add_child(_tooltip_label)

func _update_panel_bounds():
	if _window != null and is_instance_valid(_window):
		_window.clamp_to_viewport()

func _switch_tab(tab_name):
	_active_tab = tab_name
	_hide_tooltip()
	refresh()

func _process(_delta):
	if _tooltip_panel != null and _tooltip_panel.visible:
		var vp_size = _get_viewport_size()
		var mouse_pos = _window.get_global_mouse_position() if _window != null else Vector2.ZERO
		var tip_size = _tooltip_panel.size
		var target_pos = mouse_pos + TOOLTIP_OFFSET
		if target_pos.x + tip_size.x + TOOLTIP_SCREEN_MARGIN > vp_size.x:
			target_pos.x = max(TOOLTIP_SCREEN_MARGIN, mouse_pos.x - tip_size.x - 12.0)
		if target_pos.y + tip_size.y + TOOLTIP_SCREEN_MARGIN > vp_size.y:
			target_pos.y = max(TOOLTIP_SCREEN_MARGIN, vp_size.y - tip_size.y - TOOLTIP_SCREEN_MARGIN)
		_tooltip_panel.position = target_pos

func _unhandled_input(ev):
	if ev is InputEventKey and ev.is_pressed() and not ev.echo:
		if ev.keycode == KEY_K:
			dismiss()
			get_viewport().set_input_as_handled()

func get_floating_window():
	return _window

func dismiss():
	_hide_tooltip()
	if _callbacks.has("on_close") and _callbacks.on_close.is_valid():
		_callbacks.on_close.call()
	queue_free()

func refresh():
	if _player == null or _content_vbox == null or not is_instance_valid(_content_vbox):
		return
	var sp = int(_player.skill_points)
	if _points_label != null:
		_points_label.text = "Skill Points: " + str(sp)
		var pt_color = Color(0.55, 0.18, 0.04) if sp > 0 else Color(0.35, 0.28, 0.22)
		_points_label.add_theme_color_override("font_color", pt_color)
	if _skills_tab_btn != null:
		_skills_tab_btn.disabled = _active_tab == "skills"
	if _spells_tab_btn != null:
		_spells_tab_btn.disabled = _active_tab == "spells"

	for child in _content_vbox.get_children():
		_content_vbox.remove_child(child)
		child.queue_free()

	if _active_tab == "skills":
		_populate_skill_trees()
	else:
		_populate_spellbook()

func _make_card_style():
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.92, 0.86, 0.74, 0.55)
	card_style.border_color = Color(0.45, 0.34, 0.20, 0.7)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(10)
	return card_style

func _populate_skill_trees():
	if _player.chosen_skills.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No skill trees selected."
		_style_label(empty_lbl, 16, Color(0.24, 0.16, 0.10))
		_content_vbox.add_child(empty_lbl)
		return

	for sid in _player.chosen_skills:
		var skill_entry = OD.Database.get_skill(int(sid)) if OD.Database != null else null
		if skill_entry == null:
			continue
		_build_skill_row(int(sid), skill_entry)

func _build_skill_row(skill_id, skill_entry):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style())
	_content_vbox.add_child(card)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var skill_icon = TextureRect.new()
	skill_icon.custom_minimum_size = Vector2(48, 48)
	skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skill_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skill_icon.texture = _load_tex(str(skill_entry.icon))
	skill_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	skill_icon.mouse_entered.connect(func(): _show_skill_tooltip(skill_entry))
	skill_icon.mouse_exited.connect(_hide_tooltip)
	row.add_child(skill_icon)

	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(180, 0)
	info_vbox.add_theme_constant_override("separation", 2)
	row.add_child(info_vbox)

	var cur_tier = _player.get_skill_tier(skill_id)
	var max_tiers = _player.get_skill_max_tiers(skill_id)

	var name_lbl = Label.new()
	name_lbl.text = str(skill_entry.name)
	_style_label(name_lbl, 17, Color(0.20, 0.12, 0.06))
	info_vbox.add_child(name_lbl)

	var rank_lbl = Label.new()
	rank_lbl.text = str(skill_entry.type).capitalize() + "  (" + str(cur_tier) + "/" + str(max_tiers) + ")"
	_style_label(rank_lbl, 13, Color(0.36, 0.25, 0.16))
	info_vbox.add_child(rank_lbl)

	var tiers_hbox = HBoxContainer.new()
	tiers_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tiers_hbox.add_theme_constant_override("separation", 6)
	row.add_child(tiers_hbox)

	var progression = skill_entry.level_progression
	for idx in range(progression.size()):
		var tier_entry = progression[idx]
		var is_unlocked = idx < cur_tier
		var is_next = idx == cur_tier
		var can_buy = is_next and _player.can_unlock_skill_tier(skill_id)
		var tier_btn = _build_tier_button(skill_id, idx, tier_entry, is_unlocked, is_next, can_buy)
		tiers_hbox.add_child(tier_btn)

	var learn_btn = _make_texture_button(LEARN_BTN_TEXS, Vector2(44, 44))
	learn_btn.disabled = not _player.can_unlock_skill_tier(skill_id)
	learn_btn.modulate = Color(1, 1, 1, 1) if not learn_btn.disabled else Color(0.55, 0.55, 0.55, 0.55)
	learn_btn.tooltip_text = "Unlock next tier of " + str(skill_entry.name)
	learn_btn.pressed.connect(func(): _unlock_skill(skill_id))
	row.add_child(learn_btn)

func _build_tier_button(skill_id, tier_idx, tier_entry, is_unlocked, is_next, can_buy):
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(44, 44)
	var style = StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	if is_unlocked:
		style.bg_color = Color(0.24, 0.38, 0.18, 0.85)
		style.border_color = Color(0.85, 0.72, 0.28, 1.0)
	elif can_buy:
		style.bg_color = Color(0.42, 0.30, 0.10, 0.90)
		style.border_color = Color(1.0, 0.85, 0.25, 1.0)
	elif is_next:
		style.bg_color = Color(0.22, 0.18, 0.14, 0.75)
		style.border_color = Color(0.58, 0.48, 0.34, 0.9)
	else:
		style.bg_color = Color(0.12, 0.10, 0.09, 0.65)
		style.border_color = Color(0.32, 0.28, 0.24, 0.6)
	frame.add_theme_stylebox_override("panel", style)

	var btn = TextureButton.new()
	btn.custom_minimum_size = Vector2(36, 36)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.texture_normal = _load_tex(str(tier_entry.icon))
	btn.modulate = Color(1, 1, 1, 1) if is_unlocked or can_buy else Color(0.48, 0.45, 0.42, 0.85)
	if can_buy:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func(): _unlock_skill(skill_id))
	btn.mouse_entered.connect(func(): _show_tier_tooltip(tier_idx + 1, tier_entry, is_unlocked, can_buy))
	btn.mouse_exited.connect(_hide_tooltip)
	frame.add_child(btn)
	return frame

func _unlock_skill(skill_id):
	if _player == null:
		return
	var res = _player.unlock_next_skill_tier(skill_id)
	if res.get("success", false):
		if OD.Audio != null:
			OD.Audio.play_sfx("levelup")
		if OD.EventLog != null and res.has("level_entry") and res.level_entry != null:
			OD.EventLog.notify("Unlocked " + str(res.level_entry.name) + "!")
		refresh()

func _populate_spellbook():
	if _player.unlocked_spells.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No spells unlocked yet. Unlock wizard or skill abilities as you level up."
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(empty_lbl, 16, Color(0.24, 0.16, 0.10))
		_content_vbox.add_child(empty_lbl)
		return

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_tex = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)

	for spell_name in _player.unlocked_spells:
		var spell_def = OD.Database.get_spell(spell_name) if OD.Database != null else null
		if spell_def == null:
			continue
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_card_style())
		_content_vbox.add_child(card)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(38, 38)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = _load_tex(str(spell_def.icon)) if spell_def.get("icon") != null else null
		row.add_child(icon_rect)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 3)
		row.add_child(info_vbox)

		var cost = SpellEngineScript.compute_mana_cost(_player, spell_def)
		var cd = _player.get_spell_cooldown(spell_name)
		var max_cd = SpellEngineScript.get_cooldown_turns(spell_def)
		var header_lbl = Label.new()
		header_lbl.text = spell_name + "  [MP: " + str(cost) + " | CD: " + str(cd) + "/" + str(max_cd) + " | " + str(spell_def.type) + "]"
		_style_label(header_lbl, 16, Color(0.20, 0.12, 0.06))
		info_vbox.add_child(header_lbl)

		if str(spell_def.description) != "":
			var desc_lbl = Label.new()
			desc_lbl.text = str(spell_def.description)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_style_label(desc_lbl, 13, Color(0.32, 0.22, 0.14))
			info_vbox.add_child(desc_lbl)

		var slots_hbox = HBoxContainer.new()
		slots_hbox.add_theme_constant_override("separation", 2)
		info_vbox.add_child(slots_hbox)

		var assign_lbl = Label.new()
		assign_lbl.text = "Hotbar: "
		_style_label(assign_lbl, 12, Color(0.36, 0.26, 0.16))
		slots_hbox.add_child(assign_lbl)

		var current_slots = _player.get_hotbar_spells()
		for slot_idx in range(PlayerCharacter.HOTBAR_SIZE):
			var key_lbl = str((slot_idx + 1) % 10)
			var slot_btn = Button.new()
			slot_btn.text = key_lbl
			slot_btn.custom_minimum_size = Vector2(24, 22)
			slot_btn.add_theme_font_size_override("font_size", 11)
			var is_assigned = slot_idx < current_slots.size() and current_slots[slot_idx] == spell_name
			slot_btn.modulate = Color(1.0, 0.88, 0.45) if is_assigned else Color(0.85, 0.82, 0.76)
			var chosen_spell = spell_name
			var chosen_slot = slot_idx
			slot_btn.pressed.connect(func():
				_player.set_hotbar_slot(chosen_slot, chosen_spell)
				refresh()
			)
			slots_hbox.add_child(slot_btn)

		var cast_btn = OD.Chrome.parchment_button("Cast", _font(), ink_color, blank_tex, 15)
		cast_btn.disabled = cd > 0 or int(_player.mp) < cost
		var target_spell = spell_name
		cast_btn.pressed.connect(func():
			dismiss()
			if _callbacks.has("on_cast_spell") and _callbacks.on_cast_spell.is_valid():
				_callbacks.on_cast_spell.call(target_spell)
		)
		row.add_child(cast_btn)

func _show_skill_tooltip(skill_entry):
	if _tooltip_panel == null or _tooltip_label == null:
		return
	var lines = [str(skill_entry.name) + " (" + str(skill_entry.type).capitalize() + ")"]
	if str(skill_entry.description) != "":
		lines.append(str(skill_entry.description))
	_tooltip_label.text = "\n".join(lines)
	_tooltip_panel.visible = true

func _show_tier_tooltip(tier_num, tier_entry, is_unlocked, can_buy):
	if _tooltip_panel == null or _tooltip_label == null:
		return
	var status = "Unlocked" if is_unlocked else ("Click to Unlock (1 Skill Point)" if can_buy else "Locked")
	var lines = [
		"Tier " + str(tier_num) + ": " + str(tier_entry.name),
		"[" + status + "]"
	]
	if str(tier_entry.description) != "":
		lines.append(str(tier_entry.description))
	for buff in tier_entry.primary_buffs:
		if typeof(buff) == TYPE_DICTIONARY and buff.has("id"):
			var idx = int(buff.id)
			if idx >= 0 and idx < PlayerCharacter.PRIMARY_STAT_KEYS.size():
				lines.append("+" + str(buff.get("amount", 0)) + " " + PlayerCharacter.PRIMARY_STAT_KEYS[idx].capitalize())
	for buff in tier_entry.secondary_buffs:
		if typeof(buff) == TYPE_DICTIONARY and buff.has("id"):
			var sec_id = int(buff.id)
			if PlayerCharacter.SECONDARY_STAT_BY_ID.has(sec_id):
				lines.append("+" + str(buff.get("amount", 0)) + " " + PlayerCharacter.SECONDARY_STAT_BY_ID[sec_id].replace("_", " ").capitalize())
	for spell_ref in tier_entry.spells:
		if typeof(spell_ref) == TYPE_DICTIONARY and spell_ref.has("name"):
			lines.append("Grants Spell: " + str(spell_ref.name))
	_tooltip_label.text = "\n".join(lines)
	_tooltip_panel.visible = true

func _hide_tooltip():
	if _tooltip_panel != null and is_instance_valid(_tooltip_panel):
		_tooltip_panel.visible = false
