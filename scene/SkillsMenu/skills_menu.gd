extends Control

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
			Chrome.highlight(button)
	if _selected_skills != null:
		_done_button.visible = _selected_skills.keys().size() == MAX_SKILL_SELECTION
	
func _build_gui():
	DungeonSettings.reset()
	var assets = Assets.skills_menu()
	_container = get_node("/root/Container")
	_container.set_size(Settings.display_size())
	_skills = Database.character_creation_skill_list()	
	_selected_skills = {}
	_highlighted_panel_buttons = {}

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.rect_size = Vector2(Settings.display_size().x, header_background.texture.get_height())
	_container.add_child(header_background)
	
	var back_button = Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.margin_left = 0
	back_button.margin_top = 0
	back_button.connect("pressed",self,"_on_BackButton_pressed")
	_container.add_child(back_button)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.skills_header
	header_text.anchor_left = .5
	header_text.margin_left = - (header_text.texture.get_width()/2)
	_container.add_child(header_text)	
	
	_done_button = Chrome.button(assets.textures.done_button)
	_done_button.anchor_left = 1
	_done_button.anchor_top = 0
	_done_button.margin_left = -_done_button.texture_normal.get_width()
	_done_button.margin_top = 0
	_done_button.connect("pressed",self,"_on_DoneButton_pressed")
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
		
		var pick_skill_button = Chrome.highlight_on_hover_button(skill.icon)
		pick_skill_button.connect("pressed", self, "_select_skill",[skill])
		pick_skill_button.connect("mouse_entered", self, "_describe_skill", [skill])	
		pick_skill_button.connect("mouse_exited", self, "_describe_skill", [null])	
		pick_skill_button.name = "PickSkillButton#" + skill.id
		pick_skill_button.margin_top = 5
		pick_skill_button.margin_left = 5
		skill_border.add_child(pick_skill_button)
			
	var selected_skills_background = TextureRect.new()
	selected_skills_background.texture = assets.textures.selected_skills_background
	selected_skills_background.name = "SelectedSkillsBackground"
	skills_container.add_child(selected_skills_background)
	
	var selected_skills_container = HBoxContainer.new()
	selected_skills_container.name = "SelectedSkillsContainer"
	selected_skills_container.anchor_left = 0.025
	selected_skills_container.anchor_top = 0.2
	selected_skills_container.set("custom_constants/separation", 24)
	selected_skills_background.add_child(selected_skills_container)	
	
	var random_selection_button = Chrome.button(assets.textures.random_selection_button)
	random_selection_button.anchor_left = 0.838
	random_selection_button.anchor_top = 0.55
	random_selection_button.connect("pressed", self, "_on_RandomSelectionButton_pressed")
	random_selection_button.connect("mouse_entered", self, "_describe_skill",["_random"])
	random_selection_button.connect("mouse_exited", self, "_describe_skill",[null])
	selected_skills_background.add_child(random_selection_button)				
	
	var selected_skill_info_background = TextureRect.new()
	selected_skill_info_background.texture = assets.textures.selected_skill_info_background
	skills_container.add_child(selected_skill_info_background)
	
	var info_text_container = HBoxContainer.new()
	info_text_container.name = "InfoTextContainer"
	info_text_container.anchor_right = 1
	info_text_container.anchor_bottom = 1
	info_text_container.margin_top = 10
	info_text_container.margin_left = 10
	info_text_container.margin_right = -30
	info_text_container.margin_bottom = -30
	selected_skill_info_background.add_child(info_text_container)
	
	# Skill info uses the Dredmor asset font "Austin.ttf"
	_info_header = Label.new()
	_info_header.name = "InfoHeader"
	_info_header.add_font_override("font", assets.fonts.info_header)
	_info_header.add_color_override("font_color", Color(0,0,0))
	_info_header.valign = Label.VALIGN_CENTER
	_info_header.align = Label.ALIGN_CENTER
	_info_header.anchor_right = 1
	_info_header.anchor_bottom = 1
	_info_header.autowrap = true
	_info_header.size_flags_stretch_ratio = 1.2
	_info_header.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	_info_header.size_flags_vertical = SIZE_FILL | SIZE_EXPAND
	info_text_container.add_child(_info_header)
	
	_info_details = Label.new()
	_info_details.name = "InfoDetails"
	_info_details.add_font_override("font", assets.fonts.info_details)
	_info_details.add_color_override("font_color", Color(0,0,0))
	_info_details.valign = Label.VALIGN_CENTER
	_info_details.align = Label.ALIGN_CENTER
	_info_details.anchor_right = 1
	_info_details.anchor_bottom = 1
	_info_details.autowrap = true
	_info_details.size_flags_stretch_ratio = 2.8
	_info_details.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
	_info_details.size_flags_vertical = SIZE_FILL | SIZE_EXPAND
	info_text_container.add_child(_info_details)

func _remove_selected_skill_buttons():
	var parent = _get_selected_skills_container()
	for child in parent.get_children():
		parent.remove_child(child)
	
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
	else:
		_info_header.text = skill.name
		_info_details.text = skill.description

func _select_skill(skill):
	_remove_selected_skill_buttons()
	var skill_panel_button = _get_skill_panel_button(skill.id)	
	if _selected_skills.has(skill.id):		
		Chrome.darken(skill_panel_button)		
		_selected_skills.erase(skill.id)		
		_highlighted_panel_buttons.erase(skill.id)
	else:
		if _selected_skills.keys().size() < MAX_SKILL_SELECTION:
			Chrome.highlight(skill_panel_button)
			_highlighted_panel_buttons[skill.id] = skill_panel_button
			_selected_skills[skill.id] = skill						
	if _selected_skills.keys().size() > 0:
		var selected_skills_container = _get_selected_skills_container()
		for key in _selected_skills.keys():
			var selected_skill = _selected_skills[key]
			var selected_skill_button = TextureButton.new()
			selected_skill_button.texture_normal = selected_skill.icon
			selected_skill_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			selected_skill_button.connect("pressed", self, "_select_skill", [selected_skill])
			selected_skill_button.connect("mouse_entered", self, "_describe_skill", [selected_skill])	
			selected_skill_button.connect("mouse_exited", self, "_describe_skill", [null])	
			selected_skills_container.add_child(selected_skill_button)

func _on_DoneButton_pressed():
	Scenes.goto(Scenes.CHARACTER_MENU)
	pass

func _on_BackButton_pressed():
	Scenes.goto(Scenes.DIFFICULTY_MENU)

func _on_RandomSelectionButton_pressed():
	for key in _highlighted_panel_buttons.keys():
		Chrome.darken(_highlighted_panel_buttons[key])
		_highlighted_panel_buttons.erase(key)
	_remove_selected_skill_buttons()
	_selected_skills = {}
	var random_skills = _skills.duplicate()
	random_skills.shuffle()
	for ii in range(MAX_SKILL_SELECTION):
		_select_skill(random_skills[ii])
		


