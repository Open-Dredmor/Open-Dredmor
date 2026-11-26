extends Control

const SaveManagerScript = preload("res://script/instance/save_manager.gd")

static func init_container():
	return Control.new()

const SAVES_DIR = SaveManagerScript.SAVES_DIR

var _saves = []
var _selected_index = -1
var _save_list = null
var _details_label = null
var _load_button = null
var _delete_button = null

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	var assets = OD.Assets.load_game_menu()
	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.size = Vector2(OD.Settings.display_size().x, header_background.texture.get_height())
	container.add_child(header_background)

	var back_button = OD.Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.offset_left = 0
	back_button.offset_top = 0
	back_button.pressed.connect(_on_BackButton_pressed)
	container.add_child(back_button)

	var header_text = TextureRect.new()
	header_text.texture = assets.textures.load_header
	header_text.anchor_left = 0.5
	header_text.offset_left = -(header_text.texture.get_width() / 2)
	container.add_child(header_text)

	_load_button = OD.Chrome.button(assets.textures.done_button)
	_load_button.anchor_left = 1
	_load_button.anchor_top = 0
	_load_button.offset_left = -_load_button.texture_normal.get_width()
	_load_button.offset_top = 0
	_load_button.visible = false
	_load_button.pressed.connect(_on_LoadButton_pressed)
	container.add_child(_load_button)

	var content_row = HBoxContainer.new()
	content_row.anchor_left = 0.1
	content_row.anchor_top = 0.22
	content_row.anchor_right = 0.9
	content_row.anchor_bottom = 0.88
	content_row.add_theme_constant_override("separation", 32)
	container.add_child(content_row)

	_save_list = ItemList.new()
	_save_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_save_list.add_theme_font_override("font", assets.fonts.default)
	_save_list.add_theme_font_size_override("font_size", 24)
	_save_list.item_selected.connect(_on_save_selected)
	_save_list.item_activated.connect(_on_save_activated)
	content_row.add_child(_save_list)

	var info_panel = TextureRect.new()
	info_panel.texture = assets.textures.info_panel
	info_panel.custom_minimum_size = Vector2(info_panel.texture.get_width(), info_panel.texture.get_height())
	content_row.add_child(info_panel)

	var info_vertical_box = VBoxContainer.new()
	info_vertical_box.anchor_right = 1.0
	info_vertical_box.anchor_bottom = 1.0
	info_vertical_box.offset_left = 24
	info_vertical_box.offset_top = 24
	info_vertical_box.offset_right = -24
	info_vertical_box.offset_bottom = -24
	info_vertical_box.add_theme_constant_override("separation", 16)
	info_panel.add_child(info_vertical_box)

	_details_label = Label.new()
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_override("font", assets.fonts.default)
	_details_label.add_theme_font_size_override("font_size", 22)
	_details_label.add_theme_color_override("font_color", Color(0, 0, 0))
	info_vertical_box.add_child(_details_label)

	_delete_button = OD.Chrome.button(assets.textures.delete_button)
	_delete_button.visible = false
	_delete_button.pressed.connect(_on_DeleteButton_pressed)
	info_vertical_box.add_child(_delete_button)

	_refresh_saves()
	OD.Chrome.attach_focus_ring(_save_list)
	if _saves.size() > 0:
		_save_list.call_deferred("grab_focus")
	else:
		back_button.call_deferred("grab_focus")

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
	_save_list.clear()
	for save_entry in _saves:
		_save_list.add_item(save_entry.label)
	if _saves.size() > 0:
		_save_list.select(0)
		_on_save_selected(0)
	else:
		_load_button.visible = false
		_delete_button.visible = false
		_details_label.text = "No saved games found in " + SAVES_DIR

func _on_save_selected(index):
	if index < 0 or index >= _saves.size():
		return
	_selected_index = index
	_details_label.text = _saves[index].details
	_load_button.visible = true
	_delete_button.visible = true

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
		_details_label.text = "Failed to load save: " + str(loaded.get("error", "Unknown error"))
		return
	SaveManagerScript.restore_run_settings(loaded.data, save_path)
	OD.Scenes.goto(OD.Scenes.GAME)

func _on_BackButton_pressed():
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)
