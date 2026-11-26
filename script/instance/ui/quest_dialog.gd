extends CanvasLayer

class_name QuestDialog

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const QUEST_BACKGROUND_TEXTURE = "ui/gameplay/panel_quest_bg.png"
const INPROGRESS_TEXTURES = {
	normal = "ui/gameplay/panel_quest_inprogress0.png",
	hover = "ui/gameplay/panel_quest_inprogress1.png",
	pressed = "ui/gameplay/panel_quest_inprogress1.png"
}
const COMPLETED_TEXTURES = {
	normal = "ui/gameplay/panel_quest_completed0.png",
	hover = "ui/gameplay/panel_quest_completed1.png",
	pressed = "ui/gameplay/panel_quest_completed1.png"
}
const CLOSE_BUTTON_TEXTURES = {
	normal = "ui/gameplay/xclose_copper0.png",
	hover = "ui/gameplay/xclose_copper1.png",
	pressed = "ui/gameplay/xclose_copper2.png"
}
const CHECK_BLANK_TEXTURE = "ui/panel_quest_checkbox_blank.png"
const CHECK_DONE_TEXTURE = "ui/panel_quest_checkbox_checked.png"

var _player = null
var _callbacks = {}
var _active_tab = "active"

var _window = null
var _panel = null
var _list_box = null
var _inprogress_button = null
var _completed_button = null

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
	var viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_panel_bounds):
		viewport.size_changed.connect(_update_panel_bounds)

func _create_panel_style():
	var background_texture = UiHelpers.load_texture(QUEST_BACKGROUND_TEXTURE)
	return UiHelpers.create_panel_style(
		background_texture,
		44,
		{ left = 36, right = 36, top = 34, bottom = 34 }
	)

func _build_ui():
	var base_size = Vector2(504.0, 496.0)
	_window = UiHelpers.create_floating_window(self, base_size)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	_window.get_content_root().add_child(_panel)

	var root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 10)
	_panel.add_child(root_box)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_box.add_child(header)

	var title_label = Label.new()
	title_label.text = "Quest Log"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiHelpers.style_label(title_label, 24, Color(0.22, 0.14, 0.08))
	header.add_child(title_label)

	_inprogress_button = UiHelpers.make_texture_button(INPROGRESS_TEXTURES, Vector2(78, 28))
	_inprogress_button.tooltip_text = "In Progress Quests"
	_inprogress_button.pressed.connect(func(): _switch_tab("active"))
	header.add_child(_inprogress_button)

	_completed_button = UiHelpers.make_texture_button(COMPLETED_TEXTURES, Vector2(78, 28))
	_completed_button.tooltip_text = "Completed Quests"
	_completed_button.pressed.connect(func(): _switch_tab("completed"))
	header.add_child(_completed_button)

	var close_button = UiHelpers.make_texture_button(CLOSE_BUTTON_TEXTURES, Vector2(22, 22))
	close_button.pressed.connect(dismiss)
	header.add_child(close_button)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)

func _update_panel_bounds():
	if _window != null and is_instance_valid(_window):
		_window.clamp_to_viewport()

func _switch_tab(tab_name):
	_active_tab = tab_name
	refresh()

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and not event.echo:
		if event.keycode == KEY_Q:
			dismiss()
			get_viewport().set_input_as_handled()

func get_floating_window():
	return _window

func dismiss():
	UiHelpers.invoke_callback(_callbacks, "on_close")
	queue_free()

func refresh():
	if _list_box == null or not is_instance_valid(_list_box):
		return
	if _inprogress_button != null:
		_inprogress_button.modulate = Color(1, 1, 1, 1) if _active_tab == "active" else Color(0.65, 0.65, 0.65, 0.85)
	if _completed_button != null:
		_completed_button.modulate = Color(1, 1, 1, 1) if _active_tab == "completed" else Color(0.65, 0.65, 0.65, 0.85)

	UiHelpers.clear_children(_list_box)

	var quests = []
	if _player != null:
		if _active_tab == "active" and _player.has_method("get_active_quests"):
			quests = _player.get_active_quests()
		elif _active_tab == "completed" and _player.has_method("get_completed_quests"):
			quests = _player.get_completed_quests()

	if quests.is_empty():
		var empty_label = Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _active_tab == "active":
			empty_label.text = "No active quests.\nSeek out a Statue of Inconsequentia in the dungeon to receive a task!"
		else:
			empty_label.text = "No completed quests yet."
		UiHelpers.style_label(empty_label, 16, Color(0.28, 0.18, 0.10))
		_list_box.add_child(empty_label)
		return

	var check_texture = UiHelpers.load_texture(CHECK_DONE_TEXTURE if _active_tab == "completed" else CHECK_BLANK_TEXTURE)
	for quest in quests:
		_add_quest_card(quest, check_texture)

func _add_quest_card(quest, check_texture):
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.92, 0.86, 0.74, 0.55)
	card_style.border_color = Color(0.45, 0.34, 0.20, 0.7)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	_list_box.add_child(card)

	var row_box = HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 10)
	card.add_child(row_box)

	if check_texture != null:
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = check_texture
		row_box.add_child(icon_rect)

	var info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 3)
	row_box.add_child(info_box)

	var title_label = Label.new()
	title_label.text = str(quest.get("title", "Quest"))
	UiHelpers.style_label(title_label, 17, Color(0.20, 0.12, 0.06))
	info_box.add_child(title_label)

	var progress = int(quest.get("progress", 0))
	var target = int(quest.get("target", 1))
	var meta_label = Label.new()
	meta_label.text = "From: " + str(quest.get("giver", "Inconsequentia")) + "  |  Progress: " + str(progress) + "/" + str(target)
	UiHelpers.style_label(meta_label, 13, Color(0.42, 0.24, 0.08))
	info_box.add_child(meta_label)

	var description_text = str(quest.get("description", ""))
	if description_text != "":
		var description_label = Label.new()
		description_label.text = description_text
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiHelpers.style_label(description_label, 14, Color(0.28, 0.18, 0.10))
		info_box.add_child(description_label)

	var reward_parts = []
	if int(quest.get("reward_xp", 0)) > 0:
		reward_parts.append(str(quest.get("reward_xp")) + " XP")
	if int(quest.get("reward_zorkmids", 0)) > 0:
		reward_parts.append(str(quest.get("reward_zorkmids")) + " Zorkmids")
	if not reward_parts.is_empty():
		var reward_label = Label.new()
		reward_label.text = "Reward: " + ", ".join(reward_parts)
		UiHelpers.style_label(reward_label, 13, Color(0.18, 0.36, 0.12))
		info_box.add_child(reward_label)
