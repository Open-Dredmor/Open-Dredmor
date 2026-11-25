extends Control

class_name CoreHud

const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")
const MinimapOverlayScript = preload("res://script/instance/ui/minimap.gd")

const BAR_WIDTH = 1024.0
const BAR_HEIGHT = 120.0
const HOTBAR_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const MAX_LOG_LINES = 7

const MENU_TABS = [
	{ id = "menu", prefix = "ui/gameplay/game_button_menu", tip = "Menu (Esc)" },
	{ id = "character", prefix = "ui/gameplay/game_button_character", tip = "Character Sheet (I)" },
	{ id = "inventory", prefix = "ui/gameplay/game_button_inventory", tip = "Inventory (I)" },
	{ id = "skills", prefix = "ui/gameplay/game_button_skills", tip = "Skills & Spells (M)" },
	{ id = "quests", prefix = "ui/gameplay/game_button_quests", tip = "Quests" },
	{ id = "crafting", prefix = "ui/gameplay/game_button_crafting", tip = "Crafting (C)" }
]

var _dungeon = null
var _callbacks = {}

var _minimap = null
var _room_label = null
var _log_vbox = null
var _log_scroll = null
var _log_expanded = false
var _targeting_label = null

var _bar_root = null
var _zorkmid_label = null
var _portrait_rect = null
var _life_bar = null
var _life_label = null
var _mana_bar = null
var _mana_label = null
var _xp_bar = null
var _xp_label = null

var _belt_buttons = []
var _spell_buttons = []
var _spellbook_popup = null
var _spellbook_list_vbox = null
var _menu_popup = null

func _ready():
	_update_bar_scale()
	_update_top_right_layout()
	var vp = get_viewport()
	if vp != null:
		vp.size_changed.connect(_update_bar_scale)
		vp.size_changed.connect(_update_top_right_layout)

func init(dungeon, callbacks = {}):
	_dungeon = dungeon
	_callbacks = callbacks
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_left_log()
	_build_top_right_location()
	_build_targeting_banner()
	_build_bottom_bar()
	_connect_signals()
	_sync_initial_state()
	return self

func _font():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	return dialog_assets.font if dialog_assets != null else null

func _styled_label(font_size, font_color, outline_size = 2):
	var lbl = Label.new()
	var font_res = _font()
	if font_res != null:
		lbl.add_theme_font_override("font", font_res)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.add_theme_constant_override("outline_size", outline_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _load_tex(path):
	if path == "" or OD.Load == null:
		return null
	if OD.Load.exists(path):
		return OD.Load.image(path)
	return null

func _build_top_left_log():
	_log_scroll = ScrollContainer.new()
	_log_scroll.position = Vector2(14, 10)
	_log_scroll.custom_minimum_size = Vector2(540, 140)
	_log_scroll.size = Vector2(540, 140)
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_log_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_log_scroll)

	_log_vbox = VBoxContainer.new()
	_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_vbox.add_theme_constant_override("separation", 2)
	_log_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_scroll.add_child(_log_vbox)

func toggle_log_history():
	_log_expanded = not _log_expanded
	if _log_scroll == null or not is_instance_valid(_log_scroll):
		return
	if _log_expanded:
		_log_scroll.custom_minimum_size = Vector2(560, 320)
		_log_scroll.size = Vector2(560, 320)
		_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_log_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0.06, 0.05, 0.04, 0.84)
		bg.border_color = Color(0.55, 0.44, 0.28, 0.9)
		bg.set_border_width_all(1)
		bg.set_content_margin_all(8)
		_log_scroll.add_theme_stylebox_override("panel", bg)
	else:
		_log_scroll.custom_minimum_size = Vector2(540, 140)
		_log_scroll.size = Vector2(540, 140)
		_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_log_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_log_scroll.remove_theme_stylebox_override("panel")
	_rebuild_log_lines()

func _rebuild_log_lines():
	if _log_vbox == null or not is_instance_valid(_log_vbox):
		return
	for child in _log_vbox.get_children():
		_log_vbox.remove_child(child)
		child.queue_free()
	if OD.EventLog == null or not OD.EventLog.has_method("get_history"):
		return
	var history = OD.EventLog.get_history()
	var start_idx = 0 if _log_expanded else max(0, history.size() - MAX_LOG_LINES)
	for ii in range(start_idx, history.size()):
		_add_log_label(history[ii])
	_scroll_log_to_bottom()

func _scroll_log_to_bottom():
	if _log_scroll == null or not is_instance_valid(_log_scroll):
		return
	call_deferred("_apply_log_scroll_bottom")

func _apply_log_scroll_bottom():
	if _log_scroll != null and is_instance_valid(_log_scroll):
		var vbar = _log_scroll.get_v_scroll_bar()
		if vbar != null:
			_log_scroll.scroll_vertical = int(vbar.max_value)

func _build_top_right_location():
	_minimap = MinimapOverlayScript.new().init(_dungeon, 1)
	_minimap.zoom_changed.connect(func(_lvl): _update_top_right_layout())
	add_child(_minimap)

	_room_label = _styled_label(16, Color(0.92, 0.92, 0.95), 2)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_room_label)
	_update_top_right_layout()

func _update_top_right_layout():
	if not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	var margin_right = 6.0
	var margin_top = 4.0
	if _minimap != null and is_instance_valid(_minimap):
		var frame_size = _minimap.get_frame_size()
		_minimap.position = Vector2(vp_size.x - frame_size.x - margin_right, margin_top)
		if _room_label != null and is_instance_valid(_room_label):
			var label_w = max(340.0, frame_size.x)
			_room_label.position = Vector2(vp_size.x - label_w - margin_right, margin_top + frame_size.y + 4.0)
			_room_label.size = Vector2(label_w, 26.0)

func _build_targeting_banner():
	_targeting_label = _styled_label(18, Color(0.55, 0.9, 1.0), 3)
	_targeting_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_targeting_label.offset_top = 12
	_targeting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_targeting_label.visible = false
	add_child(_targeting_label)

func _build_bottom_bar():
	var anchor = Control.new()
	anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	anchor.offset_top = -BAR_HEIGHT
	anchor.offset_bottom = 0
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)

	_bar_root = Control.new()
	_bar_root.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(_bar_root)

	var bg = TextureRect.new()
	bg.texture = _load_tex("ui/gameplay/bottombar_bg.png")
	bg.position = Vector2.ZERO
	bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar_root.add_child(bg)

	_build_menu_tabs()
	_build_zorkmid_box()
	_build_digest_button()
	_build_belt_slots()
	_build_portrait()
	_build_resource_bars()
	_build_spell_slots()

func _update_bar_scale():
	if _bar_root == null or not is_instance_valid(_bar_root) or not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0.0:
		return
	var scale_factor = min(1.0, vp_size.x / BAR_WIDTH)
	_bar_root.scale = Vector2(scale_factor, scale_factor)
	var scaled_w = BAR_WIDTH * scale_factor
	var scaled_h = BAR_HEIGHT * scale_factor
	_bar_root.position = Vector2((vp_size.x - scaled_w) * 0.5, BAR_HEIGHT - scaled_h)

func _build_menu_tabs():
	var tab_w = 56.0
	var tab_h = 24.0
	var start_x = 60.0
	var pos_y = 26.0
	for ii in range(MENU_TABS.size()):
		var tab = MENU_TABS[ii]
		var btn = TextureButton.new()
		btn.position = Vector2(start_x + ii * tab_w, pos_y)
		btn.size = Vector2(tab_w, tab_h)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.texture_normal = _load_tex(tab.prefix + "0.png")
		btn.texture_hover = _load_tex(tab.prefix + "1.png")
		btn.texture_pressed = _load_tex(tab.prefix + "2.png")
		btn.tooltip_text = tab.tip
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var tab_id = tab.id
		btn.pressed.connect(func(): _on_menu_tab_pressed(tab_id))
		_bar_root.add_child(btn)

func _build_zorkmid_box():
	_zorkmid_label = _styled_label(16, Color(0.95, 0.92, 0.85), 2)
	_zorkmid_label.position = Vector2(62, 62)
	_zorkmid_label.size = Vector2(62, 26)
	_zorkmid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zorkmid_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_root.add_child(_zorkmid_label)

func _build_digest_button():
	var btn = TextureButton.new()
	btn.position = Vector2(0, 95)
	btn.size = Vector2(60, 24)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.texture_normal = _load_tex("ui/gameplay/digest0.png")
	btn.texture_hover = _load_tex("ui/gameplay/digest1.png")
	btn.tooltip_text = "Wait 1 Turn (Space)"
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		if _callbacks.has("on_wait") and _callbacks.on_wait.is_valid():
			_callbacks.on_wait.call()
	)
	_bar_root.add_child(btn)

func _build_belt_slots():
	_belt_buttons.clear()
	for ii in range(PlayerCharacter.BELT_SIZE):
		var slot_idx = ii
		var key_text = "SHIFT " + str(ii + 1) if ii == 0 else str(ii + 1)
		var btn = _create_slot_button(Vector2(134 + ii * 36, 58), Vector2(32, 32), key_text)
		btn.pressed.connect(func(): _activate_belt_slot(slot_idx))
		_bar_root.add_child(btn)
		_belt_buttons.append(btn)

func _build_portrait():
	_portrait_rect = TextureRect.new()
	_portrait_rect.position = Vector2(464, 18)
	_portrait_rect.size = Vector2(96, 96)
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(_portrait_rect)

func _build_resource_bars():
	_life_bar = TextureProgressBar.new()
	_life_bar.position = Vector2(60, 95)
	_life_bar.size = Vector2(400, 20)
	_life_bar.texture_under = _load_tex("ui/gameplay/lifebar0.png")
	_life_bar.texture_progress = _load_tex("ui/gameplay/lifebar1.png")
	_life_bar.nine_patch_stretch = false
	_life_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(_life_bar)

	_life_label = _styled_label(13, Color(1, 0.96, 0.96), 2)
	_life_label.position = Vector2(60, 94)
	_life_label.size = Vector2(400, 21)
	_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_life_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_root.add_child(_life_label)

	_xp_bar = TextureProgressBar.new()
	_xp_bar.position = Vector2(572, 84)
	_xp_bar.size = Vector2(384, 8)
	_xp_bar.texture_under = _load_tex("ui/gameplay/expbar0.png")
	_xp_bar.texture_progress = _load_tex("ui/gameplay/expbar1.png")
	_xp_bar.nine_patch_stretch = false
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(_xp_bar)

	_xp_label = _styled_label(10, Color(0.95, 0.9, 0.65), 2)
	_xp_label.position = Vector2(572, 81)
	_xp_label.size = Vector2(384, 13)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_root.add_child(_xp_label)

	_mana_bar = TextureProgressBar.new()
	_mana_bar.position = Vector2(564, 95)
	_mana_bar.size = Vector2(400, 20)
	_mana_bar.texture_under = _load_tex("ui/gameplay/manabar0.png")
	_mana_bar.texture_progress = _load_tex("ui/gameplay/manabar1.png")
	_mana_bar.nine_patch_stretch = false
	_mana_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(_mana_bar)

	_mana_label = _styled_label(13, Color(0.92, 0.96, 1.0), 2)
	_mana_label.position = Vector2(564, 94)
	_mana_label.size = Vector2(400, 21)
	_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_root.add_child(_mana_label)

func _build_spell_slots():
	_spell_buttons.clear()
	for ii in range(PlayerCharacter.HOTBAR_SIZE):
		var slot_idx = ii
		var key_lbl = str((ii + 1) % 10)
		var btn = _create_slot_button(Vector2(612 + ii * 36, 44), Vector2(34, 34), key_lbl)
		btn.pressed.connect(func(): _activate_spell_slot(slot_idx))
		_bar_root.add_child(btn)
		_spell_buttons.append(btn)

func _create_slot_button(pos, slot_size, key_text):
	var btn = Button.new()
	btn.position = pos
	btn.size = slot_size
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var empty_style = StyleBoxEmpty.new()
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 0.9, 0.55, 0.16)
	hover_style.border_color = Color(0.9, 0.78, 0.42, 0.65)
	hover_style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.position = Vector2(1, 1)
	icon_rect.size = slot_size - Vector2(2, 2)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_rect)

	var key_lbl = _styled_label(9, Color(0.92, 0.88, 0.72), 2)
	key_lbl.name = "KeyLabel"
	key_lbl.text = key_text
	key_lbl.position = Vector2(2, 0)
	btn.add_child(key_lbl)

	var info_lbl = _styled_label(10, Color(1.0, 1.0, 1.0), 2)
	info_lbl.name = "InfoLabel"
	info_lbl.position = Vector2(1, slot_size.y - 13)
	info_lbl.size = Vector2(slot_size.x - 2, 12)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	btn.add_child(info_lbl)

	return btn

func _connect_signals():
	if OD.EventLog != null and OD.EventLog.has_signal("message_logged"):
		OD.EventLog.message_logged.connect(_on_event_logged)
	if _dungeon == null:
		return
	if _dungeon.has_signal("floor_changed"):
		_dungeon.floor_changed.connect(func(_lvl, _branch): refresh_location())
	if _dungeon.has_signal("fov_updated"):
		_dungeon.fov_updated.connect(refresh_minimap)
	if _dungeon.has_signal("spell_cast_completed"):
		_dungeon.spell_cast_completed.connect(func(_name, _res): refresh_all())
	if _dungeon.has_signal("spell_targeting_changed"):
		_dungeon.spell_targeting_changed.connect(_on_targeting_changed)
	var scheduler = _dungeon.get_turn_scheduler()
	if scheduler != null:
		scheduler.turn_completed.connect(func(_turn_number, _summary):
			refresh_location()
			refresh_all()
		)
	var player = _dungeon.get_player()
	if player != null:
		player.hp_changed.connect(func(_c, _m): refresh_vitals())
		player.mp_changed.connect(func(_c, _m): refresh_vitals())
		player.xp_changed.connect(func(_x, _n, _l): refresh_vitals())
		player.leveled_up.connect(func(_l, _sp): refresh_vitals())
		player.zorkmids_changed.connect(func(_z): refresh_zorkmids())
		player.stats_changed.connect(refresh_vitals)
		player.skills_changed.connect(refresh_spell_hotbar)
		player.inventory_changed.connect(func():
			player.sync_belt_with_inventory()
			refresh_belt()
		)
		player.belt_changed.connect(refresh_belt)

func _sync_initial_state():
	if _dungeon != null and _dungeon.get_player() != null:
		_dungeon.get_player().sync_belt_with_inventory()
	_rebuild_log_lines()
	refresh_location()
	refresh_all()

func refresh_all():
	refresh_vitals()
	refresh_zorkmids()
	refresh_belt()
	refresh_spell_hotbar()

func refresh_location():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.refresh()
	if _room_label != null:
		var room_name = _dungeon.get_current_room_name()
		_room_label.text = room_name if room_name != "" else str(_dungeon.get_branch_name())

func refresh_minimap():
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.refresh()

func get_minimap():
	return _minimap

func refresh_vitals():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	if _life_bar != null:
		_life_bar.max_value = max(1, int(player.max_hp))
		_life_bar.value = clamp(int(player.hp), 0, int(player.max_hp))
	if _life_label != null:
		_life_label.text = str(int(player.hp)) + " / " + str(int(player.max_hp))
	if _mana_bar != null:
		_mana_bar.max_value = max(1, int(player.max_mp))
		_mana_bar.value = clamp(int(player.mp), 0, int(player.max_mp))
	if _mana_label != null:
		_mana_label.text = str(int(player.mp)) + " / " + str(int(player.max_mp))
	if _xp_bar != null:
		_xp_bar.max_value = max(1, int(player.xp_to_next_level))
		_xp_bar.value = clamp(int(player.xp), 0, int(player.xp_to_next_level))
	if _xp_label != null:
		_xp_label.text = str(int(player.xp)) + " / " + str(int(player.xp_to_next_level))
	_update_portrait(player)

func _update_portrait(player):
	if _portrait_rect == null or player == null:
		return
	var prefix = "portraitf" if str(player.hero_kind) == "heroine" else "portrait"
	var hp_ratio = float(player.hp) / float(max(1, int(player.max_hp)))
	var tier = "100"
	if hp_ratio < 0.25:
		tier = "25"
	elif hp_ratio < 0.5:
		tier = "50"
	var tex = _load_tex("ui/portrait/" + prefix + "_" + tier + "_stare.png")
	if tex != null:
		_portrait_rect.texture = tex

func refresh_zorkmids():
	if _zorkmid_label == null or _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player != null:
		_zorkmid_label.text = str(player.get_zorkmids())

func refresh_belt():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var items = player.get_belt_items()
	for ii in range(min(_belt_buttons.size(), items.size())):
		var btn = _belt_buttons[ii]
		var icon_rect = btn.get_node("Icon")
		var info_lbl = btn.get_node("InfoLabel")
		var item_name = items[ii]
		if item_name == "":
			icon_rect.texture = null
			info_lbl.text = ""
			btn.tooltip_text = "Belt Slot " + str(ii + 1) + " (Shift+" + str(ii + 1) + ")"
			btn.disabled = true
			continue
		var inv_idx = player.find_inventory_index_by_name(item_name)
		var item = player.inventory[inv_idx] if inv_idx >= 0 else null
		var count = player.get_inventory_count_by_name(item_name)
		icon_rect.texture = _load_tex(str(item.get("icon", ""))) if item != null else null
		info_lbl.text = str(count) if count > 1 else ""
		btn.tooltip_text = item_name + " x" + str(count) + " (Shift+" + str(ii + 1) + ")"
		btn.disabled = inv_idx == -1

func refresh_spell_hotbar():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var slots = player.get_hotbar_spells()
	for ii in range(min(_spell_buttons.size(), slots.size())):
		var btn = _spell_buttons[ii]
		var icon_rect = btn.get_node("Icon")
		var info_lbl = btn.get_node("InfoLabel")
		var spell_name = slots[ii]
		var key_lbl = str((ii + 1) % 10)
		if spell_name == "":
			icon_rect.texture = null
			info_lbl.text = ""
			btn.tooltip_text = "Empty Spell Slot " + key_lbl
			btn.disabled = true
			continue
		var spell_def = OD.Database.get_spell(spell_name) if OD.Database != null else null
		var cost = SpellEngineScript.compute_mana_cost(player, spell_def)
		var cd = player.get_spell_cooldown(spell_name)
		var icon_path = str(spell_def.icon) if spell_def != null and spell_def.get("icon") != null else ""
		icon_rect.texture = _load_tex(icon_path)
		if cd > 0:
			info_lbl.text = "CD " + str(cd)
			info_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		elif cost > 0:
			info_lbl.text = str(cost)
			info_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
		else:
			info_lbl.text = ""
		btn.tooltip_text = spell_name + " (MP: " + str(cost) + ", CD: " + str(cd) + ")"
		btn.disabled = cd > 0 or int(player.mp) < cost

func _on_targeting_changed(spell_name):
	if _targeting_label == null:
		return
	if spell_name == "":
		_targeting_label.visible = false
	else:
		_targeting_label.text = "Targeting: " + spell_name + " (Left-click to cast, Esc/Right-click to cancel)"
		_targeting_label.visible = true

func _on_event_logged(message):
	_append_log_line(message)

func _add_log_label(message):
	var line = _styled_label(14, Color(0.95, 0.95, 0.95), 2)
	line.text = str(message)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(520, 0)
	_log_vbox.add_child(line)

func _append_log_line(message):
	if _log_vbox == null or not is_instance_valid(_log_vbox):
		return
	_add_log_label(message)
	if not _log_expanded:
		while _log_vbox.get_child_count() > MAX_LOG_LINES:
			var oldest = _log_vbox.get_child(0)
			_log_vbox.remove_child(oldest)
			oldest.queue_free()
	_scroll_log_to_bottom()

func _activate_belt_slot(slot_idx):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var item_name = player.get_belt_item(slot_idx)
	if item_name == "":
		return
	var inv_idx = player.find_inventory_index_by_name(item_name)
	if inv_idx == -1:
		return
	var res = _dungeon.begin_use_inventory_item(inv_idx)
	if typeof(res) == TYPE_DICTIONARY and res.get("open_crafting", false):
		_dungeon.open_crafting_dialog(str(res.get("tool_tag", "")))

func _activate_spell_slot(slot_idx):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var spell_name = player.get_hotbar_spell(slot_idx)
	if spell_name == "":
		return
	_dungeon.begin_spell_targeting(spell_name)

func _on_menu_tab_pressed(tab_id):
	match tab_id:
		"menu":
			toggle_pause_menu()
		"character", "inventory":
			if _callbacks.has("on_inventory") and _callbacks.on_inventory.is_valid():
				_callbacks.on_inventory.call()
		"skills":
			toggle_spellbook()
		"crafting":
			if _dungeon != null and is_instance_valid(_dungeon):
				_dungeon.open_crafting_dialog()
		"quests":
			if OD.EventLog != null:
				OD.EventLog.notify("No active quests.")

func is_modal_open():
	return is_instance_valid(_spellbook_popup) or is_instance_valid(_menu_popup)

func is_spellbook_open():
	return is_instance_valid(_spellbook_popup)

func handle_key_input(ev):
	if not (ev is InputEventKey) or not ev.is_pressed() or ev.echo:
		return false
	if is_instance_valid(_menu_popup) and ev.keycode == KEY_ESCAPE:
		_close_pause_menu()
		return true
	if is_instance_valid(_spellbook_popup) and ev.keycode == KEY_ESCAPE:
		_close_spellbook()
		return true
	if _log_expanded and ev.keycode == KEY_ESCAPE:
		toggle_log_history()
		return true
	if ev.keycode == KEY_L:
		toggle_log_history()
		return true
	if ev.keycode == KEY_M:
		toggle_spellbook()
		return true
	if ev.keycode == KEY_TAB:
		if _minimap != null and is_instance_valid(_minimap):
			_minimap.cycle_zoom(ev.shift_pressed)
		return true
	if ev.keycode == KEY_EQUAL or ev.keycode == KEY_KP_ADD:
		if _minimap != null and is_instance_valid(_minimap):
			_minimap.zoom_in()
		return true
	if ev.keycode == KEY_MINUS or ev.keycode == KEY_KP_SUBTRACT:
		if _minimap != null and is_instance_valid(_minimap):
			_minimap.zoom_out()
		return true
	for ii in range(HOTBAR_KEYS.size()):
		if ev.keycode == HOTBAR_KEYS[ii]:
			if ev.shift_pressed and ii < PlayerCharacter.BELT_SIZE:
				_activate_belt_slot(ii)
			else:
				_activate_spell_slot(ii)
			return true
	return false

func toggle_pause_menu():
	if is_instance_valid(_menu_popup):
		_close_pause_menu()
		return
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_menu_popup = center

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 220)
	panel.add_theme_stylebox_override("panel", _create_dialog_style())
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = _styled_label(24, Color(0.22, 0.14, 0.08), 0)
	title.text = "Game Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_tex = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)

	var resume_btn = OD.Chrome.parchment_button("Resume", _font(), ink_color, blank_tex, 18)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	var main_btn = OD.Chrome.parchment_button("Main Menu", _font(), ink_color, blank_tex, 18)
	main_btn.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.MAIN_MENU))
	vbox.add_child(main_btn)

	var quit_btn = OD.Chrome.parchment_button("Quit", _font(), ink_color, blank_tex, 18)
	quit_btn.pressed.connect(func(): OD.Scenes.quit())
	vbox.add_child(quit_btn)

func _close_pause_menu():
	if is_instance_valid(_menu_popup):
		_menu_popup.queue_free()
		_menu_popup = null

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

func _create_dialog_style():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var bg_tex = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	if bg_tex != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = bg_tex
		style_box.texture_margin_left = 44
		style_box.texture_margin_right = 44
		style_box.texture_margin_top = 44
		style_box.texture_margin_bottom = 44
		style_box.content_margin_left = 36
		style_box.content_margin_right = 36
		style_box.content_margin_top = 30
		style_box.content_margin_bottom = 32
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = Color(0.14, 0.11, 0.09, 0.94)
	fallback.border_color = Color(0.6, 0.48, 0.3, 0.95)
	fallback.set_border_width_all(2)
	fallback.set_content_margin_all(24)
	return fallback

func _open_spellbook():
	_close_spellbook()
	var viewport_size = get_viewport_rect().size
	var panel_w = clamp(viewport_size.x * 0.55, 480.0, 760.0)
	var panel_h = clamp(viewport_size.y * 0.65, 360.0, 560.0)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_spellbook_popup = center

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel", _create_dialog_style())
	center.add_child(panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(root_vbox)

	var header = HBoxContainer.new()
	root_vbox.add_child(header)
	var title = Label.new()
	title.text = "Spellbook"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
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
	_spellbook_list_vbox.add_theme_constant_override("separation", 8)
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
		row.add_theme_constant_override("separation", 10)
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
			desc_lbl.add_theme_font_size_override("font_size", 13)
			info_vbox.add_child(desc_lbl)

		var cast_btn = Button.new()
		cast_btn.text = "Cast"
		var chosen = spell_name
		cast_btn.pressed.connect(func():
			_close_spellbook()
			_dungeon.begin_spell_targeting(chosen)
		)
		row.add_child(cast_btn)
