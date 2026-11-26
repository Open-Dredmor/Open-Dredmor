extends Control

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const HOVER_TOOLTIP_DELAY = 0.55

const SETTING_TOOLTIPS = {
	"easy": "Elves Just Want to Have Fun (Easy)\nA lighter, more forgiving dungeon crawl with gentler encounters.",
	"medium": "Dwarvish Moderation (Medium)\nThe standard Dungeons of Dredmor experience with balanced challenge.",
	"hard": "Going Rogue (Hard)\nA punishing difficulty for seasoned dungeoneers where mistakes are costly.",
	"permadeath": "Permadeath\nDeath is final. Your save file is deleted when your character dies, with no reloading.",
	"no_time_to_grind": "No Time to Grind\nGenerates smaller dungeon floors for faster runs while keeping experience progression."
}

static func init_container():
	return Control.new()

var _no_time_to_grind_enabled = false
var _permadeath_enabled = false
var _permadeath_checkmark = null
var _no_time_to_grind_checkmark = null
var _easy_checkmark = null
var _medium_checkmark = null
var _hard_checkmark = null
var _selected_pack_ids = []
var _ordered_pack_ids = []
var _available_packs_by_id = {}
var _pack_list_container = null
var _pack_list_assets = null
var _tooltip_panel = null
var _tooltip_label = null
var _pending_tooltip_text = ""
var _tooltip_delay_remaining = 0.0
var _tooltip_active = false
var _left_buttons = []

func _ready():	
	call_deferred("_build_gui")

func _process(delta):
	if _pending_tooltip_text != "":
		if not _tooltip_active:
			_tooltip_delay_remaining -= delta
			if _tooltip_delay_remaining <= 0.0:
				_tooltip_active = true
				_show_tooltip(_pending_tooltip_text)
		if _tooltip_active and _tooltip_panel != null and _tooltip_panel.visible:
			UiHelpers.position_tooltip(_tooltip_panel, get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)
	
func _build_gui():
	var assets = OD.Assets.difficulty_menu()
	var difficulty_menu = get_node("/root/Container")
	var display_size = OD.Settings.display_size()
	difficulty_menu.set_size(display_size)

	if OD.Load.exists("ui/menus/bg_stonetile.png"):
		var background_tile = TextureRect.new()
		background_tile.texture = OD.Load.image("ui/menus/bg_stonetile.png")
		background_tile.stretch_mode = TextureRect.STRETCH_TILE
		background_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		difficulty_menu.add_child(background_tile)

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	var header_height = header_background.texture.get_height()
	header_background.size = Vector2(display_size.x, header_height)
	difficulty_menu.add_child(header_background)
	
	var back_button = OD.Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.offset_left = 0
	back_button.offset_top = 0
	back_button.pressed.connect(_on_BackButton_pressed)
	difficulty_menu.add_child(back_button)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.choose_header
	header_text.anchor_left = .5
	header_text.offset_left = - (header_text.texture.get_width()/2)
	difficulty_menu.add_child(header_text)	
	
	var done_button = OD.Chrome.button(assets.textures.done_button)
	done_button.anchor_left = 1
	done_button.anchor_top = 0
	done_button.offset_left = -done_button.texture_normal.get_width()
	done_button.offset_top = 0
	done_button.pressed.connect(_on_DoneButton_pressed)
	difficulty_menu.add_child(done_button)

	var columns_container = MarginContainer.new()
	columns_container.anchor_left = 0.0
	columns_container.anchor_top = 0.0
	columns_container.anchor_right = 1.0
	columns_container.anchor_bottom = 1.0
	columns_container.offset_top = header_height + 24
	columns_container.offset_left = 40
	columns_container.offset_right = -40
	columns_container.offset_bottom = -24
	difficulty_menu.add_child(columns_container)

	var columns_box = HBoxContainer.new()
	columns_box.alignment = BoxContainer.ALIGNMENT_CENTER
	columns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns_box.add_theme_constant_override("separation", 48)
	columns_container.add_child(columns_box)

	var options_form = TextureRect.new()
	options_form.texture = assets.textures.options_form
	var options_width = options_form.texture.get_width()
	var options_height = options_form.texture.get_height()
	options_form.custom_minimum_size = Vector2(options_width, options_height)
	options_form.stretch_mode = TextureRect.STRETCH_KEEP
	options_form.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	columns_box.add_child(options_form)
		
	_easy_checkmark = TextureRect.new()
	_easy_checkmark.texture = assets.textures.checkmark_large
	_easy_checkmark.anchor_top = .175
	_easy_checkmark.anchor_left = .245
	_easy_checkmark.offset_left = -(_easy_checkmark.texture.get_width()/2)
	_easy_checkmark.offset_top = -(_easy_checkmark.texture.get_height()/2)
	options_form.add_child(_easy_checkmark)
		
	var easy_button = OD.Chrome.invisible_button()
	easy_button.pressed.connect(_on_EasyDifficultyButton_pressed)	
	easy_button.set_size(Vector2(options_width * .7, 50))
	easy_button.anchor_top = .12
	easy_button.anchor_left = .15
	_attach_setting_tooltip(easy_button, SETTING_TOOLTIPS["easy"])
	options_form.add_child(easy_button)	
	
	_medium_checkmark = TextureRect.new()
	_medium_checkmark.texture = assets.textures.checkmark_large
	_medium_checkmark.anchor_top = .285
	_medium_checkmark.anchor_left = .245
	_medium_checkmark.offset_left = -(_medium_checkmark.texture.get_width()/2)
	_medium_checkmark.offset_top = -(_medium_checkmark.texture.get_height()/2)
	options_form.add_child(_medium_checkmark)
	
	var medium_button = OD.Chrome.invisible_button()	
	medium_button.pressed.connect(_on_MediumDifficultyButton_pressed)	
	medium_button.set_size(Vector2(options_width * .7, 60))
	medium_button.anchor_top = .22
	medium_button.anchor_left = .15
	_attach_setting_tooltip(medium_button, SETTING_TOOLTIPS["medium"])
	options_form.add_child(medium_button)
	
	_hard_checkmark = TextureRect.new()
	_hard_checkmark.texture = assets.textures.checkmark_large
	_hard_checkmark.anchor_top = .39
	_hard_checkmark.anchor_left = .245
	_hard_checkmark.offset_left = -(_hard_checkmark.texture.get_width()/2)
	_hard_checkmark.offset_top = -(_hard_checkmark.texture.get_height()/2)
	options_form.add_child(_hard_checkmark)
	
	var hard_button = OD.Chrome.invisible_button()
	hard_button.pressed.connect(_on_HardDifficultyButton_pressed)	
	hard_button.set_size(Vector2(options_width * .7, 70))
	hard_button.anchor_top = .34
	hard_button.anchor_left = .15
	_attach_setting_tooltip(hard_button, SETTING_TOOLTIPS["hard"])
	options_form.add_child(hard_button)
	
	_permadeath_checkmark = TextureRect.new()
	_permadeath_checkmark.texture = assets.textures.checkmark_small
	_permadeath_checkmark.anchor_top = .55
	_permadeath_checkmark.anchor_left = .22
	_permadeath_checkmark.offset_left = -(_permadeath_checkmark.texture.get_width()/2)
	_permadeath_checkmark.offset_top = -(_permadeath_checkmark.texture.get_height()/2)
	options_form.add_child(_permadeath_checkmark)
	
	var permadeath_button = OD.Chrome.invisible_button()
	permadeath_button.pressed.connect(_on_PermadeathButton_pressed)	
	permadeath_button.set_size(Vector2(options_width * .7, 60))
	permadeath_button.anchor_top = .50
	permadeath_button.anchor_left = .15
	_attach_setting_tooltip(permadeath_button, SETTING_TOOLTIPS["permadeath"])
	options_form.add_child(permadeath_button)
	
	_no_time_to_grind_checkmark = TextureRect.new()
	_no_time_to_grind_checkmark.texture = assets.textures.checkmark_small
	_no_time_to_grind_checkmark.anchor_top = .71
	_no_time_to_grind_checkmark.anchor_left = .22
	_no_time_to_grind_checkmark.offset_left = -(_no_time_to_grind_checkmark.texture.get_width()/2)
	_no_time_to_grind_checkmark.offset_top = -(_no_time_to_grind_checkmark.texture.get_height()/2)
	options_form.add_child(_no_time_to_grind_checkmark)
	
	var no_time_to_grind_button = OD.Chrome.invisible_button()
	no_time_to_grind_button.pressed.connect(_on_NoTimeToGrindButton_pressed)	
	no_time_to_grind_button.set_size(Vector2(options_width * .7, 60))
	no_time_to_grind_button.anchor_top = .65
	no_time_to_grind_button.anchor_left = .15
	_attach_setting_tooltip(no_time_to_grind_button, SETTING_TOOLTIPS["no_time_to_grind"])
	options_form.add_child(no_time_to_grind_button)	
	
	var settings = OD.DungeonSettings.get_settings()
	_permadeath_enabled = settings.permadeath
	_no_time_to_grind_enabled = settings.no_time_to_grind
	_selected_pack_ids = settings.active_packs.duplicate()
	_select_difficulty(settings.difficulty)
	_permadeath_checkmark.visible = _permadeath_enabled
	_no_time_to_grind_checkmark.visible = _no_time_to_grind_enabled

	_left_buttons = [easy_button, medium_button, hard_button, permadeath_button, no_time_to_grind_button]
	for ii in range(_left_buttons.size()):
		var current_button = _left_buttons[ii]
		if ii > 0:
			current_button.focus_neighbor_top = current_button.get_path_to(_left_buttons[ii - 1])
		else:
			current_button.focus_neighbor_top = current_button.get_path_to(back_button)
		if ii < _left_buttons.size() - 1:
			current_button.focus_neighbor_bottom = current_button.get_path_to(_left_buttons[ii + 1])

	_build_content_packs_panel(columns_box, assets, display_size, options_height)

	var tooltip_nodes = UiHelpers.create_tooltip(difficulty_menu, 300, 17)
	_tooltip_panel = tooltip_nodes.panel
	_tooltip_label = tooltip_nodes.label

	easy_button.call_deferred("grab_focus")

func _attach_setting_tooltip(control, tooltip_text):
	control.mouse_entered.connect(func(): _on_setting_hover_entered(tooltip_text))
	control.mouse_exited.connect(func(): _on_setting_hover_exited(tooltip_text))

func _on_setting_hover_entered(tooltip_text):
	_pending_tooltip_text = tooltip_text
	_tooltip_delay_remaining = HOVER_TOOLTIP_DELAY
	_tooltip_active = false
	_hide_tooltip()

func _on_setting_hover_exited(tooltip_text):
	if _pending_tooltip_text == tooltip_text:
		_pending_tooltip_text = ""
		_tooltip_delay_remaining = 0.0
		_tooltip_active = false
		_hide_tooltip()

func _show_tooltip(tooltip_text):
	if _tooltip_label != null and _tooltip_panel != null:
		_tooltip_label.text = tooltip_text
		_tooltip_panel.visible = true
		UiHelpers.position_tooltip(_tooltip_panel, get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)

func _hide_tooltip():
	if _tooltip_panel != null:
		_tooltip_panel.visible = false

func _unhandled_input(event):
	if (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_BackButton_pressed()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		get_viewport().set_input_as_handled()
		_on_DoneButton_pressed()

func _initialize_pack_order():
	_available_packs_by_id.clear()
	_ordered_pack_ids.clear()
	var available_packs = OD.Database.get_available_packs()
	for pack_info in available_packs:
		_available_packs_by_id[pack_info.id] = pack_info
	for pack_id in _selected_pack_ids:
		if _available_packs_by_id.has(pack_id) and not _ordered_pack_ids.has(pack_id):
			_ordered_pack_ids.append(pack_id)
	for pack_info in available_packs:
		if not _ordered_pack_ids.has(pack_info.id):
			_ordered_pack_ids.append(pack_info.id)
	_sync_selected_pack_order()

func _sync_selected_pack_order():
	var ordered_selected = []
	for pack_id in _ordered_pack_ids:
		if _selected_pack_ids.has(pack_id):
			ordered_selected.append(pack_id)
	_selected_pack_ids = ordered_selected
	OD.DungeonSettings.set_active_packs(_selected_pack_ids)

func _build_content_packs_panel(parent, assets, display_size, target_height):
	var dialog_assets = OD.Assets.dialog()
	var font_result = dialog_assets.font if dialog_assets != null else null
	var parchment_background = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	var ink_color = Color(0.16, 0.10, 0.06)
	var header_ink = Color(0.28, 0.12, 0.05)

	var panel_width = clamp(display_size.x * 0.42, 460.0, 660.0)
	var panel_height = clamp(target_height, 480.0, max(480.0, display_size.y - 160.0))

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if parchment_background != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = parchment_background
		style_box.texture_margin_left = 32
		style_box.texture_margin_right = 32
		style_box.texture_margin_top = 32
		style_box.texture_margin_bottom = 32
		style_box.content_margin_left = 36
		style_box.content_margin_right = 36
		style_box.content_margin_top = 32
		style_box.content_margin_bottom = 32
		panel.add_theme_stylebox_override("panel", style_box)
	parent.add_child(panel)

	var vertical_box = VBoxContainer.new()
	vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_box.add_theme_constant_override("separation", 10)
	panel.add_child(vertical_box)

	var title_label = Label.new()
	title_label.text = "Expansions & Mods"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_result != null:
		title_label.add_theme_font_override("font", font_result)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", header_ink)
	vertical_box.add_child(title_label)

	var subtitle_label = Label.new()
	subtitle_label.text = "Later packs in load order override earlier ones"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_result != null:
		subtitle_label.add_theme_font_override("font", font_result)
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color(0.35, 0.24, 0.16))
	vertical_box.add_child(subtitle_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_box.add_child(scroll)

	_pack_list_container = VBoxContainer.new()
	_pack_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pack_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_pack_list_container)

	_pack_list_assets = assets
	_initialize_pack_order()
	_rebuild_pack_rows()

func _format_pack_tooltip(pack_info):
	var lines = [str(pack_info.name)]
	var kind_label = "Expansion Pack" if pack_info.kind == "expansion" else "Mod"
	var metadata = pack_info.get("metadata", {})
	var author = str(metadata.get("author", "")).strip_edges()
	var revision = str(metadata.get("revision", "")).strip_edges()
	var detail_parts = [kind_label]
	if revision != "":
		detail_parts.append("v" + revision)
	if author != "":
		detail_parts.append("by " + author)
	lines.append(" | ".join(detail_parts))
	var description = str(metadata.get("description", "")).strip_edges()
	if description != "":
		lines.append("")
		lines.append(description)
	var required_expansions = metadata.get("require_expansion", [])
	if typeof(required_expansions) == TYPE_ARRAY and not required_expansions.is_empty():
		lines.append("")
		lines.append("Requires: " + ", ".join(required_expansions))
	return "\n".join(lines)

func _create_reorder_button(direction, enabled, font_result, ink_color):
	var path_base = "ui/menus/arrowbutton_up" if direction < 0 else "ui/menus/arrowbutton_down"
	var normal_texture = UiHelpers.load_texture(path_base + "0.png")
	if normal_texture != null:
		var button = UiHelpers.make_texture_button({
			normal = path_base + "0.png",
			hover = path_base + "1.png",
			pressed = path_base + "2.png",
			disabled = path_base + "3.png"
		}, Vector2(28, 34))
		button.disabled = not enabled
		if not enabled:
			button.modulate = Color(1, 1, 1, 0.35)
		return button
	var fallback_button = Button.new()
	fallback_button.text = "^" if direction < 0 else "v"
	fallback_button.custom_minimum_size = Vector2(28, 34)
	fallback_button.disabled = not enabled
	if font_result != null:
		fallback_button.add_theme_font_override("font", font_result)
	fallback_button.add_theme_font_size_override("font_size", 18)
	fallback_button.add_theme_color_override("font_color", ink_color)
	OD.Chrome.attach_focus_ring(fallback_button)
	return fallback_button

func _rebuild_pack_rows(focus_pack_id = "", focus_control_kind = ""):
	if _pack_list_container == null:
		return
	for child in _pack_list_container.get_children():
		_pack_list_container.remove_child(child)
		child.queue_free()

	var dialog_assets = OD.Assets.dialog()
	var font_result = dialog_assets.font if dialog_assets != null else null
	var ink_color = Color(0.16, 0.10, 0.06)
	var sub_ink_color = Color(0.38, 0.26, 0.16)

	if _ordered_pack_ids.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No expansions or mods found."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if font_result != null:
			empty_label.add_theme_font_override("font", font_result)
		empty_label.add_theme_font_size_override("font_size", 19)
		empty_label.add_theme_color_override("font_color", ink_color)
		_pack_list_container.add_child(empty_label)
		return

	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.84, 0.77, 0.65, 0.8)
	box_style.border_color = Color(0.32, 0.20, 0.12, 1.0)
	box_style.set_border_width_all(2)

	var row_panel_style = StyleBoxFlat.new()
	row_panel_style.bg_color = Color(0.76, 0.67, 0.54, 0.35)
	row_panel_style.border_color = Color(0.45, 0.32, 0.20, 0.55)
	row_panel_style.set_border_width_all(1)
	row_panel_style.content_margin_left = 10
	row_panel_style.content_margin_right = 8
	row_panel_style.content_margin_top = 6
	row_panel_style.content_margin_bottom = 6

	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)

	var toggle_buttons = []
	var pack_count = _ordered_pack_ids.size()
	for ii in range(pack_count):
		var pack_id = _ordered_pack_ids[ii]
		var pack_info = _available_packs_by_id[pack_id]
		var is_enabled = _selected_pack_ids.has(pack_id)

		var row_panel = PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_panel.add_theme_stylebox_override("panel", row_panel_style)
		_pack_list_container.add_child(row_panel)

		var row_horizontal_box = HBoxContainer.new()
		row_horizontal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_horizontal_box.add_theme_constant_override("separation", 10)
		row_panel.add_child(row_horizontal_box)

		var order_label = Label.new()
		order_label.text = str(ii + 1) + "."
		order_label.custom_minimum_size = Vector2(26, 0)
		order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font_result != null:
			order_label.add_theme_font_override("font", font_result)
		order_label.add_theme_font_size_override("font_size", 17)
		order_label.add_theme_color_override("font_color", sub_ink_color)
		row_horizontal_box.add_child(order_label)

		var toggle_button = Button.new()
		toggle_button.toggle_mode = true
		toggle_button.button_pressed = is_enabled
		toggle_button.custom_minimum_size = Vector2(0, 38)
		toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		toggle_button.add_theme_stylebox_override("normal", transparent_style)
		toggle_button.add_theme_stylebox_override("hover", transparent_style)
		toggle_button.add_theme_stylebox_override("pressed", transparent_style)
		toggle_button.add_theme_stylebox_override("focus", transparent_style)
		OD.Chrome.attach_focus_ring(toggle_button)
		_attach_setting_tooltip(toggle_button, _format_pack_tooltip(pack_info))
		row_horizontal_box.add_child(toggle_button)
		toggle_buttons.append(toggle_button)

		var toggle_content = HBoxContainer.new()
		toggle_content.set_anchors_preset(Control.PRESET_FULL_RECT)
		toggle_content.add_theme_constant_override("separation", 10)
		toggle_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toggle_button.add_child(toggle_content)

		var check_box = PanelContainer.new()
		check_box.custom_minimum_size = Vector2(26, 26)
		check_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		check_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_box.add_theme_stylebox_override("panel", box_style)
		toggle_content.add_child(check_box)

		var mark = TextureRect.new()
		mark.texture = _pack_list_assets.textures.checkmark_small
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.visible = is_enabled
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_box.add_child(mark)

		var text_column = VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_column.add_theme_constant_override("separation", 0)
		text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toggle_content.add_child(text_column)

		var name_label = Label.new()
		name_label.text = pack_info.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if font_result != null:
			name_label.add_theme_font_override("font", font_result)
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.add_theme_color_override("font_color", ink_color)
		text_column.add_child(name_label)

		var kind_label = Label.new()
		kind_label.text = "Expansion" if pack_info.kind == "expansion" else "Mod"
		kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if font_result != null:
			kind_label.add_theme_font_override("font", font_result)
		kind_label.add_theme_font_size_override("font_size", 13)
		kind_label.add_theme_color_override("font_color", sub_ink_color)
		text_column.add_child(kind_label)

		toggle_button.toggled.connect(func(pressed_state):
			mark.visible = pressed_state
			_on_pack_toggled(pressed_state, pack_id)
		)

		var up_button = _create_reorder_button(-1, ii > 0, font_result, ink_color)
		up_button.pressed.connect(func(): _move_pack(ii, -1))
		row_horizontal_box.add_child(up_button)

		var down_button = _create_reorder_button(1, ii < pack_count - 1, font_result, ink_color)
		down_button.pressed.connect(func(): _move_pack(ii, 1))
		row_horizontal_box.add_child(down_button)

		if pack_id == focus_pack_id:
			if focus_control_kind == "up" and not up_button.disabled:
				up_button.call_deferred("grab_focus")
			elif focus_control_kind == "down" and not down_button.disabled:
				down_button.call_deferred("grab_focus")
			else:
				toggle_button.call_deferred("grab_focus")

	if not toggle_buttons.is_empty():
		for left_button in _left_buttons:
			left_button.focus_neighbor_right = left_button.get_path_to(toggle_buttons[0])
		for toggle_button in toggle_buttons:
			toggle_button.focus_neighbor_left = toggle_button.get_path_to(_left_buttons[0])

func _move_pack(from_index, direction):
	var to_index = from_index + direction
	if to_index < 0 or to_index >= _ordered_pack_ids.size():
		return
	var moved_pack_id = _ordered_pack_ids[from_index]
	_ordered_pack_ids[from_index] = _ordered_pack_ids[to_index]
	_ordered_pack_ids[to_index] = moved_pack_id
	_sync_selected_pack_order()
	var focus_kind = "up" if direction < 0 else "down"
	_rebuild_pack_rows(moved_pack_id, focus_kind)

func _on_pack_toggled(enabled, pack_id):
	if enabled:
		if not _selected_pack_ids.has(pack_id):
			_selected_pack_ids.append(pack_id)
	else:
		_selected_pack_ids.erase(pack_id)
	_sync_selected_pack_order()

func _on_DoneButton_pressed():
	OD.Database.set_active_packs(_selected_pack_ids)
	OD.Scenes.goto(OD.Scenes.SKILLS_MENU)

func _on_BackButton_pressed():
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)

func _select_difficulty(mode):
	_easy_checkmark.visible = mode == OD.DungeonSettings.Difficulty.Easy
	_medium_checkmark.visible = mode == OD.DungeonSettings.Difficulty.Medium
	_hard_checkmark.visible = mode == OD.DungeonSettings.Difficulty.Hard
	OD.DungeonSettings.set_difficulty(mode)

func _on_EasyDifficultyButton_pressed():
	_select_difficulty(OD.DungeonSettings.Difficulty.Easy)
	
func _on_MediumDifficultyButton_pressed():
	_select_difficulty(OD.DungeonSettings.Difficulty.Medium)
	
func _on_HardDifficultyButton_pressed():
	_select_difficulty(OD.DungeonSettings.Difficulty.Hard)

func _on_PermadeathButton_pressed():
	_permadeath_enabled = !_permadeath_enabled
	_permadeath_checkmark.visible = _permadeath_enabled
	OD.DungeonSettings.set_permadeath(_permadeath_enabled)
	
func _on_NoTimeToGrindButton_pressed():
	_no_time_to_grind_enabled = !_no_time_to_grind_enabled
	_no_time_to_grind_checkmark.visible = _no_time_to_grind_enabled
	OD.DungeonSettings.set_no_time_to_grind(_no_time_to_grind_enabled)
