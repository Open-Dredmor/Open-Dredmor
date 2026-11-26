extends Control

const SaveManagerScript = preload("res://script/instance/save_manager.gd")

static func init_container():
	return Control.new()

const SAVES_DIR = SaveManagerScript.SAVES_DIR

const SKILL_SLOT_POSITIONS = [
	Vector2(446, 422),
	Vector2(522, 422),
	Vector2(598, 422),
	Vector2(674, 422),
	Vector2(483, 498),
	Vector2(559, 498),
	Vector2(635, 498)
]

var _saves = []
var _selected_index = -1
var _assets = null
var _book_list_box = null
var _book_buttons = []
var _thumbnail_texture = null
var _fallback_preview_box = null
var _portrait_texture = null
var _details_label = null
var _title_label = null
var _skill_icon_rects = []
var _load_button = null
var _delete_button = null
var _back_button = null

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	_assets = OD.Assets.load_game_menu()
	var container = get_node("/root/Container")
	var display_size = OD.Settings.display_size()
	container.set_size(display_size)

	if _assets.textures.stone_tile != null:
		var background_tile = TextureRect.new()
		background_tile.texture = _assets.textures.stone_tile
		background_tile.stretch_mode = TextureRect.STRETCH_TILE
		background_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		container.add_child(background_tile)

	var header_background = TextureRect.new()
	header_background.texture = _assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	var header_height = header_background.texture.get_height()
	header_background.size = Vector2(display_size.x, header_height)
	container.add_child(header_background)

	_back_button = OD.Chrome.button(_assets.textures.back_button)
	_back_button.anchor_left = 0
	_back_button.anchor_top = 0
	_back_button.offset_left = 0
	_back_button.offset_top = 0
	_back_button.pressed.connect(_on_BackButton_pressed)
	container.add_child(_back_button)

	var header_text = TextureRect.new()
	header_text.texture = _assets.textures.load_header
	header_text.anchor_left = 0.5
	header_text.offset_left = -(header_text.texture.get_width() / 2)
	container.add_child(header_text)

	_load_button = OD.Chrome.button(_assets.textures.done_button)
	_load_button.anchor_left = 1
	_load_button.anchor_top = 0
	_load_button.offset_left = -_load_button.texture_normal.get_width()
	_load_button.offset_top = 0
	_load_button.visible = false
	_load_button.pressed.connect(_on_LoadButton_pressed)
	container.add_child(_load_button)

	var center_wrapper = CenterContainer.new()
	center_wrapper.anchor_left = 0.0
	center_wrapper.anchor_top = 0.0
	center_wrapper.anchor_right = 1.0
	center_wrapper.anchor_bottom = 1.0
	center_wrapper.offset_top = header_height + 12
	center_wrapper.offset_bottom = -12
	center_wrapper.offset_left = 16
	center_wrapper.offset_right = -16
	container.add_child(center_wrapper)

	var frame_width = _assets.textures.painting_frame.get_width() if _assets.textures.painting_frame != null else 832
	var frame_height = _assets.textures.painting_frame.get_height() if _assets.textures.painting_frame != null else 632

	var painting_frame = TextureRect.new()
	painting_frame.texture = _assets.textures.painting_frame
	painting_frame.custom_minimum_size = Vector2(frame_width, frame_height)
	painting_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	painting_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_wrapper.add_child(painting_frame)

	var widgets_width = _assets.textures.widgets.get_width() if _assets.textures.widgets != null else 800
	var widgets_height = _assets.textures.widgets.get_height() if _assets.textures.widgets != null else 600

	var widgets_panel = TextureRect.new()
	widgets_panel.texture = _assets.textures.widgets
	widgets_panel.position = Vector2((frame_width - widgets_width) * 0.5, (frame_height - widgets_height) * 0.5)
	widgets_panel.size = Vector2(widgets_width, widgets_height)
	painting_frame.add_child(widgets_panel)

	var books_scroll = ScrollContainer.new()
	books_scroll.position = Vector2(8, 28)
	books_scroll.size = Vector2(404, 544)
	books_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	books_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	books_scroll.follow_focus = true
	widgets_panel.add_child(books_scroll)

	_book_list_box = VBoxContainer.new()
	_book_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_list_box.add_theme_constant_override("separation", 4)
	books_scroll.add_child(_book_list_box)

	var preview_container = Control.new()
	preview_container.position = Vector2(414, 102)
	preview_container.size = Vector2(364, 244)
	widgets_panel.add_child(preview_container)

	_thumbnail_texture = TextureRect.new()
	_thumbnail_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_thumbnail_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumbnail_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_thumbnail_texture.visible = false
	preview_container.add_child(_thumbnail_texture)

	_fallback_preview_box = HBoxContainer.new()
	_fallback_preview_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fallback_preview_box.offset_left = 14
	_fallback_preview_box.offset_top = 14
	_fallback_preview_box.offset_right = -14
	_fallback_preview_box.offset_bottom = -14
	_fallback_preview_box.add_theme_constant_override("separation", 14)
	preview_container.add_child(_fallback_preview_box)

	_portrait_texture = TextureRect.new()
	_portrait_texture.custom_minimum_size = Vector2(100, 100)
	_portrait_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fallback_preview_box.add_child(_portrait_texture)

	_details_label = Label.new()
	_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_override("font", _assets.fonts.default)
	_details_label.add_theme_font_size_override("font_size", 19)
	_details_label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.80))
	_fallback_preview_box.add_child(_details_label)

	_title_label = Label.new()
	_title_label.position = Vector2(424, 368)
	_title_label.size = Vector2(344, 36)
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.clip_text = true
	_title_label.add_theme_font_override("font", _assets.fonts.default)
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(0.14, 0.10, 0.06))
	widgets_panel.add_child(_title_label)

	_skill_icon_rects.clear()
	for slot_position in SKILL_SLOT_POSITIONS:
		var icon_rect = TextureRect.new()
		icon_rect.position = slot_position
		icon_rect.size = Vector2(64, 64)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		widgets_panel.add_child(icon_rect)
		_skill_icon_rects.append(icon_rect)

	_delete_button = OD.Chrome.button(_assets.textures.delete_button)
	var delete_width = _delete_button.texture_normal.get_width() if _delete_button.texture_normal != null else 105
	_delete_button.position = Vector2(595.0 - delete_width * 0.5, 586.0)
	_delete_button.visible = false
	_delete_button.pressed.connect(_on_DeleteButton_pressed)
	widgets_panel.add_child(_delete_button)

	_refresh_saves()

func _unhandled_input(event):
	if (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_BackButton_pressed()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_Y and _delete_button != null and _delete_button.visible:
			get_viewport().set_input_as_handled()
			_on_DeleteButton_pressed()
		elif event.button_index == JOY_BUTTON_START and _load_button != null and _load_button.visible:
			get_viewport().set_input_as_handled()
			_on_LoadButton_pressed()

func _refresh_saves():
	_saves = SaveManagerScript.list_saves(SAVES_DIR)
	_selected_index = -1
	_book_buttons.clear()
	for child in _book_list_box.get_children():
		_book_list_box.remove_child(child)
		child.queue_free()

	for ii in range(_saves.size()):
		var save_entry = _saves[ii]
		var book_button = TextureButton.new()
		book_button.texture_normal = _assets.textures.book_normal
		book_button.texture_hover = _assets.textures.book_hover
		book_button.texture_pressed = _assets.textures.book_hover
		book_button.texture_focused = _assets.textures.book_hover
		book_button.custom_minimum_size = Vector2(400, 64)
		book_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		OD.Chrome.attach_focus_ring(book_button)

		var book_label = Label.new()
		book_label.text = save_entry.name + " the Adventurer"
		book_label.anchor_left = 0.0
		book_label.anchor_top = 0.0
		book_label.anchor_right = 1.0
		book_label.anchor_bottom = 1.0
		book_label.offset_left = 74
		book_label.offset_right = -74
		book_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		book_label.clip_text = true
		book_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		book_label.add_theme_font_override("font", _assets.fonts.default)
		book_label.add_theme_font_size_override("font_size", 21)
		book_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
		book_label.add_theme_constant_override("outline_size", 2)
		book_label.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.03, 0.9))
		book_button.add_child(book_label)

		var save_index = ii
		book_button.pressed.connect(func():
			if _selected_index == save_index:
				_on_LoadButton_pressed()
			else:
				_on_save_selected(save_index)
		)
		book_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
				_on_save_activated(save_index)
		)
		_book_list_box.add_child(book_button)
		_book_buttons.append(book_button)

	for ii in range(_book_buttons.size()):
		var current_button = _book_buttons[ii]
		if ii > 0:
			current_button.focus_neighbor_top = current_button.get_path_to(_book_buttons[ii - 1])
		else:
			current_button.focus_neighbor_top = current_button.get_path_to(_back_button)
		if ii < _book_buttons.size() - 1:
			current_button.focus_neighbor_bottom = current_button.get_path_to(_book_buttons[ii + 1])

	if _saves.size() > 0:
		_on_save_selected(0)
		_book_buttons[0].call_deferred("grab_focus")
	else:
		_load_button.visible = false
		_delete_button.visible = false
		_thumbnail_texture.visible = false
		_fallback_preview_box.visible = true
		_portrait_texture.texture = null
		_title_label.text = "No Saved Games"
		_details_label.text = "No saved games found in " + SAVES_DIR
		_clear_skill_icons()
		_back_button.call_deferred("grab_focus")

func _clear_skill_icons():
	for icon_rect in _skill_icon_rects:
		icon_rect.texture = null
		icon_rect.tooltip_text = ""

func _resolve_skill_for_save(skill_entry):
	if OD.Database == null:
		return null
	if typeof(skill_entry) == TYPE_DICTIONARY:
		var skill_name = str(skill_entry.get("name", ""))
		if skill_name != "" and OD.Database.has_method("get_skill_by_name"):
			var by_name = OD.Database.get_skill_by_name(skill_name)
			if by_name != null:
				return by_name
		var skill_id = int(skill_entry.get("id", -1))
		if skill_id >= 0 and OD.Database.has_method("get_skill"):
			return OD.Database.get_skill(skill_id)
	elif typeof(skill_entry) == TYPE_INT or typeof(skill_entry) == TYPE_FLOAT:
		if OD.Database.has_method("get_skill"):
			return OD.Database.get_skill(int(skill_entry))
	return null

func _update_skill_icons(save_entry):
	_clear_skill_icons()
	var entries = save_entry.get("skill_entries", [])
	if entries.is_empty():
		entries = save_entry.get("starting_skill_ids", [])
	var slot_limit = min(entries.size(), _skill_icon_rects.size())
	for ii in range(slot_limit):
		var skill_data = _resolve_skill_for_save(entries[ii])
		if skill_data == null:
			continue
		var icon_path = str(skill_data.get("icon", ""))
		if icon_path != "" and OD.Load.exists(icon_path):
			_skill_icon_rects[ii].texture = OD.Load.image(icon_path)
		_skill_icon_rects[ii].tooltip_text = str(skill_data.get("name", ""))

func _on_save_selected(index):
	if index < 0 or index >= _saves.size():
		return
	_selected_index = index
	for ii in range(_book_buttons.size()):
		_book_buttons[ii].texture_normal = _assets.textures.book_hover if ii == index else _assets.textures.book_normal

	var save_entry = _saves[index]
	_title_label.text = save_entry.name + " the Adventurer"
	_load_button.visible = true
	_delete_button.visible = true

	var thumb_path = str(save_entry.get("thumbnail_path", ""))
	if thumb_path != "" and FileAccess.file_exists(thumb_path):
		var thumb_image = Image.load_from_file(thumb_path)
		if thumb_image != null and not thumb_image.is_empty():
			_thumbnail_texture.texture = ImageTexture.create_from_image(thumb_image)
			_thumbnail_texture.visible = true
			_fallback_preview_box.visible = false
		else:
			_show_fallback_preview(save_entry)
	else:
		_show_fallback_preview(save_entry)

	_update_skill_icons(save_entry)

func _show_fallback_preview(save_entry):
	_thumbnail_texture.visible = false
	_fallback_preview_box.visible = true
	var portrait_path = "ui/portrait/portraitf_100_stare.png" if str(save_entry.get("hero", "hero")) == "heroine" else "ui/portrait/portrait_100_stare.png"
	_portrait_texture.texture = OD.Load.image(portrait_path) if OD.Load.exists(portrait_path) else null
	_details_label.text = save_entry.details

func _on_DeleteButton_pressed():
	if _selected_index < 0 or _selected_index >= _saves.size():
		return
	DirAccess.remove_absolute(_saves[_selected_index].path)
	_refresh_saves()

func _on_save_activated(index):
	_on_save_selected(index)
	_on_LoadButton_pressed()

func _on_LoadButton_pressed():
	if _selected_index < 0 or _selected_index >= _saves.size():
		return
	var save_path = _saves[_selected_index].path
	var loaded = SaveManagerScript.load_save_file(save_path)
	if not loaded.ok:
		_show_fallback_preview(_saves[_selected_index])
		_details_label.text = "Failed to load save: " + str(loaded.get("error", "Unknown error"))
		return
	SaveManagerScript.restore_run_settings(loaded.data, save_path)
	OD.Scenes.goto(OD.Scenes.GAME)

func _on_BackButton_pressed():
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)
