extends Control

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

static func init_container():
	return Control.new()

var MAX_SKILL_SELECTION = 7

var _selected_skills = null
var _skills = null
var _highlighted_panel_buttons = null
var _skill_panel_buttons = {}
var _selected_skills_container = null
var _pack_info_by_id = {}

var _container = null
var _done_button = null
var _info_header = null
var _info_details = null
var _tooltip_panel = null
var _tooltip_label = null

func _ready():	
	call_deferred("_build_gui")
	
func _process(_delta):
	if _highlighted_panel_buttons != null:
		for key in _highlighted_panel_buttons.keys():
			var button = _highlighted_panel_buttons[key]
			OD.Chrome.highlight(button)
	if _selected_skills != null:
		_done_button.visible = _selected_skills.keys().size() == MAX_SKILL_SELECTION
	if _tooltip_panel != null and _tooltip_panel.visible:
		UiHelpers.position_tooltip(_tooltip_panel, get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)
	
func _build_gui():
	var assets = OD.Assets.skills_menu()
	_container = get_node("/root/Container")
	var display_size = OD.Settings.display_size()
	_container.set_size(display_size)
	_skills = OD.Database.character_creation_skill_list()	
	_selected_skills = {}
	_highlighted_panel_buttons = {}
	_skill_panel_buttons.clear()
	_pack_info_by_id.clear()
	for pack_info in OD.Database.get_available_packs():
		_pack_info_by_id[pack_info.id] = pack_info

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	var header_height = header_background.texture.get_height()
	header_background.size = Vector2(display_size.x, header_height)
	_container.add_child(header_background)
	
	var back_button = OD.Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.offset_left = 0
	back_button.offset_top = 0
	back_button.pressed.connect(_on_BackButton_pressed)
	_container.add_child(back_button)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.skills_header
	header_text.anchor_left = .5
	header_text.offset_left = - (header_text.texture.get_width()/2)
	_container.add_child(header_text)	
	
	_done_button = OD.Chrome.button(assets.textures.done_button)
	_done_button.anchor_left = 1
	_done_button.anchor_top = 0
	_done_button.offset_left = -_done_button.texture_normal.get_width()
	_done_button.offset_top = 0
	_done_button.pressed.connect(_on_DoneButton_pressed)
	_container.add_child(_done_button)	

	var center_wrapper = CenterContainer.new()
	center_wrapper.anchor_left = 0.0
	center_wrapper.anchor_top = 0.0
	center_wrapper.anchor_right = 1.0
	center_wrapper.anchor_bottom = 1.0
	center_wrapper.offset_top = header_height + 16
	center_wrapper.offset_bottom = -16
	center_wrapper.offset_left = 24
	center_wrapper.offset_right = -24
	_container.add_child(center_wrapper)
			
	var skills_container = VBoxContainer.new()
	skills_container.name = 'SkillsContainer'
	skills_container.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_container.add_theme_constant_override("separation", 12)
	center_wrapper.add_child(skills_container)

	var border_size = assets.textures.skill_button_border.get_size() if assets.textures.skill_button_border != null else Vector2(72, 72)
	var columns_count = 10
	var grid_separation = 4
	var rows_count = max(1, int(ceil(float(_skills.size()) / float(columns_count))))
	var grid_content_height = rows_count * border_size.y + max(0, rows_count - 1) * grid_separation
	var selected_panel_height = assets.textures.selected_skills_background.get_height() if assets.textures.selected_skills_background != null else 104
	var info_panel_height = assets.textures.selected_skill_info_background.get_height() if assets.textures.selected_skill_info_background != null else 120
	var max_scroll_height = max(240.0, display_size.y - header_height - selected_panel_height - info_panel_height - 96.0)
	var scroll_height = min(grid_content_height + 8.0, max_scroll_height)
	var scroll_width = columns_count * border_size.x + (columns_count - 1) * grid_separation + 24.0

	var skills_scroll = ScrollContainer.new()
	skills_scroll.name = "SkillsScroll"
	skills_scroll.custom_minimum_size = Vector2(scroll_width, scroll_height)
	skills_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skills_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skills_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	skills_scroll.follow_focus = true
	skills_container.add_child(skills_scroll)
			
	var skills_selector = GridContainer.new()
	skills_selector.name = "SkillsSelector"
	skills_selector.columns = columns_count
	skills_selector.add_theme_constant_override("h_separation", grid_separation)
	skills_selector.add_theme_constant_override("v_separation", grid_separation)
	skills_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skills_scroll.add_child(skills_selector)
			
	for skill in _skills:
		var skill_border = TextureRect.new()
		skill_border.texture = assets.textures.skill_button_border
		skill_border.custom_minimum_size = border_size
		skill_border.name = "PickSkillBorder#" + str(skill.id)
		skills_selector.add_child(skill_border)
		
		var pick_skill_button = OD.Chrome.highlight_on_hover_button(skill.icon)
		pick_skill_button.pressed.connect(_select_skill.bind(skill))
		pick_skill_button.mouse_entered.connect(_on_skill_hover_entered.bind(skill))
		pick_skill_button.mouse_exited.connect(_on_skill_hover_exited)
		pick_skill_button.focus_entered.connect(_describe_skill.bind(skill))
		pick_skill_button.name = "PickSkillButton#" + str(skill.id)
		pick_skill_button.offset_top = 5
		pick_skill_button.offset_left = 5
		skill_border.add_child(pick_skill_button)
		_skill_panel_buttons[skill.id] = pick_skill_button
			
	var selected_skills_background = TextureRect.new()
	selected_skills_background.texture = assets.textures.selected_skills_background
	selected_skills_background.name = "SelectedSkillsBackground"
	selected_skills_background.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skills_container.add_child(selected_skills_background)
	
	_selected_skills_container = HBoxContainer.new()
	_selected_skills_container.name = "SelectedSkillsContainer"
	_selected_skills_container.anchor_left = 0.025
	_selected_skills_container.anchor_top = 0.2
	_selected_skills_container.add_theme_constant_override("separation", 24)
	selected_skills_background.add_child(_selected_skills_container)	
	
	var random_selection_button = OD.Chrome.button(assets.textures.random_selection_button)
	random_selection_button.anchor_left = 0.838
	random_selection_button.anchor_top = 0.55
	random_selection_button.pressed.connect(_on_RandomSelectionButton_pressed)
	random_selection_button.mouse_entered.connect(_describe_skill.bind("_random"))
	random_selection_button.mouse_exited.connect(_describe_skill.bind(null))
	random_selection_button.focus_entered.connect(_describe_skill.bind("_random"))
	selected_skills_background.add_child(random_selection_button)

	var last_selection_button = OD.Chrome.button(assets.textures.last_selection_button)
	last_selection_button.anchor_left = 0.935
	last_selection_button.anchor_top = 0.55
	last_selection_button.pressed.connect(_on_LastSelectionButton_pressed)
	last_selection_button.mouse_entered.connect(_describe_skill.bind("_last"))
	last_selection_button.mouse_exited.connect(_describe_skill.bind(null))
	last_selection_button.focus_entered.connect(_describe_skill.bind("_last"))
	last_selection_button.disabled = OD.Settings.last_selected_skill_ids().is_empty()
	selected_skills_background.add_child(last_selection_button)
	
	var selected_skill_info_background = TextureRect.new()
	selected_skill_info_background.texture = assets.textures.selected_skill_info_background
	selected_skill_info_background.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skills_container.add_child(selected_skill_info_background)
	
	var info_text_container = HBoxContainer.new()
	info_text_container.name = "InfoTextContainer"
	info_text_container.anchor_right = 1
	info_text_container.anchor_bottom = 1
	info_text_container.offset_top = 10
	info_text_container.offset_left = 10
	info_text_container.offset_right = -30
	info_text_container.offset_bottom = -30
	selected_skill_info_background.add_child(info_text_container)
	
	# Skill info uses the Dredmor asset font "Austin.ttf"
	_info_header = Label.new()
	_info_header.name = "InfoHeader"
	_info_header.add_theme_font_override("font", assets.fonts.info_header)
	_info_header.add_theme_font_size_override("font_size", assets.font_sizes.info_header)
	_info_header.add_theme_color_override("font_color", Color(0,0,0))
	_info_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_header.anchor_right = 1
	_info_header.anchor_bottom = 1
	_info_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_header.size_flags_stretch_ratio = 1.2
	_info_header.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	_info_header.size_flags_vertical = SIZE_FILL | SIZE_EXPAND
	info_text_container.add_child(_info_header)
	
	_info_details = Label.new()
	_info_details.name = "InfoDetails"
	_info_details.add_theme_font_override("font", assets.fonts.info_details)
	_info_details.add_theme_font_size_override("font_size", assets.font_sizes.info_details)
	_info_details.add_theme_color_override("font_color", Color(0,0,0))
	_info_details.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_details.anchor_right = 1
	_info_details.anchor_bottom = 1
	_info_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_details.size_flags_stretch_ratio = 2.8
	_info_details.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	_info_details.size_flags_vertical = SIZE_FILL | SIZE_EXPAND
	info_text_container.add_child(_info_details)

	var tooltip_nodes = UiHelpers.create_tooltip(_container, 220, 16)
	_tooltip_panel = tooltip_nodes.panel
	_tooltip_label = tooltip_nodes.label

	var saved_skill_ids = OD.DungeonSettings.get_settings().starting_skill_ids
	for skill in _skills:
		if saved_skill_ids.has(skill.id):
			_select_skill(skill)

	if not _skills.is_empty():
		var first_button = _get_skill_panel_button(_skills[0].id)
		if first_button != null:
			first_button.call_deferred("grab_focus")

func _format_skill_source(skill):
	var pack_id = str(skill.get("pack_id", "vanilla"))
	if pack_id == "" or pack_id == "vanilla":
		return "Dungeons of Dredmor"
	if _pack_info_by_id.has(pack_id):
		var pack_info = _pack_info_by_id[pack_id]
		if pack_info.kind == "expansion":
			return "Expansion: " + str(pack_info.name)
		var author = str(pack_info.get("metadata", {}).get("author", "")).strip_edges()
		if author != "":
			return "Mod: " + str(pack_info.name) + " - " + author
		return "Mod: " + str(pack_info.name)
	return "Source: " + pack_id

func _on_skill_hover_entered(skill):
	_describe_skill(skill)
	if _tooltip_label != null and _tooltip_panel != null and skill != null:
		_tooltip_label.text = _format_skill_source(skill)
		_tooltip_panel.visible = true
		UiHelpers.position_tooltip(_tooltip_panel, get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)

func _on_skill_hover_exited():
	_describe_skill(null)
	if _tooltip_panel != null:
		_tooltip_panel.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_on_BackButton_pressed()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START and _done_button != null and _done_button.visible:
		get_viewport().set_input_as_handled()
		_on_DoneButton_pressed()

func _remove_selected_skill_buttons():
	var parent = _get_selected_skills_container()
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	
func _get_selected_skills_container():
	return _selected_skills_container

func _get_skill_panel_button(skill_id):
	return _skill_panel_buttons.get(skill_id, null)

func _describe_skill(skill):
	if skill == null:
		_info_header.text = ""
		_info_details.text = ""	
	elif typeof(skill) == TYPE_STRING and skill == "_random":
		_info_header.text = "Random Skills"
		_info_details.text = "You start the game with seven skills chosen, excitingly, at random."
	elif typeof(skill) == TYPE_STRING and skill == "_last":
		_info_header.text = "Last Selection"
		_info_details.text = "Select the same seven skills you used in your previous game."
	else:
		var archetype = skill.type.capitalize() + " Skill" if skill.has("type") and skill.type != "" else ""
		_info_header.text = skill.name + ("\n[" + archetype + "]" if archetype != "" else "")
		_info_details.text = skill.description

func _select_skill(skill):
	_remove_selected_skill_buttons()
	var skill_panel_button = _get_skill_panel_button(skill.id)	
	if _selected_skills.has(skill.id):		
		OD.Chrome.darken(skill_panel_button)		
		_selected_skills.erase(skill.id)		
		_highlighted_panel_buttons.erase(skill.id)
	else:
		if _selected_skills.keys().size() < MAX_SKILL_SELECTION:
			OD.Chrome.highlight(skill_panel_button)
			_highlighted_panel_buttons[skill.id] = skill_panel_button
			_selected_skills[skill.id] = skill						
	if _selected_skills.keys().size() > 0:
		var selected_skills_container = _get_selected_skills_container()
		for key in _selected_skills.keys():
			var selected_skill = _selected_skills[key]
			var selected_skill_button = TextureButton.new()
			selected_skill_button.texture_normal = selected_skill.icon
			selected_skill_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			selected_skill_button.pressed.connect(_select_skill.bind(selected_skill))
			selected_skill_button.mouse_entered.connect(_on_skill_hover_entered.bind(selected_skill))
			selected_skill_button.mouse_exited.connect(_on_skill_hover_exited)
			selected_skills_container.add_child(selected_skill_button)

func _on_DoneButton_pressed():
	var selected_ids = _selected_skills.keys()
	OD.DungeonSettings.set_starting_skill_ids(selected_ids)
	OD.Settings.set_last_selected_skill_ids(selected_ids)
	OD.Scenes.goto(OD.Scenes.CHARACTER_MENU)

func _on_BackButton_pressed():
	OD.DungeonSettings.set_starting_skill_ids(_selected_skills.keys())
	OD.Scenes.goto(OD.Scenes.DIFFICULTY_MENU)

func _clear_selected_skills():
	for key in _highlighted_panel_buttons.keys():
		OD.Chrome.darken(_highlighted_panel_buttons[key])
		_highlighted_panel_buttons.erase(key)
	_remove_selected_skill_buttons()
	_selected_skills = {}

func _on_RandomSelectionButton_pressed():
	_clear_selected_skills()
	var random_skills = OD.DataStructure.choose(_skills, MAX_SKILL_SELECTION)
	for skill in random_skills:
		_select_skill(skill)

func _on_LastSelectionButton_pressed():
	var last_ids = OD.Settings.last_selected_skill_ids()
	if last_ids.is_empty():
		return
	_clear_selected_skills()
	for skill in _skills:
		if last_ids.has(skill.id):
			_select_skill(skill)
		


