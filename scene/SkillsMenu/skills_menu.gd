extends Control

var MAX_SKILL_SELECTION = 7

var _selected_skills = null
var _container = null
var _skill_selection_slug = ""

func _ready():	
	call_deferred("_build_gui")
	
func _process(_delta):
	if _selected_skills != null:
		for key in _selected_skills.keys():
			var skill = _selected_skills[key]
			var button = _get_skill_panel_button(skill.id)
			Chrome.highlight(button)
	
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
	
func _build_gui():
	DungeonSettings.reset()
	var assets = Assets.skills_menu()
	_container = get_node("/root/Container")
	_container.set_size(Settings.display_size())

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.rect_size = Vector2(Settings.display_size().x, header_background.texture.get_height())
	_container.add_child(header_background)
	
	var back_button = TextureButton.new()
	Chrome.button(back_button, assets.textures.back_button)
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
	
	var done_button = TextureButton.new()
	Chrome.button(done_button, assets.textures.done_button)
	done_button.anchor_left = 1
	done_button.anchor_top = 0
	done_button.margin_left = -done_button.texture_normal.get_width()
	done_button.margin_top = 0
	done_button.connect("pressed",self,"_on_DoneButton_pressed")
	_container.add_child(done_button)	
			
	var skills_container = VBoxContainer.new()
	skills_container.name = 'SkillsContainer'
	skills_container.anchor_left = .25
	skills_container.anchor_top = .3
	_container.add_child(skills_container)
			
	var skills_selector = GridContainer.new()
	skills_selector.name = "SkillsSelector"
	skills_selector.columns = 10	
	skills_container.add_child(skills_selector)
	
	_selected_skills = {}
	var skills = Database.character_creation_skill_list()	
	for skill in skills:
		var skill_border = TextureRect.new()
		skill_border.texture = assets.textures.skill_button_border
		skill_border.name = "PickSkillBorder#" + skill.id
		skills_selector.add_child(skill_border)
		
		var pick_skill_button = Chrome.highlight_on_hover_button(skill.icon)
		pick_skill_button.connect("pressed", self, "_select_skill",[skill])
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
	
	var selected_skill_info_background = TextureRect.new()
	selected_skill_info_background.texture = assets.textures.selected_skill_info_background
	skills_container.add_child(selected_skill_info_background)
	

func _select_skill(skill):
	_remove_selected_skill_buttons()
	var skill_panel_button = _get_skill_panel_button(skill.id)	
	if _selected_skills.has(skill.id):		
		Chrome.darken(skill_panel_button)		
		_selected_skills.erase(skill.id)		
	else:
		if _selected_skills.keys().size() < MAX_SKILL_SELECTION:
			Chrome.highlight(skill_panel_button)
			_selected_skills[skill.id] = skill						
	if _selected_skills.keys().size() > 0:
		var selected_skills_container = _get_selected_skills_container()
		for key in _selected_skills.keys():
			var selected_skill = _selected_skills[key]
			var selected_skill_button = TextureButton.new()
			selected_skill_button.texture_normal = selected_skill.icon
			selected_skill_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			selected_skill_button.connect("pressed", self, "_select_skill",[selected_skill])			
			selected_skills_container.add_child(selected_skill_button)
			

func _on_DoneButton_pressed():
	# TODO Implement
	print("Not yet implemented")
	pass

func _on_BackButton_pressed():
	Scenes.goto(Scenes.DifficultyMenu)
