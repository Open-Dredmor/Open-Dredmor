extends Control

class_name CoreHud

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const SpellEngineScript = preload("res://script/instance/combat/spell_engine.gd")
const MinimapOverlayScript = preload("res://script/instance/ui/minimap.gd")
const SkillTreeDialogScript = preload("res://script/instance/ui/skill_tree_dialog.gd")
const QuestDialogScript = preload("res://script/instance/ui/quest_dialog.gd")
const PauseDialogScript = preload("res://script/instance/ui/pause_dialog.gd")

const BAR_WIDTH = 1024.0
const BAR_HEIGHT = 120.0
const HOTBAR_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const MAX_LOG_LINES = 7

const MENU_TABS = [
	{ id = "menu", prefix = "ui/gameplay/game_button_menu", tip = "Menu (M / Esc)" },
	{ id = "character", prefix = "ui/gameplay/game_button_character", tip = "Character Sheet (C)" },
	{ id = "inventory", prefix = "ui/gameplay/game_button_inventory", tip = "Inventory (I)" },
	{ id = "skills", prefix = "ui/gameplay/game_button_skills", tip = "Skills & Spells (K)" },
	{ id = "quests", prefix = "ui/gameplay/game_button_quests", tip = "Quests (Q)" },
	{ id = "crafting", prefix = "ui/gameplay/game_button_crafting", tip = "Crafting (R)" }
]

var _dungeon = null
var _callbacks = {}

var _minimap = null
var _room_label = null
var _log_vertical_box = null
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
var _skill_points_badge = null
var _skill_dialog = null
var _quest_dialog = null
var _pause_dialog = null

func _ready():
	_update_bar_scale()
	_update_top_right_layout()
	var viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_update_bar_scale)
		viewport.size_changed.connect(_update_top_right_layout)

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

func _styled_label(font_size, font_color, outline_size = 2):
	var label = Label.new()
	UiHelpers.style_label(label, font_size, font_color, null, outline_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _load_tex(path):
	return UiHelpers.load_texture(path)

func _build_top_left_log():
	_log_scroll = ScrollContainer.new()
	_log_scroll.position = Vector2(14, 10)
	_log_scroll.custom_minimum_size = Vector2(540, 140)
	_log_scroll.size = Vector2(540, 140)
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_log_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_log_scroll)

	_log_vertical_box = VBoxContainer.new()
	_log_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_vertical_box.add_theme_constant_override("separation", 2)
	_log_vertical_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_scroll.add_child(_log_vertical_box)

func toggle_log_history():
	_log_expanded = not _log_expanded
	if _log_scroll == null or not is_instance_valid(_log_scroll):
		return
	if _log_expanded:
		_log_scroll.custom_minimum_size = Vector2(560, 320)
		_log_scroll.size = Vector2(560, 320)
		_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_log_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		var background = StyleBoxFlat.new()
		background.bg_color = Color(0.06, 0.05, 0.04, 0.84)
		background.border_color = Color(0.55, 0.44, 0.28, 0.9)
		background.set_border_width_all(1)
		background.set_content_margin_all(8)
		_log_scroll.add_theme_stylebox_override("panel", background)
	else:
		_log_scroll.custom_minimum_size = Vector2(540, 140)
		_log_scroll.size = Vector2(540, 140)
		_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_log_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_log_scroll.remove_theme_stylebox_override("panel")
	_rebuild_log_lines()

func _rebuild_log_lines():
	if _log_vertical_box == null or not is_instance_valid(_log_vertical_box):
		return
	for child in _log_vertical_box.get_children():
		_log_vertical_box.remove_child(child)
		child.queue_free()
	if OD.EventLog == null or not OD.EventLog.has_method("get_history"):
		return
	var history = OD.EventLog.get_history()
	var start_index = 0 if _log_expanded else max(0, history.size() - MAX_LOG_LINES)
	for ii in range(start_index, history.size()):
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
	var viewport_size = get_viewport_rect().size
	var margin_right = 6.0
	var margin_top = 4.0
	if _minimap != null and is_instance_valid(_minimap):
		var frame_size = _minimap.get_frame_size()
		_minimap.position = Vector2(viewport_size.x - frame_size.x - margin_right, margin_top)
		if _room_label != null and is_instance_valid(_room_label):
			var label_w = max(340.0, frame_size.x)
			_room_label.position = Vector2(viewport_size.x - label_w - margin_right, margin_top + frame_size.y + 4.0)
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

	var background = TextureRect.new()
	background.texture = _load_tex("ui/gameplay/bottombar_bg.png")
	background.position = Vector2.ZERO
	background.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	background.stretch_mode = TextureRect.STRETCH_KEEP
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar_root.add_child(background)

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
	var viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0:
		return
	var scale_factor = min(1.0, viewport_size.x / BAR_WIDTH)
	_bar_root.scale = Vector2(scale_factor, scale_factor)
	var scaled_w = BAR_WIDTH * scale_factor
	var scaled_h = BAR_HEIGHT * scale_factor
	_bar_root.position = Vector2((viewport_size.x - scaled_w) * 0.5, BAR_HEIGHT - scaled_h)

func _build_menu_tabs():
	var tab_w = 56.0
	var tab_h = 24.0
	var start_x = 60.0
	var position_y = 26.0
	for ii in range(MENU_TABS.size()):
		var tab = MENU_TABS[ii]
		var button = TextureButton.new()
		button.position = Vector2(start_x + ii * tab_w, position_y)
		button.size = Vector2(tab_w, tab_h)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.texture_normal = _load_tex(tab.prefix + "0.png")
		button.texture_hover = _load_tex(tab.prefix + "1.png")
		button.texture_pressed = _load_tex(tab.prefix + "2.png")
		button.tooltip_text = tab.tip
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var tab_id = tab.id
		button.pressed.connect(func(): _on_menu_tab_pressed(tab_id))
		_bar_root.add_child(button)
		if tab_id == "skills":
			_skill_points_badge = _styled_label(11, Color(1.0, 0.88, 0.25), 2)
			_skill_points_badge.position = Vector2(tab_w - 18, -4)
			_skill_points_badge.size = Vector2(20, 14)
			_skill_points_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_skill_points_badge.visible = false
			button.add_child(_skill_points_badge)

func _build_zorkmid_box():
	_zorkmid_label = _styled_label(16, Color(0.95, 0.92, 0.85), 2)
	_zorkmid_label.position = Vector2(62, 62)
	_zorkmid_label.size = Vector2(62, 26)
	_zorkmid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zorkmid_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_root.add_child(_zorkmid_label)

func _build_digest_button():
	var button = TextureButton.new()
	button.position = Vector2(0, 95)
	button.size = Vector2(60, 24)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.texture_normal = _load_tex("ui/gameplay/digest0.png")
	button.texture_hover = _load_tex("ui/gameplay/digest1.png")
	button.tooltip_text = "Wait 1 Turn (Space)"
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func():
		if _callbacks.has("on_wait") and _callbacks.on_wait.is_valid():
			_callbacks.on_wait.call()
	)
	_bar_root.add_child(button)

func _build_belt_slots():
	_belt_buttons.clear()
	for ii in range(PlayerCharacter.BELT_SIZE):
		var slot_index = ii
		var key_text = "SHIFT " + str(ii + 1) if ii == 0 else str(ii + 1)
		var button = _create_slot_button(Vector2(134 + ii * 36, 58), Vector2(32, 32), key_text)
		button.pressed.connect(func(): _activate_belt_slot(slot_index))
		_bar_root.add_child(button)
		_belt_buttons.append(button)

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
		var slot_index = ii
		var key_label = str((ii + 1) % 10)
		var button = _create_slot_button(Vector2(612 + ii * 36, 44), Vector2(34, 34), key_label)
		button.pressed.connect(func(): _activate_spell_slot(slot_index))
		_bar_root.add_child(button)
		_spell_buttons.append(button)

func _create_slot_button(pos, slot_size, key_text):
	var button = Button.new()
	button.position = pos
	button.size = slot_size
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var empty_style = StyleBoxEmpty.new()
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 0.9, 0.55, 0.16)
	hover_style.border_color = Color(0.9, 0.78, 0.42, 0.65)
	hover_style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)

	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.position = Vector2(1, 1)
	icon_rect.size = slot_size - Vector2(2, 2)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_rect)

	var key_label = _styled_label(9, Color(0.92, 0.88, 0.72), 2)
	key_label.name = "KeyLabel"
	key_label.text = key_text
	key_label.position = Vector2(2, 0)
	button.add_child(key_label)

	var info_label = _styled_label(10, Color(1.0, 1.0, 1.0), 2)
	info_label.name = "InfoLabel"
	info_label.position = Vector2(1, slot_size.y - 13)
	info_label.size = Vector2(slot_size.x - 2, 12)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.add_child(info_label)

	return button

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
		player.leveled_up.connect(func(_l, _sp):
			refresh_vitals()
			refresh_skill_badge()
		)
		player.zorkmids_changed.connect(func(_z): refresh_zorkmids())
		player.stats_changed.connect(refresh_vitals)
		player.skills_changed.connect(func():
			refresh_spell_hotbar()
			refresh_skill_badge()
		)
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
	refresh_skill_badge()

func refresh_skill_badge():
	if _skill_points_badge == null or not is_instance_valid(_skill_points_badge):
		return
	if _dungeon == null or not is_instance_valid(_dungeon):
		_skill_points_badge.visible = false
		return
	var player = _dungeon.get_player()
	if player == null or int(player.skill_points) <= 0:
		_skill_points_badge.visible = false
		return
	_skill_points_badge.text = "+" + str(int(player.skill_points))
	_skill_points_badge.visible = true

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
		var button = _belt_buttons[ii]
		var icon_rect = button.get_node("Icon")
		var info_label = button.get_node("InfoLabel")
		var item_name = items[ii]
		if item_name == "":
			icon_rect.texture = null
			info_label.text = ""
			button.tooltip_text = "Belt Slot " + str(ii + 1) + " (Shift+" + str(ii + 1) + ")"
			button.disabled = true
			continue
		var inventory_index = player.find_inventory_index_by_name(item_name)
		var item = player.inventory[inventory_index] if inventory_index >= 0 else null
		var count = player.get_inventory_count_by_name(item_name)
		icon_rect.texture = _load_tex(str(item.get("icon", ""))) if item != null else null
		info_label.text = str(count) if count > 1 else ""
		button.tooltip_text = item_name + " x" + str(count) + " (Shift+" + str(ii + 1) + ")"
		button.disabled = inventory_index == -1

func refresh_spell_hotbar():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var slots = player.get_hotbar_spells()
	for ii in range(min(_spell_buttons.size(), slots.size())):
		var button = _spell_buttons[ii]
		var icon_rect = button.get_node("Icon")
		var info_label = button.get_node("InfoLabel")
		var spell_name = slots[ii]
		var key_label = str((ii + 1) % 10)
		if spell_name == "":
			icon_rect.texture = null
			info_label.text = ""
			button.tooltip_text = "Empty Spell Slot " + key_label
			button.disabled = true
			continue
		var spell_definition = OD.Database.get_spell(spell_name) if OD.Database != null else null
		var cost = SpellEngineScript.compute_mana_cost(player, spell_definition)
		var cooldown = player.get_spell_cooldown(spell_name)
		var icon_path = str(spell_definition.icon) if spell_definition != null and spell_definition.get("icon") != null else ""
		icon_rect.texture = _load_tex(icon_path)
		if cooldown > 0:
			info_label.text = "CD " + str(cooldown)
			info_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		elif cost > 0:
			info_label.text = str(cost)
			info_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
		else:
			info_label.text = ""
		button.tooltip_text = spell_name + " (MP: " + str(cost) + ", CD: " + str(cooldown) + ")"
		button.disabled = cooldown > 0 or int(player.mp) < cost

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
	_log_vertical_box.add_child(line)

func _append_log_line(message):
	if _log_vertical_box == null or not is_instance_valid(_log_vertical_box):
		return
	_add_log_label(message)
	if not _log_expanded:
		while _log_vertical_box.get_child_count() > MAX_LOG_LINES:
			var oldest = _log_vertical_box.get_child(0)
			_log_vertical_box.remove_child(oldest)
			oldest.queue_free()
	_scroll_log_to_bottom()

func _activate_belt_slot(slot_index):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var item_name = player.get_belt_item(slot_index)
	if item_name == "":
		return
	var inventory_index = player.find_inventory_index_by_name(item_name)
	if inventory_index == -1:
		return
	var result = _dungeon.begin_use_inventory_item(inventory_index)
	if typeof(result) == TYPE_DICTIONARY and result.get("open_crafting", false):
		_dungeon.open_crafting_dialog(str(result.get("tool_tag", "")))

func _activate_spell_slot(slot_index):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	var spell_name = player.get_hotbar_spell(slot_index)
	if spell_name == "":
		return
	_dungeon.begin_spell_targeting(spell_name)

func _on_menu_tab_pressed(tab_id):
	match tab_id:
		"menu":
			toggle_pause_menu()
		"character":
			if _callbacks.has("on_character") and _callbacks.on_character.is_valid():
				_callbacks.on_character.call()
			elif _callbacks.has("on_inventory") and _callbacks.on_inventory.is_valid():
				_callbacks.on_inventory.call()
		"inventory":
			if _callbacks.has("on_inventory") and _callbacks.on_inventory.is_valid():
				_callbacks.on_inventory.call()
		"skills":
			toggle_skill_tree()
		"crafting":
			if _callbacks.has("on_crafting") and _callbacks.on_crafting.is_valid():
				_callbacks.on_crafting.call()
			elif _dungeon != null and is_instance_valid(_dungeon):
				_dungeon.open_crafting_dialog()
		"quests":
			toggle_quest_log()

func is_modal_open():
	return is_instance_valid(_pause_dialog)

func is_spellbook_open():
	return is_instance_valid(_skill_dialog)

func close_all_modals():
	_close_pause_menu()
	_close_skill_tree()
	_close_quest_log()

func _notify_before_open_modal():
	close_all_modals()
	if _callbacks.has("on_before_open_modal") and _callbacks.on_before_open_modal.is_valid():
		_callbacks.on_before_open_modal.call()

func handle_key_input(event):
	if not (event is InputEventKey) or not event.is_pressed() or event.echo:
		return false
	if is_modal_open():
		return false
	if _log_expanded and event.keycode == KEY_ESCAPE:
		toggle_log_history()
		return true
	if event.keycode == KEY_L:
		toggle_log_history()
		return true
	if event.keycode == KEY_M:
		toggle_pause_menu()
		return true
	if event.keycode == KEY_K:
		toggle_skill_tree()
		return true
	if event.keycode == KEY_Q:
		toggle_quest_log()
		return true
	if event.keycode == KEY_TAB:
		if _minimap != null and is_instance_valid(_minimap):
			_minimap.cycle_zoom(event.shift_pressed)
		return true
	if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
		if _minimap != null and is_instance_valid(_minimap):
			_minimap.zoom_in()
		return true
	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		if _minimap != null and is_instance_valid(_minimap):
			_minimap.zoom_out()
		return true
	for ii in range(HOTBAR_KEYS.size()):
		if event.keycode == HOTBAR_KEYS[ii]:
			if event.shift_pressed and ii < PlayerCharacter.BELT_SIZE:
				_activate_belt_slot(ii)
			else:
				_activate_spell_slot(ii)
			return true
	return false

func toggle_pause_menu():
	if is_instance_valid(_pause_dialog):
		_close_pause_menu()
		return
	_pause_dialog = PauseDialogScript.new().init({
		on_save = func():
			if _dungeon != null and is_instance_valid(_dungeon) and _dungeon.has_method("save_game"):
				return _dungeon.save_game()
			return { ok = false },
		on_save_and_quit = func():
			if _dungeon != null and is_instance_valid(_dungeon) and _dungeon.has_method("save_game"):
				_dungeon.save_game()
			_close_pause_menu()
			OD.Scenes.goto(OD.Scenes.MAIN_MENU),
		on_close = func(): _pause_dialog = null
	})
	add_child(_pause_dialog)

func _close_pause_menu():
	if is_instance_valid(_pause_dialog):
		_pause_dialog.queue_free()
		_pause_dialog = null

func toggle_skill_tree(initial_tab = "skills"):
	if is_instance_valid(_skill_dialog):
		_close_skill_tree()
		return
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	_skill_dialog = SkillTreeDialogScript.new().init(player, {
		on_cast_spell = func(spell_name):
			_skill_dialog = null
			_dungeon.begin_spell_targeting(spell_name),
		on_close = func(): _skill_dialog = null
	}, initial_tab)
	add_child(_skill_dialog)

func _close_skill_tree():
	if is_instance_valid(_skill_dialog):
		_skill_dialog.queue_free()
		_skill_dialog = null

func toggle_spellbook():
	toggle_skill_tree("spells")

func toggle_quest_log():
	if is_instance_valid(_quest_dialog):
		_close_quest_log()
		return
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	_quest_dialog = QuestDialogScript.new().init(player, {
		on_close = func(): _quest_dialog = null
	})
	add_child(_quest_dialog)

func _close_quest_log():
	if is_instance_valid(_quest_dialog):
		_quest_dialog.queue_free()
		_quest_dialog = null
