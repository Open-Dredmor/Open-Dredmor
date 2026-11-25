extends CanvasLayer

class_name InventoryDialog

const CHAR_PANEL_TEX = "ui/gameplay/panel_char_bg.png"
const INV_PANEL_TEX = "ui/gameplay/2x_inventory.png"
const SORT_BTN_TEXS = {
	normal = "ui/gameplay/2x_inventory_sort0.png",
	hover = "ui/gameplay/2x_inventory_sort1.png",
	pressed = "ui/gameplay/2x_inventory_sort2.png"
}
const CLOSE_BTN_TEXS = {
	normal = "ui/gameplay/xclose_copper0.png",
	hover = "ui/gameplay/xclose_copper1.png",
	pressed = "ui/gameplay/xclose_copper2.png"
}
const SLOT_FILL_TEX = "ui/gameplay/item_slot_fill32.png"
const SKILLBAR_TEXS = {
	warrior = "ui/gameplay/panel_char_skillbar_warrior.png",
	wizard = "ui/gameplay/panel_char_skillbar_wizard.png",
	rogue = "ui/gameplay/panel_char_skillbar_rogue.png"
}

const RESIST_ICON_OVERRIDES = {
	asphyxiative = "ui/icons/dmg_aphyxiative_resist.png",
	blasting = "ui/icons/dmg_blast_resist.png",
	necromantic = "ui/icons/dmg_necromatic_resist.png"
}

const CHAR_SLOT_RECTS = {
	head = Rect2(185, 40, 32, 32),
	neck = Rect2(226, 51, 32, 32),
	chest = Rect2(185, 73, 32, 32),
	weapon_left = Rect2(126, 89, 32, 32),
	weapon_right = Rect2(243, 89, 32, 32),
	belt = Rect2(185, 110, 32, 32),
	ring_left = Rect2(134, 131, 32, 32),
	hands = Rect2(242, 127, 32, 32),
	legs = Rect2(184, 151, 32, 32),
	ring_right = Rect2(135, 164, 32, 32),
	missile_weapon = Rect2(243, 160, 32, 32),
	feet = Rect2(184, 188, 32, 32)
}

const AMMO_SLOTS = ["bolts", "thrown"]

const SLOT_LABELS = {
	weapon_right = "Main Hand",
	weapon_left = "Off Hand",
	missile_weapon = "Crossbow",
	bolts = "Bolts",
	thrown = "Thrown",
	head = "Head",
	chest = "Chest",
	legs = "Legs",
	feet = "Feet",
	hands = "Hands",
	ring_left = "Left Ring",
	ring_right = "Right Ring",
	neck = "Amulet",
	belt = "Belt"
}

const PRIMARY_STAT_POSITIONS = [
	{ key = "burliness", pos = Vector2(119, 327) },
	{ key = "sagacity", pos = Vector2(119, 345) },
	{ key = "nimbleness", pos = Vector2(119, 363) },
	{ key = "caddishness", pos = Vector2(119, 381) },
	{ key = "savvy", pos = Vector2(119, 399) },
	{ key = "stubbornness", pos = Vector2(119, 417) }
]

const SECONDARY_GRID_KEYS = [
	["melee_power", "armour_absorption", "trap_affinity"],
	["magic_power", "block_chance", "trap_sight_radius"],
	["crit_chance", "dodge_chance", "visual_sight_radius"],
	["haywire_chance", "counter_chance", "smithing_level"],
	["enemy_dodge_reduction", "magic_resistance", "alchemy_level"],
	["sneakiness", "magic_reflect", "tinkering_level"]
]

const SECONDARY_STAT_LABELS = {
	hp_max = "Max HP",
	mp_max = "Max MP",
	melee_power = "Melee",
	magic_power = "Magic",
	crit_chance = "Crit",
	haywire_chance = "Haywire",
	dodge_chance = "Dodge",
	block_chance = "Block",
	counter_chance = "Counter",
	enemy_dodge_reduction = "Accuracy",
	armour_absorption = "Armour",
	magic_resistance = "Mag Res",
	sneakiness = "Sneak",
	health_regen_bonus = "HP Regen",
	mana_regen_bonus = "MP Regen",
	magic_reflect = "Reflect",
	trap_affinity = "Trap Aff",
	trap_sight_radius = "Trap Sight",
	visual_sight_radius = "Sight",
	smithing_level = "Smithing",
	tinkering_level = "Tinkering",
	alchemy_level = "Alchemy",
	resist_bonus = "Resist",
	wandcrafting_level = "Wandcraft"
}

var _player = null
var _drop_inv_cb = Callable()
var _drop_equip_cb = Callable()
var _use_inv_cb = Callable()
var _pickup_cb = Callable()
var _close_cb = Callable()

var _equip_buttons = {}
var _inv_buttons = []
var _char_name_label = null
var _level_label = null
var _melee_label = null
var _ranged_label = null
var _life_label = null
var _mana_label = null
var _hp_regen_label = null
var _mp_regen_label = null
var _primary_labels = {}
var _secondary_labels = {}
var _resist_vbox = null
var _skillbar_containers = {}
var _skillbar_labels = {}
var _selected_info_label = null
var _tooltip_panel = null
var _tooltip_label = null

var _selected_source = null
var _use_btn = null
var _equip_btn = null
var _unequip_btn = null
var _drop_one_btn = null
var _drop_all_btn = null
var _last_click_time_ms = 0
var _last_click_key = ""

func init(player, callbacks = {}):
	_player = player
	_drop_inv_cb = callbacks.get("on_drop_inventory", Callable())
	_drop_equip_cb = callbacks.get("on_drop_equipped", Callable())
	_use_inv_cb = callbacks.get("on_use_inventory", Callable())
	_pickup_cb = callbacks.get("on_pickup", Callable())
	_close_cb = callbacks.get("on_close", Callable())
	layer = 12
	_build_ui()
	_connect_signals()
	refresh()
	return self

func _connect_signals():
	if _player == null:
		return
	if _player.has_signal("inventory_changed") and not _player.inventory_changed.is_connected(refresh):
		_player.inventory_changed.connect(refresh)
	if _player.has_signal("equipment_changed") and not _player.equipment_changed.is_connected(refresh):
		_player.equipment_changed.connect(refresh)
	if _player.has_signal("stats_changed") and not _player.stats_changed.is_connected(_refresh_stats):
		_player.stats_changed.connect(_refresh_stats)

func _get_viewport_size():
	var vp = get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return Vector2(1280, 720)

func _style_label(label, font, font_size, color):
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

func _load_tex(path):
	if path != "" and OD.Load != null and OD.Load.exists(path):
		return OD.Load.image(path)
	return null

func _make_texture_button(paths_dict, min_size):
	var btn = TextureButton.new()
	btn.custom_minimum_size = min_size
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.texture_normal = _load_tex(paths_dict.get("normal", ""))
	btn.texture_hover = _load_tex(paths_dict.get("hover", ""))
	btn.texture_pressed = _load_tex(paths_dict.get("pressed", ""))
	return btn

func _create_highlight_style(border_color, bg_color = Color(0, 0, 0, 0)):
	var box = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	return box

func _build_ui():
	var dialog_assets = OD.Assets.dialog()
	var font = dialog_assets.font if dialog_assets != null else null
	var vp_size = _get_viewport_size()
	var ui_scale = clamp(min((vp_size.x - 40.0) / 960.0, (vp_size.y - 80.0) / 580.0), 0.72, 1.15)

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	center.add_child(root_vbox)

	var windows_hbox = HBoxContainer.new()
	windows_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	windows_hbox.add_theme_constant_override("separation", 16)
	root_vbox.add_child(windows_hbox)

	var char_scale = ui_scale * 1.12
	var char_holder = Control.new()
	char_holder.custom_minimum_size = Vector2(288.0 * char_scale, 512.0 * char_scale)
	windows_hbox.add_child(char_holder)

	var char_panel = Control.new()
	char_panel.custom_minimum_size = Vector2(288, 512)
	char_panel.size = Vector2(288, 512)
	char_panel.scale = Vector2(char_scale, char_scale)
	char_holder.add_child(char_panel)

	var char_bg = TextureRect.new()
	char_bg.texture = _load_tex(CHAR_PANEL_TEX)
	char_bg.size = Vector2(288, 512)
	char_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	char_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_panel.add_child(char_bg)

	_char_name_label = Label.new()
	_char_name_label.position = Vector2(20, 10)
	_char_name_label.size = Vector2(236, 20)
	_char_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(_char_name_label, font, 14, Color(0.95, 0.9, 0.72))
	char_panel.add_child(_char_name_label)

	var char_close = _make_texture_button(CLOSE_BTN_TEXS, Vector2(20, 20))
	char_close.position = Vector2(265, 2)
	char_close.pressed.connect(dismiss)
	char_panel.add_child(char_close)

	var resist_scroll = ScrollContainer.new()
	resist_scroll.position = Vector2(51, 62)
	resist_scroll.size = Vector2(54, 160)
	resist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	char_panel.add_child(resist_scroll)

	_resist_vbox = VBoxContainer.new()
	_resist_vbox.add_theme_constant_override("separation", 2)
	resist_scroll.add_child(_resist_vbox)

	var slot_fill = _load_tex(SLOT_FILL_TEX)
	_equip_buttons.clear()
	for slot_name in CHAR_SLOT_RECTS:
		var rect = CHAR_SLOT_RECTS[slot_name]
		var slot_btn = _make_slot_button(rect.size, null, font)
		slot_btn.position = rect.position
		slot_btn.size = rect.size
		slot_btn.gui_input.connect(func(ev): _on_equip_slot_gui_input(ev, slot_name))
		slot_btn.mouse_entered.connect(func(): _show_tooltip_for_equip(slot_name))
		slot_btn.mouse_exited.connect(_hide_tooltip)
		char_panel.add_child(slot_btn)
		_equip_buttons[slot_name] = slot_btn

	_melee_label = Label.new()
	_melee_label.position = Vector2(112, 227)
	_melee_label.size = Vector2(162, 16)
	_melee_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_melee_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_melee_label, font, 11, Color(0.95, 0.92, 0.84))
	char_panel.add_child(_melee_label)

	_ranged_label = Label.new()
	_ranged_label.position = Vector2(112, 249)
	_ranged_label.size = Vector2(162, 16)
	_ranged_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ranged_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_ranged_label, font, 11, Color(0.95, 0.92, 0.84))
	char_panel.add_child(_ranged_label)

	_level_label = Label.new()
	_level_label.position = Vector2(20, 300)
	_level_label.size = Vector2(36, 18)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_level_label, font, 13, Color(0.96, 0.92, 0.8))
	char_panel.add_child(_level_label)

	var bar_y = { warrior = 273.5, wizard = 290, rogue = 305.5 }
	var num_y = { warrior = 270, wizard = 285, rogue = 300 }
	_skillbar_labels.clear()
	for branch_key in bar_y:
		var num_lbl = Label.new()
		num_lbl.position = Vector2(124, num_y[branch_key])
		num_lbl.size = Vector2(19, 14)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(num_lbl, font, 11, Color(0.96, 0.94, 0.88))
		char_panel.add_child(num_lbl)
		_skillbar_labels[branch_key] = num_lbl

		var bar_hbox = HBoxContainer.new()
		bar_hbox.position = Vector2(146, bar_y[branch_key])
		bar_hbox.size = Vector2(130, 12)
		bar_hbox.add_theme_constant_override("separation", 0)
		char_panel.add_child(bar_hbox)
		_skillbar_containers[branch_key] = bar_hbox

	_primary_labels.clear()
	for p_info in PRIMARY_STAT_POSITIONS:
		var lbl = Label.new()
		lbl.position = p_info.pos
		lbl.size = Vector2(22, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(lbl, font, 12, Color(0.96, 0.94, 0.88))
		char_panel.add_child(lbl)
		_primary_labels[p_info.key] = lbl

	_secondary_labels.clear()
	var col_x = [168, 214, 260]
	for row_idx in range(SECONDARY_GRID_KEYS.size()):
		for col_idx in range(3):
			var sec_key = SECONDARY_GRID_KEYS[row_idx][col_idx]
			var lbl = Label.new()
			lbl.position = Vector2(col_x[col_idx], 327 + row_idx * 18)
			lbl.size = Vector2(22, 16)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_style_label(lbl, font, 12, Color(0.96, 0.94, 0.88))
			char_panel.add_child(lbl)
			_secondary_labels[sec_key] = lbl

	_life_label = Label.new()
	_life_label.position = Vector2(100, 443)
	_life_label.size = Vector2(48, 15)
	_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_life_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_life_label, font, 10, Color(0.98, 0.92, 0.9))
	char_panel.add_child(_life_label)

	_mana_label = Label.new()
	_mana_label.position = Vector2(210, 443)
	_mana_label.size = Vector2(48, 15)
	_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_mana_label, font, 10, Color(0.9, 0.94, 0.98))
	char_panel.add_child(_mana_label)

	_hp_regen_label = Label.new()
	_hp_regen_label.position = Vector2(119, 461)
	_hp_regen_label.size = Vector2(28, 15)
	_hp_regen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_regen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_hp_regen_label, font, 10, Color(0.95, 0.85, 0.85))
	char_panel.add_child(_hp_regen_label)

	_mp_regen_label = Label.new()
	_mp_regen_label.position = Vector2(229, 461)
	_mp_regen_label.size = Vector2(28, 15)
	_mp_regen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mp_regen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_mp_regen_label, font, 10, Color(0.85, 0.9, 0.98))
	char_panel.add_child(_mp_regen_label)

	var inv_holder = Control.new()
	inv_holder.custom_minimum_size = Vector2(608.0 * ui_scale, 552.0 * ui_scale)
	windows_hbox.add_child(inv_holder)

	var inv_panel = Control.new()
	inv_panel.custom_minimum_size = Vector2(608, 552)
	inv_panel.size = Vector2(608, 552)
	inv_panel.scale = Vector2(ui_scale, ui_scale)
	inv_holder.add_child(inv_panel)

	var inv_bg = TextureRect.new()
	inv_bg.texture = _load_tex(INV_PANEL_TEX)
	inv_bg.size = Vector2(608, 552)
	inv_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_panel.add_child(inv_bg)

	var inv_close = _make_texture_button(CLOSE_BTN_TEXS, Vector2(32, 32))
	inv_close.position = Vector2(562, 10)
	inv_close.pressed.connect(dismiss)
	inv_panel.add_child(inv_close)

	var sort_btn = _make_texture_button(SORT_BTN_TEXS, Vector2(84, 30))
	sort_btn.position = Vector2(387, 485)
	sort_btn.size = Vector2(84, 30)
	sort_btn.pressed.connect(func():
		if _player != null:
			_selected_source = null
			_player.sort_inventory()
	)
	inv_panel.add_child(sort_btn)

	_inv_buttons.clear()
	for ii in range(PlayerCharacter.INVENTORY_SIZE):
		var slot_idx = ii
		var row_idx = ii / PlayerCharacter.INVENTORY_COLS
		var col_idx = ii % PlayerCharacter.INVENTORY_COLS
		var inv_btn = _make_slot_button(Vector2(64, 64), null, font)
		inv_btn.position = Vector2(45 + col_idx * 66, 68 + row_idx * 66)
		inv_btn.size = Vector2(64, 64)
		inv_btn.gui_input.connect(func(ev): _on_inv_slot_gui_input(ev, slot_idx))
		inv_btn.mouse_entered.connect(func(): _show_tooltip_for_inv(slot_idx))
		inv_btn.mouse_exited.connect(_hide_tooltip)
		inv_panel.add_child(inv_btn)
		_inv_buttons.append(inv_btn)

	var action_bar = PanelContainer.new()
	var action_style = StyleBoxFlat.new()
	action_style.bg_color = Color(0.14, 0.11, 0.08, 0.92)
	action_style.border_color = Color(0.55, 0.45, 0.28)
	action_style.set_border_width_all(2)
	action_style.set_corner_radius_all(4)
	action_style.content_margin_left = 12
	action_style.content_margin_right = 12
	action_style.content_margin_top = 6
	action_style.content_margin_bottom = 6
	action_bar.add_theme_stylebox_override("panel", action_style)
	root_vbox.add_child(action_bar)

	var action_hbox = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	action_bar.add_child(action_hbox)

	for ammo_slot in AMMO_SLOTS:
		var ammo_lbl = Label.new()
		ammo_lbl.text = SLOT_LABELS.get(ammo_slot, ammo_slot) + ":"
		_style_label(ammo_lbl, font, 14, Color(0.88, 0.82, 0.68))
		action_hbox.add_child(ammo_lbl)
		var ammo_btn = _make_slot_button(Vector2(36, 36), slot_fill, font)
		ammo_btn.gui_input.connect(func(ev): _on_equip_slot_gui_input(ev, ammo_slot))
		ammo_btn.mouse_entered.connect(func(): _show_tooltip_for_equip(ammo_slot))
		ammo_btn.mouse_exited.connect(_hide_tooltip)
		action_hbox.add_child(ammo_btn)
		_equip_buttons[ammo_slot] = ammo_btn

	_selected_info_label = Label.new()
	_selected_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_info_label.text = "Click to select/move, Right-click or Double-click to equip/unequip."
	_style_label(_selected_info_label, font, 16, Color(0.95, 0.9, 0.78))
	action_hbox.add_child(_selected_info_label)

	_use_btn = Button.new()
	_use_btn.text = "Use"
	_use_btn.pressed.connect(_on_use_selected_pressed)
	action_hbox.add_child(_use_btn)

	_equip_btn = Button.new()
	_equip_btn.text = "Equip"
	_equip_btn.pressed.connect(_on_equip_selected_pressed)
	action_hbox.add_child(_equip_btn)

	_unequip_btn = Button.new()
	_unequip_btn.text = "Unequip"
	_unequip_btn.pressed.connect(_on_unequip_selected_pressed)
	action_hbox.add_child(_unequip_btn)

	_drop_one_btn = Button.new()
	_drop_one_btn.text = "Drop 1"
	_drop_one_btn.pressed.connect(func(): _drop_selected(1))
	action_hbox.add_child(_drop_one_btn)

	_drop_all_btn = Button.new()
	_drop_all_btn.text = "Drop Stack"
	_drop_all_btn.pressed.connect(func(): _drop_selected(-1))
	action_hbox.add_child(_drop_all_btn)

	if _pickup_cb.is_valid():
		var pickup_btn = Button.new()
		pickup_btn.text = "Pickup (G)"
		pickup_btn.pressed.connect(func():
			_pickup_cb.call()
			refresh()
		)
		action_hbox.add_child(pickup_btn)

	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 50
	var tip_style = StyleBoxFlat.new()
	tip_style.bg_color = Color(0.11, 0.09, 0.07, 0.96)
	tip_style.border_color = Color(0.75, 0.62, 0.35, 1.0)
	tip_style.set_border_width_all(2)
	tip_style.set_corner_radius_all(6)
	tip_style.content_margin_left = 10
	tip_style.content_margin_right = 10
	tip_style.content_margin_top = 8
	tip_style.content_margin_bottom = 8
	_tooltip_panel.add_theme_stylebox_override("panel", tip_style)
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.custom_minimum_size = Vector2(240, 0)
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(_tooltip_label, font, 14, Color(0.95, 0.92, 0.84))
	_tooltip_panel.add_child(_tooltip_label)

func _make_slot_button(min_size, bg_tex, font):
	var btn = Button.new()
	btn.custom_minimum_size = min_size
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_NONE
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", _create_highlight_style(Color(0.9, 0.78, 0.42, 0.9), Color(1, 1, 1, 0.08)))
	btn.add_theme_stylebox_override("pressed", _create_highlight_style(Color(1.0, 0.9, 0.5, 1.0), Color(1, 1, 1, 0.14)))

	if bg_tex != null:
		var slot_bg = TextureRect.new()
		slot_bg.name = "SlotBg"
		slot_bg.texture = bg_tex
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_bg.stretch_mode = TextureRect.STRETCH_SCALE
		slot_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(slot_bg)

	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 2
	icon_rect.offset_top = 2
	icon_rect.offset_right = -2
	icon_rect.offset_bottom = -2
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_rect)

	var count_label = Label.new()
	count_label.name = "Count"
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -28
	count_label.offset_top = -18
	count_label.offset_right = -3
	count_label.offset_bottom = -1
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(count_label, font, 12, Color(1.0, 0.96, 0.72))
	count_label.add_theme_constant_override("outline_size", 2)
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	btn.add_child(count_label)
	return btn

func _process(_delta):
	if _tooltip_panel != null and _tooltip_panel.visible:
		var vp_size = _get_viewport_size()
		var mouse_pos = get_viewport().get_mouse_position()
		var tip_size = _tooltip_panel.size
		var target_pos = mouse_pos + Vector2(16, 16)
		if target_pos.x + tip_size.x > vp_size.x - 8:
			target_pos.x = max(8.0, mouse_pos.x - tip_size.x - 12)
		if target_pos.y + tip_size.y > vp_size.y - 8:
			target_pos.y = max(8.0, mouse_pos.y - tip_size.y - 12)
		_tooltip_panel.position = target_pos

func _unhandled_input(ev):
	if ev is InputEventKey and ev.is_pressed() and not ev.echo:
		if ev.keycode == KEY_ESCAPE or ev.keycode == KEY_I:
			get_viewport().set_input_as_handled()
			dismiss()

func dismiss():
	if _close_cb.is_valid():
		_close_cb.call()
	queue_free()

func _is_double_click(click_key):
	var now_ms = Time.get_ticks_msec()
	var is_double = (_last_click_key == click_key and (now_ms - _last_click_time_ms) <= 320)
	_last_click_time_ms = now_ms
	_last_click_key = click_key
	return is_double

func _on_inv_slot_gui_input(ev, slot_idx):
	if _player == null or not (ev is InputEventMouseButton) or not ev.pressed:
		return
	var item = _player.inventory[slot_idx]
	if ev.button_index == MOUSE_BUTTON_RIGHT:
		if item != null:
			if _player.is_item_usable(item):
				_use_inventory_slot(slot_idx)
			else:
				_player.equip_from_inventory(slot_idx)
				_selected_source = null
				refresh()
		return
	if ev.button_index != MOUSE_BUTTON_LEFT:
		return
	if item != null and _is_double_click("inv_" + str(slot_idx)):
		if _player.is_item_usable(item):
			_use_inventory_slot(slot_idx)
		else:
			_player.equip_from_inventory(slot_idx)
			_selected_source = null
			refresh()
		return
	if _selected_source == null:
		if item != null:
			_selected_source = { kind = "inv", index = slot_idx }
		refresh()
		return
	if _selected_source.kind == "inv":
		if _selected_source.index == slot_idx:
			_selected_source = null
		else:
			_player.move_or_swap_inventory_slot(_selected_source.index, slot_idx)
			_selected_source = null
		refresh()
		return
	if _selected_source.kind == "equip":
		_player.unequip_slot(_selected_source.slot, slot_idx)
		_selected_source = null
		refresh()

func _on_equip_slot_gui_input(ev, slot_name):
	if _player == null or not (ev is InputEventMouseButton) or not ev.pressed:
		return
	var equipped = _player.get_equipped_item(slot_name)
	if ev.button_index == MOUSE_BUTTON_RIGHT:
		if equipped != null:
			_player.unequip_slot(slot_name)
			_selected_source = null
			refresh()
		return
	if ev.button_index != MOUSE_BUTTON_LEFT:
		return
	if equipped != null and _is_double_click("equip_" + slot_name):
		_player.unequip_slot(slot_name)
		_selected_source = null
		refresh()
		return
	if _selected_source == null:
		if equipped != null:
			_selected_source = { kind = "equip", slot = slot_name }
		refresh()
		return
	if _selected_source.kind == "inv":
		if _player.equip_from_inventory(_selected_source.index, slot_name):
			_selected_source = null
		elif equipped != null:
			_selected_source = { kind = "equip", slot = slot_name }
		refresh()
		return
	if _selected_source.kind == "equip":
		if _selected_source.slot == slot_name:
			_selected_source = null
		else:
			var from_slot = _selected_source.slot
			var from_item = _player.get_equipped_item(from_slot)
			if from_item != null and _player.can_equip_in_slot(from_item, slot_name):
				var target_item = _player.get_equipped_item(slot_name)
				if target_item == null or _player.can_equip_in_slot(target_item, from_slot):
					_player.equipment[slot_name] = from_item
					_player.equipment[from_slot] = target_item
					_player.recalculate_stats()
					_player.equipment_changed.emit()
			_selected_source = null
		refresh()

func _use_inventory_slot(slot_idx):
	if _player == null:
		return
	if _use_inv_cb.is_valid():
		_use_inv_cb.call(slot_idx)
	else:
		_player.use_consumable_at(slot_idx)
	_selected_source = null
	if is_instance_valid(self):
		refresh()

func _on_use_selected_pressed():
	if _player == null or _selected_source == null or _selected_source.kind != "inv":
		return
	_use_inventory_slot(_selected_source.index)

func _on_equip_selected_pressed():
	if _player == null or _selected_source == null or _selected_source.kind != "inv":
		return
	_player.equip_from_inventory(_selected_source.index)
	_selected_source = null
	refresh()

func _on_unequip_selected_pressed():
	if _player == null or _selected_source == null or _selected_source.kind != "equip":
		return
	_player.unequip_slot(_selected_source.slot)
	_selected_source = null
	refresh()

func _drop_selected(count):
	if _player == null or _selected_source == null:
		return
	if _selected_source.kind == "inv":
		var idx = _selected_source.index
		if _drop_inv_cb.is_valid():
			_drop_inv_cb.call(idx, count)
		else:
			_player.remove_item_at(idx, count)
		if _player.inventory[idx] == null:
			_selected_source = null
	elif _selected_source.kind == "equip":
		var slot_name = _selected_source.slot
		if _drop_equip_cb.is_valid():
			_drop_equip_cb.call(slot_name)
		else:
			_player.equipment[slot_name] = null
			_player.recalculate_stats()
			_player.equipment_changed.emit()
		_selected_source = null
	refresh()

func _get_selected_item():
	if _player == null or _selected_source == null:
		return null
	if _selected_source.kind == "inv":
		return _player.inventory[_selected_source.index]
	if _selected_source.kind == "equip":
		return _player.get_equipped_item(_selected_source.slot)
	return null

func refresh():
	if _player == null:
		return
	var selected_item = _get_selected_item()
	var valid_slots = _player.get_valid_slots_for_item(selected_item) if selected_item != null and _selected_source != null and _selected_source.kind == "inv" else []

	for slot_name in _equip_buttons:
		var btn = _equip_buttons.get(slot_name, null)
		if btn == null:
			continue
		var item = _player.get_equipped_item(slot_name)
		var is_selected = (_selected_source != null and _selected_source.kind == "equip" and _selected_source.slot == slot_name)
		var is_valid_target = (slot_name in valid_slots)
		_apply_slot_visuals(btn, item, is_selected, is_valid_target)

	for ii in range(PlayerCharacter.INVENTORY_SIZE):
		var btn = _inv_buttons[ii]
		var item = _player.inventory[ii]
		var is_selected = (_selected_source != null and _selected_source.kind == "inv" and _selected_source.index == ii)
		_apply_slot_visuals(btn, item, is_selected, false)

	_refresh_selected_controls(selected_item)
	_refresh_stats()

func _apply_slot_visuals(btn, item, is_selected, is_valid_target):
	var icon_rect = btn.get_node("Icon")
	var count_label = btn.get_node("Count")
	if is_selected:
		btn.add_theme_stylebox_override("normal", _create_highlight_style(Color(1.0, 0.85, 0.25), Color(0.9, 0.7, 0.2, 0.2)))
	elif is_valid_target:
		btn.add_theme_stylebox_override("normal", _create_highlight_style(Color(0.45, 0.95, 0.4), Color(0.3, 0.8, 0.3, 0.16)))
	else:
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())

	if item == null:
		icon_rect.texture = null
		count_label.text = ""
	else:
		icon_rect.texture = _load_tex(str(item.get("icon", "")))
		if str(item.get("category", "")) == "wand":
			count_label.text = str(int(item.get("charges", 0)))
		else:
			var cnt = int(item.get("count", 1))
			count_label.text = str(cnt) if cnt > 1 else ""

func _refresh_selected_controls(selected_item):
	if selected_item == null:
		_selected_info_label.text = "Click to select/move, Right-click or Double-click to use/equip."
		_use_btn.disabled = true
		_equip_btn.disabled = true
		_unequip_btn.disabled = true
		_drop_one_btn.disabled = true
		_drop_all_btn.disabled = true
		return
	var cnt = int(selected_item.get("count", 1))
	var cnt_str = " (x" + str(cnt) + ")" if cnt > 1 else ""
	_selected_info_label.text = str(selected_item.get("name", "Item")) + cnt_str
	var is_inv = _selected_source != null and _selected_source.kind == "inv"
	_use_btn.disabled = not (is_inv and _player.is_item_usable(selected_item))
	var can_equip = is_inv and not _player.get_valid_slots_for_item(selected_item).is_empty()
	_equip_btn.disabled = not can_equip
	_unequip_btn.disabled = not (_selected_source != null and _selected_source.kind == "equip")
	_drop_one_btn.disabled = false
	_drop_all_btn.disabled = cnt <= 1

func _compute_melee_attack_total():
	var total = _player.get_secondary_stat("melee_power")
	for slot_name in ["weapon_right", "weapon_left"]:
		var item = _player.get_equipped_item(slot_name)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var w_dmg = item.get("weapon_damage", {})
			for dmg_type in w_dmg:
				total += int(w_dmg[dmg_type])
	for dmg_type in PlayerCharacter.DAMAGE_TYPES:
		total += _player.get_damage_bonus(dmg_type)
	return total

func _compute_ranged_attack_total():
	var total = 0
	for slot_name in ["missile_weapon", "bolts"]:
		var item = _player.get_equipped_item(slot_name)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var w_dmg = item.get("weapon_damage", {})
			for dmg_type in w_dmg:
				total += int(w_dmg[dmg_type])
	return total

func _refresh_stats():
	if _player == null:
		return
	_char_name_label.text = _player.character_name if _player.character_name != "" else "Hero"
	_level_label.text = str(_player.level)
	var melee_val = _compute_melee_attack_total()
	var ranged_val = _compute_ranged_attack_total()
	_melee_label.text = ("+" if melee_val >= 0 else "") + str(melee_val)
	_ranged_label.text = ("+" if ranged_val >= 0 else "") + str(ranged_val) if ranged_val != 0 else ""

	_life_label.text = "%d/%d" % [_player.hp, _player.max_hp]
	_mana_label.text = "%d/%d" % [_player.mp, _player.max_mp]
	_hp_regen_label.text = str(_player.get_secondary_stat("health_regen_bonus"))
	_mp_regen_label.text = str(_player.get_secondary_stat("mana_regen_bonus"))

	for stat_key in _primary_labels:
		_primary_labels[stat_key].text = str(_player.get_primary_stat(stat_key))
	for sec_key in _secondary_labels:
		_secondary_labels[sec_key].text = str(_player.get_secondary_stat(sec_key))

	var branch_levels = {
		warrior = _player.warrior_level,
		wizard = _player.wizard_level,
		rogue = _player.rogue_level
	}
	for branch_key in _skillbar_containers:
		if _skillbar_labels.has(branch_key):
			_skillbar_labels[branch_key].text = str(int(branch_levels.get(branch_key, 0)))
		var container = _skillbar_containers[branch_key]
		for child in container.get_children():
			child.queue_free()
		var bar_tex = _load_tex(SKILLBAR_TEXS.get(branch_key, ""))
		var pip_count = clamp(int(branch_levels.get(branch_key, 0)), 0, 28)
		for ii in range(pip_count):
			var pip = TextureRect.new()
			pip.texture = bar_tex
			pip.custom_minimum_size = Vector2(4, 12)
			pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pip.stretch_mode = TextureRect.STRETCH_SCALE
			pip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(pip)

	for child in _resist_vbox.get_children():
		child.queue_free()
	var dialog_assets = OD.Assets.dialog()
	var font = dialog_assets.font if dialog_assets != null else null
	for dmg_type in PlayerCharacter.DAMAGE_TYPES:
		var res_val = _player.get_resistance(dmg_type)
		if res_val == 0:
			continue
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_resist_vbox.add_child(row)
		var icon_path = RESIST_ICON_OVERRIDES.get(dmg_type, "ui/icons/dmg_" + dmg_type + "_resist.png")
		var icon_tex = _load_tex(icon_path)
		if icon_tex != null:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.custom_minimum_size = Vector2(14, 14)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(icon_rect)
		var res_lbl = Label.new()
		res_lbl.text = str(res_val)
		var res_color = Color(0.45, 0.9, 0.45) if res_val > 0 else Color(0.95, 0.35, 0.35)
		_style_label(res_lbl, font, 12, res_color)
		row.add_child(res_lbl)

func _show_tooltip_for_inv(slot_idx):
	if _player == null:
		return
	var item = _player.inventory[slot_idx]
	_show_tooltip(item)

func _show_tooltip_for_equip(slot_name):
	if _player == null:
		return
	var item = _player.get_equipped_item(slot_name)
	if item == null:
		_tooltip_label.text = SLOT_LABELS.get(slot_name, slot_name) + " (Empty)"
		_tooltip_panel.visible = true
		return
	_show_tooltip(item)

func _show_tooltip(item):
	if item == null:
		_hide_tooltip()
		return
	var lines = []
	var cnt = int(item.get("count", 1))
	var title = str(item.get("name", "Item")) + (" x" + str(cnt) if cnt > 1 else "")
	lines.append(title)
	var cat_str = str(item.get("category", "misc")).capitalize()
	var slot_str = str(item.get("slot", ""))
	if slot_str != "" and slot_str != cat_str.to_lower():
		cat_str += " (" + slot_str + ")"
	lines.append("Level %d  |  %s  |  Sell: %d zm" % [int(item.get("level", 1)), cat_str, int(item.get("sell_price", 0))])

	var cat = str(item.get("category", "misc"))
	if cat == "food":
		if bool(item.get("is_booze", false)) or int(item.get("food_mp", 0)) > 0:
			var total_mp = max(1, int(item.get("food_mp", 6)))
			var mp_per_turn = max(1, int(ceil(float(total_mp) / 6.0)))
			lines.append("Booze: +" + str(mp_per_turn) + " MP/turn (6 turns) & Tipsy")
		else:
			lines.append("Food: Restores " + str(int(item.get("food_hp", 1))) + " HP over time")
		if str(item.get("food_effect", "")) != "":
			lines.append("Effect: " + str(item.get("food_effect", "")))
	elif cat == "potion":
		lines.append("Potion: Casts " + str(item.get("potion_spell", "")))
	elif cat == "mushroom":
		lines.append("Mushroom: Casts " + str(item.get("casts_spell", "")))
	elif cat == "wand":
		lines.append("Wand: Casts " + str(item.get("wand_spell", "")))
		lines.append("Charges: " + str(int(item.get("charges", 0))) + " / " + str(int(item.get("max_charges", 0))))

	var w_dmg = item.get("weapon_damage", {})
	if typeof(w_dmg) == TYPE_DICTIONARY and not w_dmg.is_empty():
		var w_parts = []
		for dmg_type in w_dmg:
			w_parts.append(str(dmg_type).capitalize() + ": " + str(w_dmg[dmg_type]))
		lines.append("Weapon: " + ", ".join(w_parts))

	for p_buff in item.get("primary_buffs", []):
		var pid = int(p_buff.get("id", -1))
		if pid >= 0 and pid < PlayerCharacter.PRIMARY_STAT_KEYS.size():
			var amt = int(p_buff.get("amount", 0))
			var sign_str = "+" if amt >= 0 else ""
			lines.append(sign_str + str(amt) + " " + PlayerCharacter.PRIMARY_STAT_KEYS[pid].capitalize())

	for s_buff in item.get("secondary_buffs", []):
		var sid = int(s_buff.get("id", -1))
		var sec_key = PlayerCharacter.SECONDARY_STAT_BY_ID.get(sid, "")
		if sec_key != "":
			var amt = int(s_buff.get("amount", 0))
			var sign_str = "+" if amt >= 0 else ""
			lines.append(sign_str + str(amt) + " " + SECONDARY_STAT_LABELS.get(sec_key, sec_key))

	var res_map = item.get("resist_buffs", {})
	if typeof(res_map) == TYPE_DICTIONARY and not res_map.is_empty():
		for dmg_type in res_map:
			var amt = int(res_map[dmg_type])
			var sign_str = "+" if amt >= 0 else ""
			lines.append(sign_str + str(amt) + " " + str(dmg_type).capitalize() + " Resist")

	var dmg_map = item.get("damage_buffs", {})
	if typeof(dmg_map) == TYPE_DICTIONARY and not dmg_map.is_empty():
		for dmg_type in dmg_map:
			var amt = int(dmg_map[dmg_type])
			var sign_str = "+" if amt >= 0 else ""
			lines.append(sign_str + str(amt) + " " + str(dmg_type).capitalize() + " Damage")

	var desc = str(item.get("description", ""))
	if desc != "":
		lines.append("")
		lines.append(desc)

	_tooltip_label.text = "\n".join(lines)
	_tooltip_panel.visible = true

func _hide_tooltip():
	if _tooltip_panel != null:
		_tooltip_panel.visible = false
