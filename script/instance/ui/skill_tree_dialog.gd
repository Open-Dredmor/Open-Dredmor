extends CanvasLayer

class_name SkillTreeDialog

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const FloatingWindowScript = preload("res://script/instance/ui/floating_window.gd")
const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")

const TOME_BACKGROUND_TEXTURE = "ui/gameplay/skilltome_bg.png"
const LEARN_BUTTON_TEXTURES = {
	normal = "ui/gameplay/skilltome_learn0.png",
	hover = "ui/gameplay/skilltome_learn1.png",
	pressed = "ui/gameplay/skilltome_learn1.png"
}
const CLOSE_BUTTON_TEXTURES = {
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
var _skills_tab_button = null
var _spells_tab_button = null
var _content_vertical_box = null
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
	var viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_panel_bounds):
		viewport.size_changed.connect(_update_panel_bounds)

func _on_player_leveled_up(_new_level, _points):
	refresh()

func _create_panel_style():
	var background_texture = UiHelpers.load_texture(TOME_BACKGROUND_TEXTURE)
	return UiHelpers.create_panel_style(
		background_texture,
		{ left = 52, right = 52, top = 48, bottom = 48 },
		{ left = 44, right = 44, top = 38, bottom = 38 }
	)

func _build_ui():
	var base_size = Vector2(760.0, 560.0)
	_window = UiHelpers.create_floating_window(self, base_size, 0.72, 1.15, 0.6)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	_window.get_content_root().add_child(_panel)

	var root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	_panel.add_child(root_box)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_box.add_child(header)

	var title_label = Label.new()
	title_label.text = "Skill Tome & Spellbook"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiHelpers.style_label(title_label, 24, Color(0.22, 0.14, 0.08))
	header.add_child(title_label)

	_points_label = Label.new()
	UiHelpers.style_label(_points_label, 18, Color(0.45, 0.25, 0.05))
	header.add_child(_points_label)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)
	var font = UiHelpers.dialog_font()

	_skills_tab_button = OD.Chrome.parchment_button("Skill Trees", font, ink_color, blank_texture, 16)
	_skills_tab_button.pressed.connect(func(): _switch_tab("skills"))
	header.add_child(_skills_tab_button)

	_spells_tab_button = OD.Chrome.parchment_button("Spellbook", font, ink_color, blank_texture, 16)
	_spells_tab_button.pressed.connect(func(): _switch_tab("spells"))
	header.add_child(_spells_tab_button)

	var close_button = UiHelpers.make_texture_button(CLOSE_BUTTON_TEXTURES, Vector2(24, 24))
	close_button.pressed.connect(dismiss)
	header.add_child(close_button)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)

	_content_vertical_box = VBoxContainer.new()
	_content_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vertical_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_content_vertical_box)

	var tooltip = UiHelpers.create_tooltip(self, 240, 14)
	_tooltip_panel = tooltip.panel
	_tooltip_label = tooltip.label

func _update_panel_bounds():
	if _window != null and is_instance_valid(_window):
		_window.clamp_to_viewport()

func _switch_tab(tab_name):
	_active_tab = tab_name
	_hide_tooltip()
	refresh()

func _process(_delta):
	if _tooltip_panel != null and _tooltip_panel.visible:
		var mouse_position = _window.get_global_mouse_position() if _window != null else Vector2.ZERO
		UiHelpers.position_tooltip(_tooltip_panel, mouse_position, UiHelpers.viewport_size(self))

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and not event.echo:
		if event.keycode == KEY_K:
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
	if _player == null or _content_vertical_box == null or not is_instance_valid(_content_vertical_box):
		return
	var sp = int(_player.skill_points)
	if _points_label != null:
		_points_label.text = "Skill Points: " + str(sp)
		var point_color = Color(0.55, 0.18, 0.04) if sp > 0 else Color(0.35, 0.28, 0.22)
		_points_label.add_theme_color_override("font_color", point_color)
	if _skills_tab_button != null:
		_skills_tab_button.disabled = _active_tab == "skills"
	if _spells_tab_button != null:
		_spells_tab_button.disabled = _active_tab == "spells"

	for child in _content_vertical_box.get_children():
		_content_vertical_box.remove_child(child)
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
		var empty_label = Label.new()
		empty_label.text = "No skill trees selected."
		UiHelpers.style_label(empty_label, 16, Color(0.24, 0.16, 0.10))
		_content_vertical_box.add_child(empty_label)
		return

	for sid in _player.chosen_skills:
		var skill_entry = OD.Database.get_skill(int(sid)) if OD.Database != null else null
		if skill_entry == null:
			continue
		_build_skill_row(int(sid), skill_entry)

func _build_skill_row(skill_id, skill_entry):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style())
	_content_vertical_box.add_child(card)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var skill_icon = TextureRect.new()
	skill_icon.custom_minimum_size = Vector2(48, 48)
	skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skill_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skill_icon.texture = UiHelpers.load_texture(str(skill_entry.icon))
	skill_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	skill_icon.mouse_entered.connect(func(): _show_skill_tooltip(skill_entry))
	skill_icon.mouse_exited.connect(_hide_tooltip)
	row.add_child(skill_icon)

	var info_box = VBoxContainer.new()
	info_box.custom_minimum_size = Vector2(180, 0)
	info_box.add_theme_constant_override("separation", 2)
	row.add_child(info_box)

	var current_tier = _player.get_skill_tier(skill_id)
	var max_tiers = _player.get_skill_max_tiers(skill_id)

	var name_label = Label.new()
	name_label.text = str(skill_entry.name)
	UiHelpers.style_label(name_label, 17, Color(0.20, 0.12, 0.06))
	info_box.add_child(name_label)

	var rank_label = Label.new()
	rank_label.text = str(skill_entry.type).capitalize() + "  (" + str(current_tier) + "/" + str(max_tiers) + ")"
	UiHelpers.style_label(rank_label, 13, Color(0.36, 0.25, 0.16))
	info_box.add_child(rank_label)

	var tiers_box = HBoxContainer.new()
	tiers_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tiers_box.add_theme_constant_override("separation", 6)
	row.add_child(tiers_box)

	var progression = skill_entry.level_progression
	for index in range(progression.size()):
		var tier_entry = progression[index]
		var is_unlocked = index < current_tier
		var is_next = index == current_tier
		var can_buy = is_next and _player.can_unlock_skill_tier(skill_id)
		var tier_button = _build_tier_button(skill_id, index, tier_entry, is_unlocked, is_next, can_buy)
		tiers_box.add_child(tier_button)

	var learn_button = UiHelpers.make_texture_button(LEARN_BUTTON_TEXTURES, Vector2(44, 44))
	learn_button.disabled = not _player.can_unlock_skill_tier(skill_id)
	learn_button.modulate = Color(1, 1, 1, 1) if not learn_button.disabled else Color(0.55, 0.55, 0.55, 0.55)
	learn_button.tooltip_text = "Unlock next tier of " + str(skill_entry.name)
	learn_button.pressed.connect(func(): _unlock_skill(skill_id))
	row.add_child(learn_button)

func _build_tier_button(skill_id, tier_index, tier_entry, is_unlocked, is_next, can_buy):
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

	var button = TextureButton.new()
	button.custom_minimum_size = Vector2(36, 36)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.texture_normal = UiHelpers.load_texture(str(tier_entry.icon))
	button.modulate = Color(1, 1, 1, 1) if is_unlocked or can_buy else Color(0.48, 0.45, 0.42, 0.85)
	if can_buy:
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func(): _unlock_skill(skill_id))
	button.mouse_entered.connect(func(): _show_tier_tooltip(tier_index + 1, tier_entry, is_unlocked, can_buy))
	button.mouse_exited.connect(_hide_tooltip)
	frame.add_child(button)
	return frame

func _unlock_skill(skill_id):
	if _player == null:
		return
	var result = _player.unlock_next_skill_tier(skill_id)
	if result.get("success", false):
		if OD.Audio != null:
			OD.Audio.play_sfx("levelup")
		if OD.EventLog != null and result.has("level_entry") and result.level_entry != null:
			OD.EventLog.notify("Unlocked " + str(result.level_entry.name) + "!")
		refresh()

func _populate_spellbook():
	if _player.unlocked_spells.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No spells unlocked yet. Unlock wizard or skill abilities as you level up."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiHelpers.style_label(empty_label, 16, Color(0.24, 0.16, 0.10))
		_content_vertical_box.add_child(empty_label)
		return

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)
	var font = UiHelpers.dialog_font()

	for spell_name in _player.unlocked_spells:
		var spell_definition = OD.Database.get_spell(spell_name) if OD.Database != null else null
		if spell_definition == null:
			continue
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_card_style())
		_content_vertical_box.add_child(card)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(38, 38)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = UiHelpers.load_texture(str(spell_definition.icon)) if spell_definition.get("icon") != null else null
		row.add_child(icon_rect)

		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.add_theme_constant_override("separation", 3)
		row.add_child(info_box)

		var cost = SpellEngineScript.compute_mana_cost(_player, spell_definition)
		var cooldown = _player.get_spell_cooldown(spell_name)
		var max_cooldown = SpellEngineScript.get_cooldown_turns(spell_definition)
		var header_label = Label.new()
		header_label.text = spell_name + "  [MP: " + str(cost) + " | CD: " + str(cooldown) + "/" + str(max_cooldown) + " | " + str(spell_definition.type) + "]"
		UiHelpers.style_label(header_label, 16, Color(0.20, 0.12, 0.06))
		info_box.add_child(header_label)

		if str(spell_definition.description) != "":
			var description_label = Label.new()
			description_label.text = str(spell_definition.description)
			description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			UiHelpers.style_label(description_label, 13, Color(0.32, 0.22, 0.14))
			info_box.add_child(description_label)

		var slots_box = HBoxContainer.new()
		slots_box.add_theme_constant_override("separation", 2)
		info_box.add_child(slots_box)

		var assign_label = Label.new()
		assign_label.text = "Hotbar: "
		UiHelpers.style_label(assign_label, 12, Color(0.36, 0.26, 0.16))
		slots_box.add_child(assign_label)

		var current_slots = _player.get_hotbar_spells()
		for slot_index in range(PlayerCharacter.HOTBAR_SIZE):
			var key_label = str((slot_index + 1) % 10)
			var slot_button = Button.new()
			slot_button.text = key_label
			slot_button.custom_minimum_size = Vector2(24, 22)
			slot_button.add_theme_font_size_override("font_size", 11)
			var is_assigned = slot_index < current_slots.size() and current_slots[slot_index] == spell_name
			slot_button.modulate = Color(1.0, 0.88, 0.45) if is_assigned else Color(0.85, 0.82, 0.76)
			var chosen_spell = spell_name
			var chosen_slot = slot_index
			slot_button.pressed.connect(func():
				_player.set_hotbar_slot(chosen_slot, chosen_spell)
				refresh()
			)
			slots_box.add_child(slot_button)

		var cast_button = OD.Chrome.parchment_button("Cast", font, ink_color, blank_texture, 15)
		cast_button.disabled = cooldown > 0 or int(_player.mp) < cost
		var target_spell = spell_name
		cast_button.pressed.connect(func():
			dismiss()
			if _callbacks.has("on_cast_spell") and _callbacks.on_cast_spell.is_valid():
				_callbacks.on_cast_spell.call(target_spell)
		)
		row.add_child(cast_button)

func _show_skill_tooltip(skill_entry):
	if _tooltip_panel == null or _tooltip_label == null:
		return
	var lines = [str(skill_entry.name) + " (" + str(skill_entry.type).capitalize() + ")"]
	if str(skill_entry.description) != "":
		lines.append(str(skill_entry.description))
	_tooltip_label.text = "\n".join(lines)
	_tooltip_panel.visible = true

func _show_tier_tooltip(tier_number, tier_entry, is_unlocked, can_buy):
	if _tooltip_panel == null or _tooltip_label == null:
		return
	var status = "Unlocked" if is_unlocked else ("Click to Unlock (1 Skill Point)" if can_buy else "Locked")
	var lines = [
		"Tier " + str(tier_number) + ": " + str(tier_entry.name),
		"[" + status + "]"
	]
	if str(tier_entry.description) != "":
		lines.append(str(tier_entry.description))
	for buff in tier_entry.primary_buffs:
		if typeof(buff) == TYPE_DICTIONARY and buff.has("id"):
			var index = int(buff.id)
			if index >= 0 and index < PlayerCharacter.PRIMARY_STAT_KEYS.size():
				lines.append("+" + str(buff.get("amount", 0)) + " " + PlayerCharacter.PRIMARY_STAT_KEYS[index].capitalize())
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
