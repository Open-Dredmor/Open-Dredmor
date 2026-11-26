extends CanvasLayer

class_name InventoryDialog

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const FloatingWindowScript = preload("res://script/instance/ui/floating_window.gd")
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

const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)
const UI_SCALE_REF_SIZE = Vector2(960.0, 580.0)
const UI_SCALE_MARGIN = Vector2(40.0, 80.0)
const UI_SCALE_MIN = 0.72
const UI_SCALE_MAX = 1.15
const CHAR_PANEL_EXTRA_SCALE = 1.12

const ROOT_VBOX_SEPARATION = 10
const WINDOWS_HBOX_SEPARATION = 16

const CHAR_PANEL_SIZE = Vector2(288, 512)
const CHAR_NAME_RECT = Rect2(20, 10, 236, 20)
const CHAR_NAME_FONT_SIZE = 14
const CHAR_CLOSE_BTN_RECT = Rect2(265, 2, 20, 20)
const RESIST_SCROLL_RECT = Rect2(51, 62, 54, 160)
const RESIST_VBOX_SEPARATION = 2
const RESIST_ROW_SEPARATION = 4
const RESIST_ICON_SIZE = Vector2(14, 14)
const RESIST_FONT_SIZE = 12

const MELEE_LABEL_RECT = Rect2(112, 227, 162, 16)
const RANGED_LABEL_RECT = Rect2(112, 249, 162, 16)
const COMBAT_STAT_FONT_SIZE = 11
const LEVEL_LABEL_RECT = Rect2(20, 300, 36, 18)
const LEVEL_FONT_SIZE = 13

const SKILLBAR_Y = { warrior = 273.5, wizard = 290, rogue = 305.5 }
const SKILLNUM_Y = { warrior = 270, wizard = 285, rogue = 300 }
const SKILLNUM_X = 124
const SKILLNUM_SIZE = Vector2(19, 14)
const SKILLNUM_FONT_SIZE = 11
const SKILLBAR_X = 146
const SKILLBAR_SIZE = Vector2(130, 12)
const SKILL_PIP_SIZE = Vector2(4, 12)
const SKILL_PIP_MAX = 28

const PRIMARY_STAT_SIZE = Vector2(22, 16)
const PRIMARY_STAT_FONT_SIZE = 12
const SECONDARY_COL_X = [168, 214, 260]
const SECONDARY_START_Y = 327
const SECONDARY_ROW_STEP_Y = 18
const SECONDARY_STAT_SIZE = Vector2(22, 16)
const SECONDARY_STAT_FONT_SIZE = 12

const LIFE_LABEL_RECT = Rect2(100, 443, 48, 15)
const MANA_LABEL_RECT = Rect2(210, 443, 48, 15)
const HP_REGEN_LABEL_RECT = Rect2(119, 461, 28, 15)
const MP_REGEN_LABEL_RECT = Rect2(229, 461, 28, 15)
const VITALS_FONT_SIZE = 10

const INV_PANEL_SIZE = Vector2(608, 552)
const INV_CLOSE_BTN_RECT = Rect2(562, 10, 32, 32)
const SORT_BTN_RECT = Rect2(387, 485, 84, 30)
const INV_SLOT_START = Vector2(45, 68)
const INV_SLOT_STEP = Vector2(66, 66)
const INV_SLOT_SIZE = Vector2(64, 64)

const ACTION_BAR_BORDER_WIDTH = 2
const ACTION_BAR_CORNER_RADIUS = 4
const ACTION_BAR_MARGIN_H = 12
const ACTION_BAR_MARGIN_V = 6
const ACTION_BAR_SEPARATION = 10
const AMMO_LABEL_FONT_SIZE = 14
const AMMO_SLOT_SIZE = Vector2(36, 36)
const SELECTED_INFO_FONT_SIZE = 16

const SLOT_ICON_INSET = 2
const SLOT_COUNT_OFFSET_LEFT = -28
const SLOT_COUNT_OFFSET_TOP = -18
const SLOT_COUNT_OFFSET_RIGHT = -3
const SLOT_COUNT_OFFSET_BOTTOM = -1
const SLOT_COUNT_FONT_SIZE = 12
const SLOT_COUNT_OUTLINE_SIZE = 2

const TOOLTIP_OFFSET = Vector2(16, 16)
const TOOLTIP_SCREEN_MARGIN = 8
const TOOLTIP_FLIP_MARGIN = 12
const TOOLTIP_BORDER_WIDTH = 2
const TOOLTIP_CORNER_RADIUS = 6
const TOOLTIP_MARGIN_H = 10
const TOOLTIP_MARGIN_V = 8
const TOOLTIP_MIN_WIDTH = 240
const TOOLTIP_FONT_SIZE = 14

var _player = null
var _mode = "both"
var _drop_inventory_callback = Callable()
var _drop_equip_callback = Callable()
var _use_inventory_callback = Callable()
var _pickup_callback = Callable()
var _close_callback = Callable()

var _equip_buttons = {}
var _inventory_buttons = []
var _character_name_label = null
var _level_label = null
var _melee_label = null
var _ranged_label = null
var _life_label = null
var _mana_label = null
var _hp_regen_label = null
var _mp_regen_label = null
var _primary_labels = {}
var _secondary_labels = {}
var _resist_vertical_box = null
var _skillbar_containers = {}
var _skillbar_labels = {}
var _selected_info_label = null
var _tooltip_panel = null
var _tooltip_label = null

var _selected_source = null
var _use_button = null
var _equip_button = null
var _unequip_button = null
var _drop_one_button = null
var _drop_all_button = null
var _window = null
var _character_holder = null
var _character_panel = null
var _inventory_holder = null
var _inventory_panel = null
var _action_bar = null
var _last_click_time_ms = 0
var _last_click_key = ""

func init(player, callbacks = {}, mode = "both"):
	_player = player
	_mode = mode if mode in ["character", "inventory", "both"] else "both"
	_drop_inventory_callback = callbacks.get("on_drop_inventory", Callable())
	_drop_equip_callback = callbacks.get("on_drop_equipped", Callable())
	_use_inventory_callback = callbacks.get("on_use_inventory", Callable())
	_pickup_callback = callbacks.get("on_pickup", Callable())
	_close_callback = callbacks.get("on_close", Callable())
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
	return UiHelpers.viewport_size(self, DEFAULT_VIEWPORT_SIZE)

func _style_label(label, font, font_size, color):
	UiHelpers.style_label(label, font_size, color, font)

func _load_tex(path):
	return UiHelpers.load_texture(path)

func _make_texture_button(paths_dict, min_size):
	return UiHelpers.make_texture_button(paths_dict, min_size)

func _create_highlight_style(border_color, background_color = Color(0, 0, 0, 0)):
	var box = StyleBoxFlat.new()
	box.bg_color = background_color
	box.border_color = border_color
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	return box

func _build_ui():
	var dialog_assets = OD.Assets.dialog()
	var font = dialog_assets.font if dialog_assets != null else null
	var viewport_size = _get_viewport_size()
	var base_size = Vector2(946.0, 628.0)
	if _mode == "character":
		base_size = Vector2(360.0, 628.0)
	elif _mode == "inventory":
		base_size = Vector2(608.0, 606.0)
	var ui_scale = clamp(min((viewport_size.x - UI_SCALE_MARGIN.x) / base_size.x, (viewport_size.y - UI_SCALE_MARGIN.y) / base_size.y), UI_SCALE_MIN, UI_SCALE_MAX)

	_window = FloatingWindowScript.new()
	_window.min_window_size = base_size * 0.55
	_window.set_base_size(base_size, ui_scale)
	if _mode == "character":
		_window.position = Vector2(36.0, max(24.0, (viewport_size.y - _window.size.y) * 0.38))
	elif _mode == "inventory":
		_window.position = Vector2(max(36.0, viewport_size.x - _window.size.x - 36.0), max(24.0, (viewport_size.y - _window.size.y) * 0.38))
	else:
		_window.position = Vector2((viewport_size.x - _window.size.x) * 0.5, max(24.0, (viewport_size.y - _window.size.y) * 0.45))
	add_child(_window)

	var root_vertical_box = VBoxContainer.new()
	root_vertical_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vertical_box.add_theme_constant_override("separation", ROOT_VBOX_SEPARATION)
	_window.get_content_root().add_child(root_vertical_box)

	var windows_horizontal_box = HBoxContainer.new()
	windows_horizontal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	windows_horizontal_box.add_theme_constant_override("separation", WINDOWS_HBOX_SEPARATION)
	root_vertical_box.add_child(windows_horizontal_box)

	var show_character = _mode in ["character", "both"]
	var show_inventory = _mode in ["inventory", "both"]

	_equip_buttons.clear()
	if show_character:
		_character_holder = Control.new()
		_character_holder.custom_minimum_size = CHAR_PANEL_SIZE * CHAR_PANEL_EXTRA_SCALE
		windows_horizontal_box.add_child(_character_holder)

		_character_panel = Control.new()
		_character_panel.custom_minimum_size = CHAR_PANEL_SIZE
		_character_panel.size = CHAR_PANEL_SIZE
		_character_panel.scale = Vector2(CHAR_PANEL_EXTRA_SCALE, CHAR_PANEL_EXTRA_SCALE)
		_character_holder.add_child(_character_panel)
		var character_panel = _character_panel
		var character_holder = _character_holder

		var character_background = TextureRect.new()
		character_background.texture = _load_tex(CHAR_PANEL_TEX)
		character_background.size = CHAR_PANEL_SIZE
		character_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		character_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_panel.add_child(character_background)

		_character_name_label = Label.new()
		_character_name_label.position = CHAR_NAME_RECT.position
		_character_name_label.size = CHAR_NAME_RECT.size
		_character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(_character_name_label, font, CHAR_NAME_FONT_SIZE, Color(0.95, 0.9, 0.72))
		character_panel.add_child(_character_name_label)

		var character_close = _make_texture_button(CLOSE_BTN_TEXS, CHAR_CLOSE_BTN_RECT.size)
		character_close.position = CHAR_CLOSE_BTN_RECT.position
		character_close.pressed.connect(dismiss)
		character_panel.add_child(character_close)

		var resist_scroll = ScrollContainer.new()
		resist_scroll.position = RESIST_SCROLL_RECT.position
		resist_scroll.size = RESIST_SCROLL_RECT.size
		resist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		character_panel.add_child(resist_scroll)

		_resist_vertical_box = VBoxContainer.new()
		_resist_vertical_box.add_theme_constant_override("separation", RESIST_VBOX_SEPARATION)
		resist_scroll.add_child(_resist_vertical_box)

		var slot_fill = _load_tex(SLOT_FILL_TEX)
		for slot_name in CHAR_SLOT_RECTS:
			var rect = CHAR_SLOT_RECTS[slot_name]
			var slot_button = _make_slot_button(rect.size, null, font)
			slot_button.position = rect.position
			slot_button.size = rect.size
			slot_button.gui_input.connect(func(ev): _on_equip_slot_gui_input(ev, slot_name))
			slot_button.pressed.connect(func(): _activate_equip_slot(slot_name))
			slot_button.mouse_entered.connect(func(): _show_tooltip_for_equip(slot_name))
			slot_button.mouse_exited.connect(_hide_tooltip)
			slot_button.focus_entered.connect(func(): _show_tooltip_for_equip(slot_name))
			slot_button.focus_exited.connect(_hide_tooltip)
			character_panel.add_child(slot_button)
			_equip_buttons[slot_name] = slot_button

		_melee_label = Label.new()
		_melee_label.position = MELEE_LABEL_RECT.position
		_melee_label.size = MELEE_LABEL_RECT.size
		_melee_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_melee_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_melee_label, font, COMBAT_STAT_FONT_SIZE, Color(0.95, 0.92, 0.84))
		character_panel.add_child(_melee_label)

		_ranged_label = Label.new()
		_ranged_label.position = RANGED_LABEL_RECT.position
		_ranged_label.size = RANGED_LABEL_RECT.size
		_ranged_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_ranged_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_ranged_label, font, COMBAT_STAT_FONT_SIZE, Color(0.95, 0.92, 0.84))
		character_panel.add_child(_ranged_label)

		_level_label = Label.new()
		_level_label.position = LEVEL_LABEL_RECT.position
		_level_label.size = LEVEL_LABEL_RECT.size
		_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_level_label, font, LEVEL_FONT_SIZE, Color(0.96, 0.92, 0.8))
		character_panel.add_child(_level_label)

		_skillbar_labels.clear()
		for branch_key in SKILLBAR_Y:
			var number_label = Label.new()
			number_label.position = Vector2(SKILLNUM_X, SKILLNUM_Y[branch_key])
			number_label.size = SKILLNUM_SIZE
			number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_style_label(number_label, font, SKILLNUM_FONT_SIZE, Color(0.96, 0.94, 0.88))
			character_panel.add_child(number_label)
			_skillbar_labels[branch_key] = number_label

			var bar_horizontal_box = HBoxContainer.new()
			bar_horizontal_box.position = Vector2(SKILLBAR_X, SKILLBAR_Y[branch_key])
			bar_horizontal_box.size = SKILLBAR_SIZE
			bar_horizontal_box.add_theme_constant_override("separation", 0)
			character_panel.add_child(bar_horizontal_box)
			_skillbar_containers[branch_key] = bar_horizontal_box

		_primary_labels.clear()
		for p_info in PRIMARY_STAT_POSITIONS:
			var label = Label.new()
			label.position = p_info.pos
			label.size = PRIMARY_STAT_SIZE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_style_label(label, font, PRIMARY_STAT_FONT_SIZE, Color(0.96, 0.94, 0.88))
			character_panel.add_child(label)
			_primary_labels[p_info.key] = label

		_secondary_labels.clear()
		for row_index in range(SECONDARY_GRID_KEYS.size()):
			for col_index in range(3):
				var sec_key = SECONDARY_GRID_KEYS[row_index][col_index]
				var label = Label.new()
				label.position = Vector2(SECONDARY_COL_X[col_index], SECONDARY_START_Y + row_index * SECONDARY_ROW_STEP_Y)
				label.size = SECONDARY_STAT_SIZE
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				_style_label(label, font, SECONDARY_STAT_FONT_SIZE, Color(0.96, 0.94, 0.88))
				character_panel.add_child(label)
				_secondary_labels[sec_key] = label

		_life_label = Label.new()
		_life_label.position = LIFE_LABEL_RECT.position
		_life_label.size = LIFE_LABEL_RECT.size
		_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_life_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_life_label, font, VITALS_FONT_SIZE, Color(0.98, 0.92, 0.9))
		character_panel.add_child(_life_label)

		_mana_label = Label.new()
		_mana_label.position = MANA_LABEL_RECT.position
		_mana_label.size = MANA_LABEL_RECT.size
		_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_mana_label, font, VITALS_FONT_SIZE, Color(0.9, 0.94, 0.98))
		character_panel.add_child(_mana_label)

		_hp_regen_label = Label.new()
		_hp_regen_label.position = HP_REGEN_LABEL_RECT.position
		_hp_regen_label.size = HP_REGEN_LABEL_RECT.size
		_hp_regen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hp_regen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_hp_regen_label, font, VITALS_FONT_SIZE, Color(0.95, 0.85, 0.85))
		character_panel.add_child(_hp_regen_label)

		_mp_regen_label = Label.new()
		_mp_regen_label.position = MP_REGEN_LABEL_RECT.position
		_mp_regen_label.size = MP_REGEN_LABEL_RECT.size
		_mp_regen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_mp_regen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(_mp_regen_label, font, VITALS_FONT_SIZE, Color(0.85, 0.9, 0.98))
		character_panel.add_child(_mp_regen_label)

	_inventory_buttons.clear()
	if show_inventory:
		_inventory_holder = Control.new()
		_inventory_holder.custom_minimum_size = INV_PANEL_SIZE
		windows_horizontal_box.add_child(_inventory_holder)

		_inventory_panel = Control.new()
		_inventory_panel.custom_minimum_size = INV_PANEL_SIZE
		_inventory_panel.size = INV_PANEL_SIZE
		_inventory_holder.add_child(_inventory_panel)
		var inventory_panel = _inventory_panel

		var inventory_background = TextureRect.new()
		inventory_background.texture = _load_tex(INV_PANEL_TEX)
		inventory_background.size = INV_PANEL_SIZE
		inventory_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		inventory_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_panel.add_child(inventory_background)

		var inventory_close = _make_texture_button(CLOSE_BTN_TEXS, INV_CLOSE_BTN_RECT.size)
		inventory_close.position = INV_CLOSE_BTN_RECT.position
		inventory_close.pressed.connect(dismiss)
		inventory_panel.add_child(inventory_close)

		var sort_button = _make_texture_button(SORT_BTN_TEXS, SORT_BTN_RECT.size)
		sort_button.position = SORT_BTN_RECT.position
		sort_button.size = SORT_BTN_RECT.size
		sort_button.pressed.connect(func():
			if _player != null:
				_selected_source = null
				_player.sort_inventory()
		)
		inventory_panel.add_child(sort_button)

		for ii in range(PlayerCharacter.INVENTORY_SIZE):
			var slot_index = ii
			var row_index = ii / PlayerCharacter.INVENTORY_COLS
			var col_index = ii % PlayerCharacter.INVENTORY_COLS
			var inventory_button = _make_slot_button(INV_SLOT_SIZE, null, font)
			inventory_button.position = Vector2(INV_SLOT_START.x + col_index * INV_SLOT_STEP.x, INV_SLOT_START.y + row_index * INV_SLOT_STEP.y)
			inventory_button.size = INV_SLOT_SIZE
			inventory_button.gui_input.connect(func(ev): _on_inv_slot_gui_input(ev, slot_index))
			inventory_button.pressed.connect(func(): _activate_inv_slot(slot_index))
			inventory_button.mouse_entered.connect(func(): _show_tooltip_for_inv(slot_index))
			inventory_button.mouse_exited.connect(_hide_tooltip)
			inventory_button.focus_entered.connect(func(): _show_tooltip_for_inv(slot_index))
			inventory_button.focus_exited.connect(_hide_tooltip)
			inventory_panel.add_child(inventory_button)
			_inventory_buttons.append(inventory_button)

	var action_bar = PanelContainer.new()
	_action_bar = action_bar
	var action_style = StyleBoxFlat.new()
	action_style.bg_color = Color(0.14, 0.11, 0.08, 0.92)
	action_style.border_color = Color(0.55, 0.45, 0.28)
	action_style.set_border_width_all(ACTION_BAR_BORDER_WIDTH)
	action_style.set_corner_radius_all(ACTION_BAR_CORNER_RADIUS)
	action_style.content_margin_left = ACTION_BAR_MARGIN_H
	action_style.content_margin_right = ACTION_BAR_MARGIN_H
	action_style.content_margin_top = ACTION_BAR_MARGIN_V
	action_style.content_margin_bottom = ACTION_BAR_MARGIN_V
	action_bar.add_theme_stylebox_override("panel", action_style)
	root_vertical_box.add_child(action_bar)

	var action_horizontal_box = HBoxContainer.new()
	action_horizontal_box.add_theme_constant_override("separation", ACTION_BAR_SEPARATION)
	action_bar.add_child(action_horizontal_box)

	if show_character:
		var slot_fill = _load_tex(SLOT_FILL_TEX)
		for ammo_slot in AMMO_SLOTS:
			var ammo_label = Label.new()
			ammo_label.text = SLOT_LABELS.get(ammo_slot, ammo_slot) + ":"
			_style_label(ammo_label, font, AMMO_LABEL_FONT_SIZE, Color(0.88, 0.82, 0.68))
			action_horizontal_box.add_child(ammo_label)
			var ammo_button = _make_slot_button(AMMO_SLOT_SIZE, slot_fill, font)
			ammo_button.gui_input.connect(func(ev): _on_equip_slot_gui_input(ev, ammo_slot))
			ammo_button.pressed.connect(func(): _activate_equip_slot(ammo_slot))
			ammo_button.mouse_entered.connect(func(): _show_tooltip_for_equip(ammo_slot))
			ammo_button.mouse_exited.connect(_hide_tooltip)
			ammo_button.focus_entered.connect(func(): _show_tooltip_for_equip(ammo_slot))
			ammo_button.focus_exited.connect(_hide_tooltip)
			action_horizontal_box.add_child(ammo_button)
			_equip_buttons[ammo_slot] = ammo_button

	_selected_info_label = Label.new()
	_selected_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_info_label.text = "Click to select/move, Right-click or Double-click to equip/unequip."
	_style_label(_selected_info_label, font, SELECTED_INFO_FONT_SIZE, Color(0.95, 0.9, 0.78))
	action_horizontal_box.add_child(_selected_info_label)

	if show_inventory:
		_use_button = Button.new()
		_use_button.text = "Use"
		_use_button.pressed.connect(_on_use_selected_pressed)
		action_horizontal_box.add_child(_use_button)

		_equip_button = Button.new()
		_equip_button.text = "Equip"
		_equip_button.pressed.connect(_on_equip_selected_pressed)
		action_horizontal_box.add_child(_equip_button)

	if show_character:
		_unequip_button = Button.new()
		_unequip_button.text = "Unequip"
		_unequip_button.pressed.connect(_on_unequip_selected_pressed)
		action_horizontal_box.add_child(_unequip_button)

	_drop_one_button = Button.new()
	_drop_one_button.text = "Drop 1"
	_drop_one_button.pressed.connect(func(): _drop_selected(1))
	action_horizontal_box.add_child(_drop_one_button)

	_drop_all_button = Button.new()
	_drop_all_button.text = "Drop Stack"
	_drop_all_button.pressed.connect(func(): _drop_selected(-1))
	action_horizontal_box.add_child(_drop_all_button)

	if show_inventory and _pickup_callback.is_valid():
		var pickup_button = Button.new()
		pickup_button.text = "Pickup (G)"
		pickup_button.pressed.connect(func():
			_pickup_callback.call()
			refresh()
		)
		action_horizontal_box.add_child(pickup_button)

	UiHelpers.enable_gamepad_focus_in_tree(_action_bar)
	if not _inventory_buttons.is_empty():
		_inventory_buttons[0].call_deferred("grab_focus")
	elif not _equip_buttons.is_empty():
		var first_equip_key = _equip_buttons.keys()[0]
		_equip_buttons[first_equip_key].call_deferred("grab_focus")

	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 50
	var tip_style = StyleBoxFlat.new()
	tip_style.bg_color = Color(0.11, 0.09, 0.07, 0.96)
	tip_style.border_color = Color(0.75, 0.62, 0.35, 1.0)
	tip_style.set_border_width_all(TOOLTIP_BORDER_WIDTH)
	tip_style.set_corner_radius_all(TOOLTIP_CORNER_RADIUS)
	tip_style.content_margin_left = TOOLTIP_MARGIN_H
	tip_style.content_margin_right = TOOLTIP_MARGIN_H
	tip_style.content_margin_top = TOOLTIP_MARGIN_V
	tip_style.content_margin_bottom = TOOLTIP_MARGIN_V
	_tooltip_panel.add_theme_stylebox_override("panel", tip_style)
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.custom_minimum_size = Vector2(TOOLTIP_MIN_WIDTH, 0)
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(_tooltip_label, font, TOOLTIP_FONT_SIZE, Color(0.95, 0.92, 0.84))
	_tooltip_panel.add_child(_tooltip_label)

func _make_slot_button(min_size, background_texture, font):
	var button = Button.new()
	button.custom_minimum_size = min_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	var empty_style = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", _create_highlight_style(Color(0.9, 0.78, 0.42, 0.9), Color(1, 1, 1, 0.08)))
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("pressed", _create_highlight_style(Color(1.0, 0.9, 0.5, 1.0), Color(1, 1, 1, 0.14)))
	UiHelpers.attach_focus_ring(button)

	if background_texture != null:
		var slot_background = TextureRect.new()
		slot_background.name = "SlotBg"
		slot_background.texture = background_texture
		slot_background.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_background.stretch_mode = TextureRect.STRETCH_SCALE
		slot_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(slot_background)

	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = SLOT_ICON_INSET
	icon_rect.offset_top = SLOT_ICON_INSET
	icon_rect.offset_right = -SLOT_ICON_INSET
	icon_rect.offset_bottom = -SLOT_ICON_INSET
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_rect)

	var count_label = Label.new()
	count_label.name = "Count"
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = SLOT_COUNT_OFFSET_LEFT
	count_label.offset_top = SLOT_COUNT_OFFSET_TOP
	count_label.offset_right = SLOT_COUNT_OFFSET_RIGHT
	count_label.offset_bottom = SLOT_COUNT_OFFSET_BOTTOM
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(count_label, font, SLOT_COUNT_FONT_SIZE, Color(1.0, 0.96, 0.72))
	count_label.add_theme_constant_override("outline_size", SLOT_COUNT_OUTLINE_SIZE)
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	button.add_child(count_label)
	return button

func _process(_delta):
	if _tooltip_panel != null and _tooltip_panel.visible:
		UiHelpers.position_tooltip(
			_tooltip_panel,
			get_viewport().get_mouse_position(),
			_get_viewport_size(),
			TOOLTIP_OFFSET,
			TOOLTIP_SCREEN_MARGIN,
			TOOLTIP_FLIP_MARGIN
		)

func get_floating_window():
	return _window

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and not event.echo:
		var matches_close = event.keycode == KEY_ESCAPE
		if _mode == "character" and event.keycode == KEY_C:
			matches_close = true
		elif _mode in ["inventory", "both"] and event.keycode == KEY_I:
			matches_close = true
		if matches_close:
			get_viewport().set_input_as_handled()
			dismiss()
	elif UiHelpers.is_gamepad_cancel(event):
		get_viewport().set_input_as_handled()
		dismiss()
	elif UiHelpers.is_gamepad_button(event, JOY_BUTTON_X):
		if _use_button != null and not _use_button.disabled:
			_use_button.pressed.emit()
		elif _equip_button != null and not _equip_button.disabled:
			_equip_button.pressed.emit()
		elif _unequip_button != null and not _unequip_button.disabled:
			_unequip_button.pressed.emit()
		get_viewport().set_input_as_handled()
	elif UiHelpers.is_gamepad_button(event, JOY_BUTTON_Y):
		if _drop_one_button != null and not _drop_one_button.disabled:
			_drop_one_button.pressed.emit()
		get_viewport().set_input_as_handled()

func _activate_inv_slot(slot_index):
	if _player == null:
		return
	var item = _player.inventory[slot_index]
	if _selected_source == null:
		if item != null:
			_selected_source = { kind = "inv", index = slot_index }
		refresh()
		return
	if _selected_source.kind == "inv":
		if _selected_source.index == slot_index:
			_selected_source = null
		else:
			_player.move_or_swap_inventory_slot(_selected_source.index, slot_index)
			_selected_source = null
		refresh()
		return
	if _selected_source.kind == "equip":
		_player.unequip_slot(_selected_source.slot, slot_index)
		_selected_source = null
		refresh()

func _activate_equip_slot(slot_name):
	if _player == null:
		return
	var equipped = _player.get_equipped_item(slot_name)
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
			_selected_source = { kind = "equip", slot = slot_name }
		refresh()

func dismiss():
	if _close_callback.is_valid():
		_close_callback.call()
	queue_free()

func _is_double_click(click_key):
	var now_ms = Time.get_ticks_msec()
	var is_double = (_last_click_key == click_key and (now_ms - _last_click_time_ms) <= 320)
	_last_click_time_ms = now_ms
	_last_click_key = click_key
	return is_double

func _on_inv_slot_gui_input(event, slot_index):
	if _player == null or not (event is InputEventMouseButton) or not event.pressed:
		return
	var item = _player.inventory[slot_index]
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if item != null:
			if _player.is_item_usable(item):
				_use_inventory_slot(slot_index)
			else:
				_player.equip_from_inventory(slot_index)
				_selected_source = null
				refresh()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if item != null and _is_double_click("inv_" + str(slot_index)):
		if _player.is_item_usable(item):
			_use_inventory_slot(slot_index)
		else:
			_player.equip_from_inventory(slot_index)
			_selected_source = null
			refresh()
		return
	if _selected_source == null:
		if item != null:
			_selected_source = { kind = "inv", index = slot_index }
		refresh()
		return
	if _selected_source.kind == "inv":
		if _selected_source.index == slot_index:
			_selected_source = null
		else:
			_player.move_or_swap_inventory_slot(_selected_source.index, slot_index)
			_selected_source = null
		refresh()
		return
	if _selected_source.kind == "equip":
		_player.unequip_slot(_selected_source.slot, slot_index)
		_selected_source = null
		refresh()

func _on_equip_slot_gui_input(event, slot_name):
	if _player == null or not (event is InputEventMouseButton) or not event.pressed:
		return
	var equipped = _player.get_equipped_item(slot_name)
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if equipped != null:
			_player.unequip_slot(slot_name)
			_selected_source = null
			refresh()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
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

func _use_inventory_slot(slot_index):
	if _player == null:
		return
	if _use_inventory_callback.is_valid():
		_use_inventory_callback.call(slot_index)
	else:
		_player.use_consumable_at(slot_index)
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
		if _drop_inventory_callback.is_valid():
			_drop_inventory_callback.call(idx, count)
		else:
			_player.remove_item_at(idx, count)
		if _player.inventory[idx] == null:
			_selected_source = null
	elif _selected_source.kind == "equip":
		var slot_name = _selected_source.slot
		if _drop_equip_callback.is_valid():
			_drop_equip_callback.call(slot_name)
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
		var button = _equip_buttons.get(slot_name, null)
		if button == null:
			continue
		var item = _player.get_equipped_item(slot_name)
		var is_selected = (_selected_source != null and _selected_source.kind == "equip" and _selected_source.slot == slot_name)
		var is_valid_target = (slot_name in valid_slots)
		_apply_slot_visuals(button, item, is_selected, is_valid_target)

	for ii in range(_inventory_buttons.size()):
		var button = _inventory_buttons[ii]
		var item = _player.inventory[ii]
		var is_selected = (_selected_source != null and _selected_source.kind == "inv" and _selected_source.index == ii)
		_apply_slot_visuals(button, item, is_selected, false)

	_refresh_selected_controls(selected_item)
	_refresh_stats()

func _apply_slot_visuals(button, item, is_selected, is_valid_target):
	var icon_rect = button.get_node("Icon")
	var count_label = button.get_node("Count")
	if is_selected:
		button.add_theme_stylebox_override("normal", _create_highlight_style(Color(1.0, 0.85, 0.25), Color(0.9, 0.7, 0.2, 0.2)))
	elif is_valid_target:
		button.add_theme_stylebox_override("normal", _create_highlight_style(Color(0.45, 0.95, 0.4), Color(0.3, 0.8, 0.3, 0.16)))
	else:
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())

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
		if _use_button != null:
			_use_button.disabled = true
		if _equip_button != null:
			_equip_button.disabled = true
		if _unequip_button != null:
			_unequip_button.disabled = true
		_drop_one_button.disabled = true
		_drop_all_button.disabled = true
		return
	var cnt = int(selected_item.get("count", 1))
	var count_text = " (x" + str(cnt) + ")" if cnt > 1 else ""
	_selected_info_label.text = str(selected_item.get("name", "Item")) + count_text
	var is_inventory = _selected_source != null and _selected_source.kind == "inv"
	if _use_button != null:
		_use_button.disabled = not (is_inventory and _player.is_item_usable(selected_item))
	if _equip_button != null:
		var can_equip = is_inventory and not _player.get_valid_slots_for_item(selected_item).is_empty()
		_equip_button.disabled = not can_equip
	if _unequip_button != null:
		_unequip_button.disabled = not (_selected_source != null and _selected_source.kind == "equip")
	_drop_one_button.disabled = false
	_drop_all_button.disabled = cnt <= 1

func _compute_melee_attack_total():
	var total = _player.get_secondary_stat("melee_power")
	for slot_name in ["weapon_right", "weapon_left"]:
		var item = _player.get_equipped_item(slot_name)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var w_damage = item.get("weapon_damage", {})
			for damage_type in w_damage:
				total += int(w_damage[damage_type])
	for damage_type in PlayerCharacter.DAMAGE_TYPES:
		total += _player.get_damage_bonus(damage_type)
	return total

func _compute_ranged_attack_total():
	var total = 0
	for slot_name in ["missile_weapon", "bolts"]:
		var item = _player.get_equipped_item(slot_name)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var w_damage = item.get("weapon_damage", {})
			for damage_type in w_damage:
				total += int(w_damage[damage_type])
	return total

func _refresh_stats():
	if _player == null or _character_name_label == null:
		return
	_character_name_label.text = _player.character_name if _player.character_name != "" else "Hero"
	_level_label.text = str(_player.level)
	var melee_value = _compute_melee_attack_total()
	var ranged_value = _compute_ranged_attack_total()
	_melee_label.text = ("+" if melee_value >= 0 else "") + str(melee_value)
	_ranged_label.text = ("+" if ranged_value >= 0 else "") + str(ranged_value) if ranged_value != 0 else ""

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
		var bar_texture = _load_tex(SKILLBAR_TEXS.get(branch_key, ""))
		var pip_count = clamp(int(branch_levels.get(branch_key, 0)), 0, SKILL_PIP_MAX)
		for ii in range(pip_count):
			var pip = TextureRect.new()
			pip.texture = bar_texture
			pip.custom_minimum_size = SKILL_PIP_SIZE
			pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pip.stretch_mode = TextureRect.STRETCH_SCALE
			pip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(pip)

	for child in _resist_vertical_box.get_children():
		child.queue_free()
	var dialog_assets = OD.Assets.dialog()
	var font = dialog_assets.font if dialog_assets != null else null
	for damage_type in PlayerCharacter.DAMAGE_TYPES:
		var result_value = _player.get_resistance(damage_type)
		if result_value == 0:
			continue
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", RESIST_ROW_SEPARATION)
		_resist_vertical_box.add_child(row)
		var icon_path = RESIST_ICON_OVERRIDES.get(damage_type, "ui/icons/dmg_" + damage_type + "_resist.png")
		var icon_texture = _load_tex(icon_path)
		if icon_texture != null:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_texture
			icon_rect.custom_minimum_size = RESIST_ICON_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(icon_rect)
		var result_label = Label.new()
		result_label.text = str(result_value)
		var result_color = Color(0.45, 0.9, 0.45) if result_value > 0 else Color(0.95, 0.35, 0.35)
		_style_label(result_label, font, RESIST_FONT_SIZE, result_color)
		row.add_child(result_label)

func _show_tooltip_for_inv(slot_index):
	if _player == null:
		return
	var item = _player.inventory[slot_index]
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
	if bool(item.get("is_artifact", false)):
		lines.append("Artifact (Quality %d)" % int(item.get("artifact_quality", 1)))
	var category_text = str(item.get("category", "misc")).capitalize()
	var slot_text = str(item.get("slot", ""))
	if slot_text != "" and slot_text != category_text.to_lower():
		category_text += " (" + slot_text + ")"
	lines.append("Level %d  |  %s  |  Sell: %d zm" % [int(item.get("level", 1)), category_text, int(item.get("sell_price", 0))])

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

	var w_damage = item.get("weapon_damage", {})
	if typeof(w_damage) == TYPE_DICTIONARY and not w_damage.is_empty():
		var w_parts = []
		for damage_type in w_damage:
			w_parts.append(str(damage_type).capitalize() + ": " + str(w_damage[damage_type]))
		lines.append("Weapon: " + ", ".join(w_parts))

	for p_buff in item.get("primary_buffs", []):
		var pid = int(p_buff.get("id", -1))
		if pid >= 0 and pid < PlayerCharacter.PRIMARY_STAT_KEYS.size():
			var amt = int(p_buff.get("amount", 0))
			var sign_text = "+" if amt >= 0 else ""
			lines.append(sign_text + str(amt) + " " + PlayerCharacter.PRIMARY_STAT_KEYS[pid].capitalize())

	for s_buff in item.get("secondary_buffs", []):
		var sid = int(s_buff.get("id", -1))
		var sec_key = PlayerCharacter.SECONDARY_STAT_BY_ID.get(sid, "")
		if sec_key != "":
			var amt = int(s_buff.get("amount", 0))
			var sign_text = "+" if amt >= 0 else ""
			lines.append(sign_text + str(amt) + " " + SECONDARY_STAT_LABELS.get(sec_key, sec_key))

	var result_map = item.get("resist_buffs", {})
	if typeof(result_map) == TYPE_DICTIONARY and not result_map.is_empty():
		for damage_type in result_map:
			var amt = int(result_map[damage_type])
			var sign_text = "+" if amt >= 0 else ""
			lines.append(sign_text + str(amt) + " " + str(damage_type).capitalize() + " Resist")

	var damage_map = item.get("damage_buffs", {})
	if typeof(damage_map) == TYPE_DICTIONARY and not damage_map.is_empty():
		for damage_type in damage_map:
			var amt = int(damage_map[damage_type])
			var sign_text = "+" if amt >= 0 else ""
			lines.append(sign_text + str(amt) + " " + str(damage_type).capitalize() + " Damage")

	var encrusts = item.get("encrusts", [])
	if typeof(encrusts) == TYPE_ARRAY and not encrusts.is_empty():
		lines.append("Encrusts: " + ", ".join(encrusts))
		lines.append("Instability: " + str(int(item.get("instability", 0))))
		var unstable_list = item.get("unstable_effects", [])
		if typeof(unstable_list) == TYPE_ARRAY and not unstable_list.is_empty():
			var u_names = []
			for u_entry in unstable_list:
				u_names.append(str(u_entry.get("name", "")))
			lines.append("Unstable: " + ", ".join(u_names))

	var desc = str(item.get("description", ""))
	if desc != "":
		lines.append("")
		lines.append(desc)

	_tooltip_label.text = "\n".join(lines)
	_tooltip_panel.visible = true

func _hide_tooltip():
	if _tooltip_panel != null:
		_tooltip_panel.visible = false
