extends Control

static func init_container():
	return Control.new()

var MAX_SKILL_SELECTION = 7

var _selected_skills = null
var _skills = null
var _highlighted_panel_buttons = null

var _container = null
var _done_button = null
var _info_header = null
var _info_details = null

func _ready():	
	call_deferred("_build_gui")
	
func _process(_delta):
	if _highlighted_panel_buttons != null:
		for key in _highlighted_panel_buttons.keys():
			var button = _highlighted_panel_buttons[key]
			OD.Chrome.highlight(button)
	if _selected_skills != null:
		_done_button.visible = _selected_skills.keys().size() == MAX_SKILL_SELECTION
	
func _build_gui():
	var assets = OD.Assets.skills_menu()
	_container = get_node("/root/Container")
	_container.set_size(OD.Settings.display_size())
	_skills = OD.Database.character_creation_skill_list()	
	_selected_skills = {}
	_highlighted_panel_buttons = {}

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.size = Vector2(OD.Settings.display_size().x, header_background.texture.get_height())
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
			
	var skills_container = VBoxContainer.new()
	skills_container.name = 'SkillsContainer'
	skills_container.anchor_left = .25
	skills_container.anchor_top = .3
	_container.add_child(skills_container)
			
	var skills_selector = GridContainer.new()
	skills_selector.name = "SkillsSelector"
	skills_selector.columns = 10	
	skills_container.add_child(skills_selector)
			
	for skill in _skills:
		var skill_border = TextureRect.new()
		skill_border.texture = assets.textures.skill_button_border
		skill_border.name = "PickSkillBorder#" + skill.id
		skills_selector.add_child(skill_border)
		
		var pick_skill_button = OD.Chrome.highlight_on_hover_button(skill.icon)
		pick_skill_button.pressed.connect(_select_skill.bind(skill))
		pick_skill_button.mouse_entered.connect(_describe_skill.bind(skill))	
		pick_skill_button.mouse_exited.connect(_describe_skill.bind(null))	
		pick_skill_button.name = "PickSkillButton#" + skill.id
		pick_skill_button.offset_top = 5
		pick_skill_button.offset_left = 5
		skill_border.add_child(pick_skill_button)
			
	var selected_skills_background = TextureRect.new()
	selected_skills_background.texture = assets.textures.selected_skills_background
	selected_skills_background.name = "SelectedSkillsBackground"
	skills_container.add_child(selected_skills_background)
	
	var selected_skills_container = HBoxContainer.new()
	selected_skills_container.name = "SelectedSkillsContainer"
	selected_skills_container.anchor_left = 0.025
	selected_skills_container.anchor_top = 0.2
	selected_skills_container.add_theme_constant_override("separation", 24)
	selected_skills_background.add_child(selected_skills_container)	
	
	var random_selection_button = OD.Chrome.button(assets.textures.random_selection_button)
	random_selection_button.anchor_left = 0.838
	random_selection_button.anchor_top = 0.55
	random_selection_button.pressed.connect(_on_RandomSelectionButton_pressed)
	random_selection_button.mouse_entered.connect(_describe_skill.bind("_random"))
	random_selection_button.mouse_exited.connect(_describe_skill.bind(null))
	selected_skills_background.add_child(random_selection_button)

	var last_selection_button = OD.Chrome.button(assets.textures.last_selection_button)
	last_selection_button.anchor_left = 0.935
	last_selection_button.anchor_top = 0.55
	last_selection_button.pressed.connect(_on_LastSelectionButton_pressed)
	last_selection_button.mouse_entered.connect(_describe_skill.bind("_last"))
	last_selection_button.mouse_exited.connect(_describe_skill.bind(null))
	last_selection_button.disabled = OD.Settings.last_selected_skill_ids().is_empty()
	selected_skills_background.add_child(last_selection_button)
	
	var selected_skill_info_background = TextureRect.new()
	selected_skill_info_background.texture = assets.textures.selected_skill_info_background
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

	var saved_skill_ids = OD.DungeonSettings.get_settings().starting_skill_ids
	for skill in _skills:
		if saved_skill_ids.has(skill.id):
			_select_skill(skill)

func _remove_selected_skill_buttons():
	var parent = _get_selected_skills_container()
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	
func _get_selected_skills_container():
	var parent_path = "/root/Container/SkillsContainer/SelectedSkillsBackground/SelectedSkillsContainer"
	return get_node(parent_path)

func _get_skill_panel_button(skill_id):
	var skill_panel_path = '/root/Container/SkillsContainer/SkillsSelector/PickSkillBorder#'+skill_id+'/PickSkillButton#'+skill_id
	return get_node(skill_panel_path)

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
			selected_skill_button.mouse_entered.connect(_describe_skill.bind(selected_skill))	
			selected_skill_button.mouse_exited.connect(_describe_skill.bind(null))	
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
		


