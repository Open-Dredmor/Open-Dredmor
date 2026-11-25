extends CanvasLayer

class_name QuestDialog

const QUEST_BG_TEX = "ui/gameplay/panel_quest_bg.png"
const INPROGRESS_TEXS = {
	normal = "ui/gameplay/panel_quest_inprogress0.png",
	hover = "ui/gameplay/panel_quest_inprogress1.png",
	pressed = "ui/gameplay/panel_quest_inprogress1.png"
}
const COMPLETED_TEXS = {
	normal = "ui/gameplay/panel_quest_completed0.png",
	hover = "ui/gameplay/panel_quest_completed1.png",
	pressed = "ui/gameplay/panel_quest_completed1.png"
}
const CLOSE_BTN_TEXS = {
	normal = "ui/gameplay/xclose_copper0.png",
	hover = "ui/gameplay/xclose_copper1.png",
	pressed = "ui/gameplay/xclose_copper2.png"
}
const CHECK_BLANK_TEX = "ui/panel_quest_checkbox_blank.png"
const CHECK_DONE_TEX = "ui/panel_quest_checkbox_checked.png"

const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)

var _player = null
var _callbacks = {}
var _active_tab = "active"

var _panel = null
var _list_vbox = null
var _inprogress_btn = null
var _completed_btn = null

func init(player, callbacks = {}):
	_player = player
	_callbacks = callbacks
	layer = 12
	_build_ui()
	_connect_signals()
	refresh()
	return self

func _connect_signals():
	if _player != null and _player.has_signal("quests_changed") and not _player.quests_changed.is_connected(refresh):
		_player.quests_changed.connect(refresh)
	var vp = get_viewport()
	if vp != null and not vp.size_changed.is_connected(_update_panel_bounds):
		vp.size_changed.connect(_update_panel_bounds)

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
	var bg_tex = _load_tex(QUEST_BG_TEX)
	if bg_tex != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = bg_tex
		style_box.texture_margin_left = 44
		style_box.texture_margin_right = 44
		style_box.texture_margin_top = 44
		style_box.texture_margin_bottom = 44
		style_box.content_margin_left = 36
		style_box.content_margin_right = 36
		style_box.content_margin_top = 34
		style_box.content_margin_bottom = 34
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = Color(0.16, 0.13, 0.10, 0.96)
	fallback.border_color = Color(0.62, 0.50, 0.32, 0.95)
	fallback.set_border_width_all(3)
	fallback.set_content_margin_all(28)
	return fallback

func _build_ui():
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(_panel)
	_update_panel_bounds()

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(root_vbox)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = "Quest Log"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(title_lbl, 24, Color(0.22, 0.14, 0.08))
	header.add_child(title_lbl)

	_inprogress_btn = _make_texture_button(INPROGRESS_TEXS, Vector2(78, 28))
	_inprogress_btn.tooltip_text = "In Progress Quests"
	_inprogress_btn.pressed.connect(func(): _switch_tab("active"))
	header.add_child(_inprogress_btn)

	_completed_btn = _make_texture_button(COMPLETED_TEXS, Vector2(78, 28))
	_completed_btn.tooltip_text = "Completed Quests"
	_completed_btn.pressed.connect(func(): _switch_tab("completed"))
	header.add_child(_completed_btn)

	var close_btn = _make_texture_button(CLOSE_BTN_TEXS, Vector2(22, 22))
	close_btn.pressed.connect(dismiss)
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_vbox)

func _update_panel_bounds():
	if _panel == null or not is_instance_valid(_panel):
		return
	var vp_size = _get_viewport_size()
	var panel_w = clamp(vp_size.x * 0.46, 440.0, 620.0)
	var panel_h = clamp(vp_size.y * 0.72, 420.0, 580.0)
	_panel.custom_minimum_size = Vector2(panel_w, panel_h)

func _switch_tab(tab_name):
	_active_tab = tab_name
	refresh()

func _unhandled_input(ev):
	if ev is InputEventKey and ev.is_pressed() and not ev.echo:
		if ev.keycode == KEY_ESCAPE or ev.keycode == KEY_Q:
			dismiss()
			get_viewport().set_input_as_handled()

func dismiss():
	if _callbacks.has("on_close") and _callbacks.on_close.is_valid():
		_callbacks.on_close.call()
	queue_free()

func refresh():
	if _list_vbox == null or not is_instance_valid(_list_vbox):
		return
	if _inprogress_btn != null:
		_inprogress_btn.modulate = Color(1, 1, 1, 1) if _active_tab == "active" else Color(0.65, 0.65, 0.65, 0.85)
	if _completed_btn != null:
		_completed_btn.modulate = Color(1, 1, 1, 1) if _active_tab == "completed" else Color(0.65, 0.65, 0.65, 0.85)

	for child in _list_vbox.get_children():
		_list_vbox.remove_child(child)
		child.queue_free()

	var quests = []
	if _player != null:
		if _active_tab == "active" and _player.has_method("get_active_quests"):
			quests = _player.get_active_quests()
		elif _active_tab == "completed" and _player.has_method("get_completed_quests"):
			quests = _player.get_completed_quests()

	if quests.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _active_tab == "active":
			empty_lbl.text = "No active quests.\nSeek out a Statue of Inconsequentia in the dungeon to receive a task!"
		else:
			empty_lbl.text = "No completed quests yet."
		_style_label(empty_lbl, 16, Color(0.28, 0.18, 0.10))
		_list_vbox.add_child(empty_lbl)
		return

	var check_tex = _load_tex(CHECK_DONE_TEX if _active_tab == "completed" else CHECK_BLANK_TEX)
	for quest in quests:
		_add_quest_card(quest, check_tex)

func _add_quest_card(quest, check_tex):
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.92, 0.86, 0.74, 0.55)
	card_style.border_color = Color(0.45, 0.34, 0.20, 0.7)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	_list_vbox.add_child(card)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	if check_tex != null:
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = check_tex
		hbox.add_child(icon_rect)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	var title_lbl = Label.new()
	title_lbl.text = str(quest.get("title", "Quest"))
	_style_label(title_lbl, 17, Color(0.20, 0.12, 0.06))
	info_vbox.add_child(title_lbl)

	var progress = int(quest.get("progress", 0))
	var target = int(quest.get("target", 1))
	var meta_lbl = Label.new()
	meta_lbl.text = "From: " + str(quest.get("giver", "Inconsequentia")) + "  |  Progress: " + str(progress) + "/" + str(target)
	_style_label(meta_lbl, 13, Color(0.42, 0.24, 0.08))
	info_vbox.add_child(meta_lbl)

	var desc_text = str(quest.get("description", ""))
	if desc_text != "":
		var desc_lbl = Label.new()
		desc_lbl.text = desc_text
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(desc_lbl, 14, Color(0.28, 0.18, 0.10))
		info_vbox.add_child(desc_lbl)

	var reward_parts = []
	if int(quest.get("reward_xp", 0)) > 0:
		reward_parts.append(str(quest.get("reward_xp")) + " XP")
	if int(quest.get("reward_zorkmids", 0)) > 0:
		reward_parts.append(str(quest.get("reward_zorkmids")) + " Zorkmids")
	if not reward_parts.is_empty():
		var reward_lbl = Label.new()
		reward_lbl.text = "Reward: " + ", ".join(reward_parts)
		_style_label(reward_lbl, 13, Color(0.18, 0.36, 0.12))
		info_vbox.add_child(reward_lbl)
