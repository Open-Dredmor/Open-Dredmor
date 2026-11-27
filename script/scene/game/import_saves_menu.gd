extends Control

const RetailSaveImporterScript = preload("res://script/instance/retail_save_importer.gd")

static func init_container():
	return Control.new()

const INK_COLOR = Color(0.16, 0.10, 0.06)
const MUTED_INK = Color(0.32, 0.22, 0.14)

var _saves = []
var _selected_index = -1
var _save_tree = null
var _directory_input = null
var _status_label = null
var _details_label = null
var _thumb_frame = null
var _thumb_rect = null
var _import_one_button = null
var _import_batch_button = null
var _select_all_button = null
var _done_button = null
var _font_result = null
var _blank_texture = null

func _ready():
	call_deferred("_build_gui")

func _exit_tree():
	var window = get_window()
	if window != null and window.files_dropped.is_connected(_on_files_dropped):
		window.files_dropped.disconnect(_on_files_dropped)

func _create_parchment_panel_style(background_texture):
	if background_texture != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = background_texture
		style_box.texture_margin_left = 32
		style_box.texture_margin_right = 32
		style_box.texture_margin_top = 32
		style_box.texture_margin_bottom = 32
		style_box.content_margin_left = 36
		style_box.content_margin_right = 36
		style_box.content_margin_top = 32
		style_box.content_margin_bottom = 32
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = Color(0.86, 0.79, 0.67, 1.0)
	fallback.border_color = Color(0.45, 0.34, 0.24, 1.0)
	fallback.set_border_width_all(3)
	fallback.set_content_margin_all(24)
	return fallback

func _create_inset_style():
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.78, 0.70, 0.57, 0.7)
	box.border_color = Color(0.46, 0.35, 0.24, 0.9)
	box.set_border_width_all(2)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func _style_tree(tree_control):
	var panel_box = StyleBoxFlat.new()
	panel_box.bg_color = Color(0.79, 0.71, 0.58, 0.55)
	panel_box.border_color = Color(0.45, 0.34, 0.24, 0.85)
	panel_box.set_border_width_all(2)
	panel_box.set_content_margin_all(6)

	var selected_box = StyleBoxFlat.new()
	selected_box.bg_color = Color(0.58, 0.42, 0.24, 0.45)
	selected_box.border_color = Color(0.38, 0.26, 0.14, 0.8)
	selected_box.set_border_width_all(1)

	var header_box = StyleBoxFlat.new()
	header_box.bg_color = Color(0.68, 0.58, 0.44, 0.9)
	header_box.border_color = Color(0.42, 0.30, 0.20, 0.9)
	header_box.set_border_width_all(1)
	header_box.content_margin_left = 8
	header_box.content_margin_right = 8
	header_box.content_margin_top = 4
	header_box.content_margin_bottom = 4

	tree_control.add_theme_stylebox_override("panel", panel_box)
	tree_control.add_theme_stylebox_override("focus", panel_box)
	tree_control.add_theme_stylebox_override("selected", selected_box)
	tree_control.add_theme_stylebox_override("selected_focus", selected_box)
	tree_control.add_theme_stylebox_override("title_button_normal", header_box)
	tree_control.add_theme_stylebox_override("title_button_hover", header_box)
	tree_control.add_theme_stylebox_override("title_button_pressed", header_box)
	tree_control.add_theme_color_override("font_color", INK_COLOR)
	tree_control.add_theme_color_override("font_selected_color", Color(0.10, 0.05, 0.02))
	tree_control.add_theme_color_override("title_button_color", INK_COLOR)
	tree_control.add_theme_color_override("guide_color", Color(0.45, 0.34, 0.24, 0.35))

func _build_gui():
	var assets = OD.Assets.load_game_menu()
	var dialog_assets = OD.Assets.dialog()
	_font_result = dialog_assets.font if dialog_assets != null and dialog_assets.font != null else assets.fonts.default
	_blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var parchment_background = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())

	if OD.Load.exists("ui/menus/bg_stonetile.png"):
		var background_tile = TextureRect.new()
		background_tile.texture = OD.Load.image("ui/menus/bg_stonetile.png")
		background_tile.stretch_mode = TextureRect.STRETCH_TILE
		background_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		container.add_child(background_tile)

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
	back_button.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.MAIN_MENU))
	container.add_child(back_button)

	var title_label = Label.new()
	title_label.text = "Import Retail Saves"
	title_label.anchor_left = 0.5
	title_label.offset_left = -200
	title_label.offset_top = 12
	title_label.custom_minimum_size = Vector2(400, 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", _font_result)
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03))
	container.add_child(title_label)

	_done_button = OD.Chrome.button(assets.textures.done_button)
	_done_button.anchor_left = 1
	_done_button.anchor_top = 0
	_done_button.offset_left = -_done_button.texture_normal.get_width()
	_done_button.offset_top = 0
	_done_button.visible = false
	_done_button.pressed.connect(_on_import_batch_pressed)
	container.add_child(_done_button)

	var outer_panel = PanelContainer.new()
	outer_panel.anchor_left = 0.06
	outer_panel.anchor_top = 0.13
	outer_panel.anchor_right = 0.94
	outer_panel.anchor_bottom = 0.94
	outer_panel.add_theme_stylebox_override("panel", _create_parchment_panel_style(parchment_background))
	container.add_child(outer_panel)

	var main_vertical_box = VBoxContainer.new()
	main_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vertical_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vertical_box.add_theme_constant_override("separation", 14)
	outer_panel.add_child(main_vertical_box)

	var top_vertical_box = VBoxContainer.new()
	top_vertical_box.add_theme_constant_override("separation", 8)
	main_vertical_box.add_child(top_vertical_box)

	var scan_row = HBoxContainer.new()
	scan_row.add_theme_constant_override("separation", 10)
	top_vertical_box.add_child(scan_row)

	var directory_label = Label.new()
	directory_label.text = "Save Dir:"
	directory_label.add_theme_font_override("font", _font_result)
	directory_label.add_theme_font_size_override("font_size", 20)
	directory_label.add_theme_color_override("font_color", INK_COLOR)
	scan_row.add_child(directory_label)

	_directory_input = LineEdit.new()
	_directory_input.placeholder_text = "Enter Dungeons of Dredmor save folder path or drag & drop a .dredmorsave here..."
	_directory_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_directory_input.add_theme_font_override("font", _font_result)
	_directory_input.add_theme_font_size_override("font_size", 18)
	_directory_input.add_theme_color_override("font_color", INK_COLOR)
	_directory_input.add_theme_color_override("font_placeholder_color", Color(0.28, 0.20, 0.14, 0.65))
	var inset_style = _create_inset_style()
	_directory_input.add_theme_stylebox_override("normal", inset_style)
	_directory_input.add_theme_stylebox_override("focus", inset_style)
	_directory_input.text_submitted.connect(func(_text): _scan_custom_dir())
	OD.Chrome.attach_focus_ring(_directory_input)
	scan_row.add_child(_directory_input)

	var scan_button = OD.Chrome.parchment_button("Scan Dir", _font_result, INK_COLOR, _blank_texture, 18)
	scan_button.custom_minimum_size = Vector2(124, 36)
	scan_button.pressed.connect(_scan_custom_dir)
	scan_row.add_child(scan_button)

	var rescan_button = OD.Chrome.parchment_button("Common Paths", _font_result, INK_COLOR, _blank_texture, 18)
	rescan_button.custom_minimum_size = Vector2(158, 36)
	rescan_button.pressed.connect(_scan_common_dirs)
	scan_row.add_child(rescan_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_override("font", _font_result)
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", MUTED_INK)
	top_vertical_box.add_child(_status_label)

	var content_row = HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 20)
	main_vertical_box.add_child(content_row)

	var left_vertical_box = VBoxContainer.new()
	left_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vertical_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vertical_box.size_flags_stretch_ratio = 1.65
	left_vertical_box.add_theme_constant_override("separation", 12)
	content_row.add_child(left_vertical_box)

	_save_tree = Tree.new()
	_save_tree.columns = 2
	_save_tree.hide_root = true
	_save_tree.column_titles_visible = true
	_save_tree.set_column_title(0, "Import")
	_save_tree.set_column_title(1, "Retail Save")
	_save_tree.set_column_expand(0, false)
	_save_tree.set_column_custom_minimum_width(0, 88)
	_save_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_save_tree.add_theme_font_override("font", _font_result)
	_save_tree.add_theme_font_size_override("font_size", 20)
	_style_tree(_save_tree)
	_save_tree.item_selected.connect(_on_tree_item_selected)
	OD.Chrome.attach_focus_ring(_save_tree)
	left_vertical_box.add_child(_save_tree)
	_save_tree.call_deferred("grab_focus")

	var batch_row = HBoxContainer.new()
	batch_row.add_theme_constant_override("separation", 12)
	left_vertical_box.add_child(batch_row)

	_select_all_button = OD.Chrome.parchment_button("Select All", _font_result, INK_COLOR, _blank_texture, 18)
	_select_all_button.custom_minimum_size = Vector2(130, 38)
	_select_all_button.pressed.connect(_on_toggle_select_all)
	batch_row.add_child(_select_all_button)

	_import_one_button = OD.Chrome.parchment_button("Import Selected", _font_result, INK_COLOR, _blank_texture, 18)
	_import_one_button.custom_minimum_size = Vector2(170, 38)
	_import_one_button.disabled = true
	_import_one_button.pressed.connect(_on_import_selected_pressed)
	batch_row.add_child(_import_one_button)

	_import_batch_button = OD.Chrome.parchment_button("Import Checked", _font_result, INK_COLOR, _blank_texture, 18)
	_import_batch_button.custom_minimum_size = Vector2(170, 38)
	_import_batch_button.disabled = true
	_import_batch_button.pressed.connect(_on_import_batch_pressed)
	batch_row.add_child(_import_batch_button)

	var info_panel = PanelContainer.new()
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_stretch_ratio = 1.0
	info_panel.add_theme_stylebox_override("panel", _create_inset_style())
	content_row.add_child(info_panel)

	var info_vertical_box = VBoxContainer.new()
	info_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vertical_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vertical_box.add_theme_constant_override("separation", 12)
	info_panel.add_child(info_vertical_box)

	_thumb_frame = PanelContainer.new()
	_thumb_frame.visible = false
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.12, 0.09, 0.07, 1.0)
	frame_style.border_color = Color(0.38, 0.27, 0.16, 1.0)
	frame_style.set_border_width_all(3)
	frame_style.set_content_margin_all(4)
	_thumb_frame.add_theme_stylebox_override("panel", frame_style)
	info_vertical_box.add_child(_thumb_frame)

	_thumb_rect = TextureRect.new()
	_thumb_rect.custom_minimum_size = Vector2(200, 150)
	_thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_thumb_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_thumb_frame.add_child(_thumb_rect)

	var details_scroll = ScrollContainer.new()
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	info_vertical_box.add_child(details_scroll)

	_details_label = Label.new()
	_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_override("font", _font_result)
	_details_label.add_theme_font_size_override("font_size", 18)
	_details_label.add_theme_color_override("font_color", INK_COLOR)
	details_scroll.add_child(_details_label)

	var window = get_window()
	if window != null and not window.files_dropped.is_connected(_on_files_dropped):
		window.files_dropped.connect(_on_files_dropped)

	_scan_common_dirs()

func _scan_common_dirs():
	var result = RetailSaveImporterScript.scan_common_directories()
	_saves = result.saves
	if not result.matched_dirs.is_empty():
		_directory_input.text = result.matched_dirs[0]
		_status_label.text = "Found %d retail save(s). Drag & drop a .dredmorsave folder anytime to import." % _saves.size()
	else:
		_status_label.text = "No retail saves found in common locations. Enter a directory to scan or drag & drop a .dredmorsave folder."
	_populate_tree()

func _scan_custom_dir():
	var directory_path = _directory_input.text.strip_edges()
	if directory_path == "":
		_status_label.text = "Enter a directory path to scan."
		return
	_saves = RetailSaveImporterScript.scan_directory(directory_path)
	if _saves.is_empty():
		_status_label.text = "No .dredmorsave folders found in " + directory_path
	else:
		_status_label.text = "Found %d retail save(s) in %s" % [_saves.size(), directory_path]
	_populate_tree()

func _populate_tree():
	_save_tree.clear()
	_selected_index = -1
	_import_one_button.disabled = true
	_import_batch_button.disabled = _saves.is_empty()
	if _done_button != null:
		_done_button.visible = not _saves.is_empty()
	_thumb_frame.visible = false
	if _saves.is_empty():
		_details_label.text = "No retail saves loaded.\n\nYou can:\n- Enter a save directory above\n- Drag & drop a .dredmorsave folder here"
		return
	var root = _save_tree.create_item()
	for ii in range(_saves.size()):
		var entry = _saves[ii]
		var item = _save_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, true)
		item.set_text(1, entry.label)
		item.set_metadata(0, ii)
	var first_item = root.get_first_child()
	if first_item != null:
		first_item.select(1)
		_on_tree_item_selected()

func _on_tree_item_selected():
	var selected = _save_tree.get_selected()
	if selected == null:
		return
	var index = int(selected.get_metadata(0))
	if index < 0 or index >= _saves.size():
		return
	_selected_index = index
	var entry = _saves[index]
	_details_label.text = entry.details
	_import_one_button.disabled = false
	_thumb_frame.visible = false
	if entry.thumbnail_path != "":
		var img = Image.load_from_file(entry.thumbnail_path)
		if img != null:
			_thumb_rect.texture = ImageTexture.create_from_image(img)
			_thumb_frame.visible = true

func _on_toggle_select_all():
	var root = _save_tree.get_root()
	if root == null:
		return
	var any_unchecked = false
	var child = root.get_first_child()
	while child != null:
		if not child.is_checked(0):
			any_unchecked = true
			break
		child = child.get_next()
	child = root.get_first_child()
	while child != null:
		child.set_checked(0, any_unchecked)
		child = child.get_next()

func _on_import_selected_pressed():
	if _selected_index < 0 or _selected_index >= _saves.size():
		return
	var entry = _saves[_selected_index]
	var result = RetailSaveImporterScript.import_save(entry.path)
	if result.ok:
		var warning_text = " (" + str(result.warnings.size()) + " warning(s))" if not result.warnings.is_empty() else ""
		_status_label.text = "Imported '%s' -> %s%s" % [result.name, result.path.get_file(), warning_text]
	else:
		_status_label.text = "Import failed: " + str(result.get("error", "Unknown error"))

func _on_import_batch_pressed():
	var root = _save_tree.get_root()
	if root == null:
		return
	var targets = []
	var child = root.get_first_child()
	while child != null:
		if child.is_checked(0):
			var index = int(child.get_metadata(0))
			if index >= 0 and index < _saves.size():
				targets.append(_saves[index])
		child = child.get_next()
	if targets.is_empty():
		_status_label.text = "No saves checked for batch import."
		return
	var ok_count = 0
	var fail_count = 0
	for entry in targets:
		var result = RetailSaveImporterScript.import_save(entry.path)
		if result.ok:
			ok_count += 1
		else:
			fail_count += 1
	_status_label.text = "Batch import complete: %d imported, %d failed. Open Load Game from Main Menu to play." % [ok_count, fail_count]

func _on_files_dropped(files):
	var imported_count = 0
	var added_entries = []
	for dropped_path in files:
		var cleaned = str(dropped_path).strip_edges()
		if FileAccess.file_exists(cleaned):
			cleaned = cleaned.get_base_dir()
		if cleaned.ends_with(".dredmorsave") or DirAccess.dir_exists_absolute(cleaned):
			var found = RetailSaveImporterScript.scan_directory(cleaned)
			for entry in found:
				var result = RetailSaveImporterScript.import_save(entry.path)
				if result.ok:
					imported_count += 1
				added_entries.append(entry)
	if not added_entries.is_empty():
		_saves = added_entries
		_populate_tree()
	_status_label.text = "Drag & drop: imported %d save(s)." % imported_count

func _unhandled_input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel")) and (not (get_viewport().gui_get_focus_owner() is LineEdit) or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		get_viewport().set_input_as_handled()
		OD.Scenes.goto(OD.Scenes.MAIN_MENU)
