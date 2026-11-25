extends Control

class_name SpellHotbar

const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")

const HOTBAR_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

const HOTBAR_OFFSET_TOP = -84
const HOTBAR_OFFSET_BOTTOM = -12
const HOTBAR_SEPARATION = 6
const HOTBAR_SLOT_SIZE = Vector2(56, 56)
const SPELLBOOK_BTN_SIZE = Vector2(72, 56)
const HOTBAR_BORDER_WIDTH = 2
const HOTBAR_CONTENT_MARGIN = 6

const TARGETING_LABEL_OFFSET_TOP = 12
const TARGETING_LABEL_FONT_SIZE = 18

const DIALOG_TEXTURE_MARGIN = 44
const DIALOG_CONTENT_MARGIN_LEFT = 36
const DIALOG_CONTENT_MARGIN_RIGHT = 36
const DIALOG_CONTENT_MARGIN_TOP = 30
const DIALOG_CONTENT_MARGIN_BOTTOM = 32

const SPELLBOOK_WIDTH_RATIO = 0.55
const SPELLBOOK_MIN_WIDTH = 480.0
const SPELLBOOK_MAX_WIDTH = 760.0
const SPELLBOOK_HEIGHT_RATIO = 0.65
const SPELLBOOK_MIN_HEIGHT = 360.0
const SPELLBOOK_MAX_HEIGHT = 560.0
const SPELLBOOK_ROOT_SEPARATION = 10
const SPELLBOOK_TITLE_FONT_SIZE = 22
const SPELLBOOK_LIST_SEPARATION = 8
const SPELLBOOK_ROW_SEPARATION = 10
const SPELLBOOK_DESC_FONT_SIZE = 13

var _dungeon = null
var _hotbar_buttons = []
var _targeting_label = null
var _spellbook_popup = null
var _spellbook_list_vbox = null

func init(dungeon):
	_dungeon = dungeon
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_connect_signals()
	refresh()
	return self

func _build_ui():
	var bottom_center = CenterContainer.new()
	bottom_center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_center.offset_top = HOTBAR_OFFSET_TOP
	bottom_center.offset_bottom = HOTBAR_OFFSET_BOTTOM
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_center)

	var bar_panel = PanelContainer.new()
	bar_panel.add_theme_stylebox_override("panel", _create_hotbar_style())
	bottom_center.add_child(bar_panel)

	var bar_hbox = HBoxContainer.new()
	bar_hbox.add_theme_constant_override("separation", HOTBAR_SEPARATION)
	bar_panel.add_child(bar_hbox)

	_hotbar_buttons.clear()
	for ii in range(PlayerCharacter.HOTBAR_SIZE):
		var slot_idx = ii
		var btn = Button.new()
		btn.custom_minimum_size = HOTBAR_SLOT_SIZE
		btn.clip_text = true
		btn.pressed.connect(func(): _activate_slot(slot_idx))
		bar_hbox.add_child(btn)
		_hotbar_buttons.append(btn)

	var book_btn = Button.new()
	book_btn.text = "Spells\n(M)"
	book_btn.custom_minimum_size = SPELLBOOK_BTN_SIZE
	book_btn.pressed.connect(toggle_spellbook)
	bar_hbox.add_child(book_btn)

	_targeting_label = Label.new()
	_targeting_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_targeting_label.offset_top = TARGETING_LABEL_OFFSET_TOP
	_targeting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_targeting_label.add_theme_font_size_override("font_size", TARGETING_LABEL_FONT_SIZE)
	_targeting_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	_targeting_label.visible = false
	add_child(_targeting_label)

func _connect_signals():
	if _dungeon == null:
		return
	if _dungeon.has_signal("spell_cast_completed"):
		_dungeon.spell_cast_completed.connect(func(_name, _res): refresh())
	if _dungeon.has_signal("spell_targeting_changed"):
		_dungeon.spell_targeting_changed.connect(_on_targeting_changed)
	var scheduler = _dungeon.get_turn_scheduler()
	if scheduler != null:
		scheduler.turn_completed.connect(func(_t, _s): refresh())
	var player = _dungeon.get_player()
	if player != null:
		player.mp_changed.connect(func(_c, _m): refresh())
		player.skills_changed.connect(refresh)

func _on_targeting_changed(spell_name):
	if _targeting_label == null:
		return
	if spell_name == "":
		_targeting_label.visible = false
	else:
		_targeting_label.text = "Targeting: " + spell_name + " (Left-click to cast, Esc/Right-click to cancel)"
		_targeting_label.visible = true

func _activate_slot(slot_idx):
	if _dungeon == null:
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var spell_name = player.get_hotbar_spell(slot_idx)
	if spell_name == "":
		return
	_dungeon.begin_spell_targeting(spell_name)

func handle_key_input(ev):
	if not (ev is InputEventKey) or not ev.is_pressed() or ev.echo:
		return false
	if ev.keycode == KEY_M:
		toggle_spellbook()
		return true
	if is_instance_valid(_spellbook_popup) and ev.keycode == KEY_ESCAPE:
		_close_spellbook()
		return true
	for ii in range(HOTBAR_KEYS.size()):
		if ev.keycode == HOTBAR_KEYS[ii]:
			_activate_slot(ii)
			return true
	return false

func is_spellbook_open():
	return is_instance_valid(_spellbook_popup)

func toggle_spellbook():
	if is_instance_valid(_spellbook_popup):
		_close_spellbook()
	else:
		_open_spellbook()

func _close_spellbook():
	if is_instance_valid(_spellbook_popup):
		_spellbook_popup.queue_free()
		_spellbook_popup = null
		_spellbook_list_vbox = null

func _create_hotbar_style():
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.12, 0.1, 0.09, 0.88)
	box.border_color = Color(0.55, 0.45, 0.3, 0.9)
	box.set_border_width_all(HOTBAR_BORDER_WIDTH)
	box.set_content_margin_all(HOTBAR_CONTENT_MARGIN)
	return box

func _create_dialog_style():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var bg_tex = null
	if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger"):
		bg_tex = dialog_assets.textures.alert_bigger
	if bg_tex != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = bg_tex
		style_box.texture_margin_left = DIALOG_TEXTURE_MARGIN
		style_box.texture_margin_right = DIALOG_TEXTURE_MARGIN
		style_box.texture_margin_top = DIALOG_TEXTURE_MARGIN
		style_box.texture_margin_bottom = DIALOG_TEXTURE_MARGIN
		style_box.content_margin_left = DIALOG_CONTENT_MARGIN_LEFT
		style_box.content_margin_right = DIALOG_CONTENT_MARGIN_RIGHT
		style_box.content_margin_top = DIALOG_CONTENT_MARGIN_TOP
		style_box.content_margin_bottom = DIALOG_CONTENT_MARGIN_BOTTOM
		return style_box
	return _create_hotbar_style()

func _open_spellbook():
	_close_spellbook()
	var viewport_size = get_viewport_rect().size
	var panel_w = clamp(viewport_size.x * SPELLBOOK_WIDTH_RATIO, SPELLBOOK_MIN_WIDTH, SPELLBOOK_MAX_WIDTH)
	var panel_h = clamp(viewport_size.y * SPELLBOOK_HEIGHT_RATIO, SPELLBOOK_MIN_HEIGHT, SPELLBOOK_MAX_HEIGHT)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_spellbook_popup = center

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel", _create_dialog_style())
	center.add_child(panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", SPELLBOOK_ROOT_SEPARATION)
	panel.add_child(root_vbox)

	var header = HBoxContainer.new()
	root_vbox.add_child(header)
	var title = Label.new()
	title.text = "Spellbook"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", SPELLBOOK_TITLE_FONT_SIZE)
	header.add_child(title)
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_close_spellbook)
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_spellbook_list_vbox = VBoxContainer.new()
	_spellbook_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spellbook_list_vbox.add_theme_constant_override("separation", SPELLBOOK_LIST_SEPARATION)
	scroll.add_child(_spellbook_list_vbox)

	_populate_spellbook()

func _populate_spellbook():
	if _spellbook_list_vbox == null or _dungeon == null:
		return
	for child in _spellbook_list_vbox.get_children():
		child.queue_free()
	var player = _dungeon.get_player()
	if player == null:
		return
	if player.unlocked_spells.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No spells unlocked yet. Unlock wizard or skill abilities as you level up."
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_spellbook_list_vbox.add_child(empty_lbl)
		return
	for spell_name in player.unlocked_spells:
		var spell_def = OD.Database.get_spell(spell_name) if OD.Database != null else null
		if spell_def == null:
			continue
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", SPELLBOOK_ROW_SEPARATION)
		_spellbook_list_vbox.add_child(row)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vbox)

		var cost = SpellEngineScript.compute_mana_cost(player, spell_def)
		var cd = player.get_spell_cooldown(spell_name)
		var max_cd = SpellEngineScript.get_cooldown_turns(spell_def)
		var header_lbl = Label.new()
		header_lbl.text = spell_name + "  [MP: " + str(cost) + " | CD: " + str(cd) + "/" + str(max_cd) + " | " + str(spell_def.type) + "]"
		info_vbox.add_child(header_lbl)

		if str(spell_def.description) != "":
			var desc_lbl = Label.new()
			desc_lbl.text = str(spell_def.description)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.add_theme_font_size_override("font_size", SPELLBOOK_DESC_FONT_SIZE)
			info_vbox.add_child(desc_lbl)

		var cast_btn = Button.new()
		cast_btn.text = "Cast"
		var chosen = spell_name
		cast_btn.pressed.connect(func():
			_close_spellbook()
			_dungeon.begin_spell_targeting(chosen)
		)
		row.add_child(cast_btn)

func refresh():
	if _dungeon == null:
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var slots = player.get_hotbar_spells()
	for ii in range(min(_hotbar_buttons.size(), slots.size())):
		var btn = _hotbar_buttons[ii]
		var spell_name = slots[ii]
		var key_lbl = str((ii + 1) % 10)
		if spell_name == "":
			btn.text = key_lbl
			btn.tooltip_text = "Empty slot " + key_lbl
			btn.disabled = true
			continue
		var spell_def = OD.Database.get_spell(spell_name) if OD.Database != null else null
		var cost = SpellEngineScript.compute_mana_cost(player, spell_def)
		var cd = player.get_spell_cooldown(spell_name)
		var short_name = spell_name.substr(0, 6)
		if cd > 0:
			btn.text = key_lbl + ":" + short_name + "\nCD " + str(cd)
		else:
			btn.text = key_lbl + ":" + short_name + "\n" + str(cost) + "MP"
		btn.tooltip_text = spell_name + " (MP: " + str(cost) + ", CD: " + str(cd) + ")"
		btn.disabled = cd > 0 or int(player.mp) < cost
