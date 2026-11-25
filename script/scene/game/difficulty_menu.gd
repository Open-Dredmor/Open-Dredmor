extends Control

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

func _ready():	
	call_deferred("_build_gui")
	
func _build_gui():
	var assets = OD.Assets.difficulty_menu()
	var difficulty_menu = get_node("/root/Container")
	difficulty_menu.set_size(OD.Settings.display_size())

	if OD.Load.exists("ui/menus/bg_stonetile.png"):
		var bg_tile = TextureRect.new()
		bg_tile.texture = OD.Load.image("ui/menus/bg_stonetile.png")
		bg_tile.stretch_mode = TextureRect.STRETCH_TILE
		bg_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		difficulty_menu.add_child(bg_tile)

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.size = Vector2(OD.Settings.display_size().x, header_background.texture.get_height())
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
	
	var options_form = TextureRect.new()
	options_form.texture = assets.textures.options_form
	options_form.custom_minimum_size = Vector2(options_form.texture.get_width(), options_form.texture.get_height())
	options_form.anchor_left = .5
	options_form.anchor_top = .5
	options_form.offset_left = -(options_form.texture.get_width()/2)	
	options_form.offset_top = -(options_form.texture.get_height()/2)
	difficulty_menu.add_child(options_form)		
		
	_easy_checkmark = TextureRect.new()
	_easy_checkmark.texture = assets.textures.checkmark_large
	_easy_checkmark.anchor_top = .175
	_easy_checkmark.anchor_left = .245
	_easy_checkmark.offset_left = -(_easy_checkmark.texture.get_width()/2)
	_easy_checkmark.offset_top = -(_easy_checkmark.texture.get_height()/2)
	options_form.add_child(_easy_checkmark)
		
	var easy_button = OD.Chrome.invisible_button()
	easy_button.pressed.connect(_on_EasyDifficultyButton_pressed)	
	easy_button.set_size(Vector2(options_form.texture.get_width() * .7,50))
	easy_button.anchor_top = .12
	easy_button.anchor_left = .15
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
	medium_button.set_size(Vector2(options_form.texture.get_width() * .7,60))
	medium_button.anchor_top = .22
	medium_button.anchor_left = .15
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
	hard_button.set_size(Vector2(options_form.texture.get_width() * .7,70))
	hard_button.anchor_top = .34
	hard_button.anchor_left = .15
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
	permadeath_button.set_size(Vector2(options_form.texture.get_width() * .7,60))
	permadeath_button.anchor_top = .50
	permadeath_button.anchor_left = .15
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
	no_time_to_grind_button.set_size(Vector2(options_form.texture.get_width() * .7,60))
	no_time_to_grind_button.anchor_top = .65
	no_time_to_grind_button.anchor_left = .15
	options_form.add_child(no_time_to_grind_button)	
	
	var settings = OD.DungeonSettings.get_settings()
	_permadeath_enabled = settings.permadeath
	_no_time_to_grind_enabled = settings.no_time_to_grind
	_selected_pack_ids = settings.active_packs.duplicate()
	_select_difficulty(settings.difficulty)
	_permadeath_checkmark.visible = _permadeath_enabled
	_no_time_to_grind_checkmark.visible = _no_time_to_grind_enabled

	_build_content_packs_panel(difficulty_menu, assets)

func _build_content_packs_panel(parent, assets):
	var dialog_assets = OD.Assets.dialog()
	var font_res = dialog_assets.font if dialog_assets != null else null
	var parchment_bg = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	var ink_color = Color(0.16, 0.10, 0.06)
	var header_ink = Color(0.28, 0.12, 0.05)

	var panel = PanelContainer.new()
	panel.anchor_left = 0.65
	panel.anchor_top = 0.20
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.80
	if parchment_bg != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = parchment_bg
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

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "Expansions"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_res != null:
		title_label.add_theme_font_override("font", font_res)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", header_ink)
	vbox.add_child(title_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)

	var available_packs = []
	for pack_info in OD.Database.get_available_packs():
		if pack_info.kind == "expansion":
			available_packs.append(pack_info)
	if available_packs.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No expansions found."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if font_res != null:
			empty_label.add_theme_font_override("font", font_res)
		empty_label.add_theme_font_size_override("font_size", 19)
		empty_label.add_theme_color_override("font_color", ink_color)
		list_vbox.add_child(empty_label)
		return

	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.84, 0.77, 0.65, 0.8)
	box_style.border_color = Color(0.32, 0.20, 0.12, 1.0)
	box_style.set_border_width_all(2)

	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)

	for pack_info in available_packs:
		var is_enabled = _selected_pack_ids.has(pack_info.id)
		var row_btn = Button.new()
		row_btn.toggle_mode = true
		row_btn.button_pressed = is_enabled
		row_btn.custom_minimum_size = Vector2(0, 38)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row_btn.add_theme_stylebox_override("normal", transparent_style)
		row_btn.add_theme_stylebox_override("hover", transparent_style)
		row_btn.add_theme_stylebox_override("pressed", transparent_style)
		row_btn.add_theme_stylebox_override("focus", transparent_style)
		list_vbox.add_child(row_btn)

		var row_hbox = HBoxContainer.new()
		row_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		row_hbox.add_theme_constant_override("separation", 12)
		row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_btn.add_child(row_hbox)

		var check_box = PanelContainer.new()
		check_box.custom_minimum_size = Vector2(28, 28)
		check_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		check_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_box.add_theme_stylebox_override("panel", box_style)
		row_hbox.add_child(check_box)

		var mark = TextureRect.new()
		mark.texture = assets.textures.checkmark_small
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.visible = is_enabled
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_box.add_child(mark)

		var name_lbl = Label.new()
		name_lbl.text = pack_info.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if font_res != null:
			name_lbl.add_theme_font_override("font", font_res)
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", ink_color)
		row_hbox.add_child(name_lbl)

		var pid = pack_info.id
		row_btn.toggled.connect(func(pressed_state):
			mark.visible = pressed_state
			_on_pack_toggled(pressed_state, pid)
		)

func _on_pack_toggled(enabled, pack_id):
	if enabled:
		if not _selected_pack_ids.has(pack_id):
			_selected_pack_ids.append(pack_id)
	else:
		_selected_pack_ids.erase(pack_id)
	OD.DungeonSettings.set_active_packs(_selected_pack_ids)

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
