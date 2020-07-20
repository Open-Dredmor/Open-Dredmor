extends Control

var _no_time_to_grind_enabled = false
var _permadeath_enabled = false
var _permadeath_checkmark = null
var _no_time_to_grind_checkmark = null
var _easy_checkmark = null
var _medium_checkmark = null
var _hard_checkmark = null

func _ready():	
	call_deferred("_build_gui")
	
func _build_gui():
	DungeonSettings.reset()
	var assets = Assets.difficulty_menu()
	var difficulty_menu = get_node("/root/Container")
	difficulty_menu.set_size(Settings.display_size())

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.rect_size = Vector2(Settings.display_size().x, header_background.texture.get_height())
	difficulty_menu.add_child(header_background)
	
	var back_button = Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.margin_left = 0
	back_button.margin_top = 0
	back_button.connect("pressed",self,"_on_BackButton_pressed")
	difficulty_menu.add_child(back_button)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.choose_header
	header_text.anchor_left = .5
	header_text.margin_left = - (header_text.texture.get_width()/2)
	difficulty_menu.add_child(header_text)	
	
	var done_button = Chrome.button(assets.textures.done_button)
	done_button.anchor_left = 1
	done_button.anchor_top = 0
	done_button.margin_left = -done_button.texture_normal.get_width()
	done_button.margin_top = 0
	done_button.connect("pressed",self,"_on_DoneButton_pressed")
	difficulty_menu.add_child(done_button)	
	
	var options_form = TextureRect.new()
	options_form.texture = assets.textures.options_form
	options_form.rect_min_size = Vector2(options_form.texture.get_width(), options_form.texture.get_height())
	options_form.anchor_left = .5
	options_form.anchor_top = .5
	options_form.margin_left = -(options_form.texture.get_width()/2)	
	options_form.margin_top = -(options_form.texture.get_height()/2)
	difficulty_menu.add_child(options_form)		
		
	_easy_checkmark = TextureRect.new()
	_easy_checkmark.texture = assets.textures.checkmark_large
	_easy_checkmark.anchor_top = .175
	_easy_checkmark.anchor_left = .245
	_easy_checkmark.margin_left = -(_easy_checkmark.texture.get_width()/2)
	_easy_checkmark.margin_top = -(_easy_checkmark.texture.get_height()/2)
	options_form.add_child(_easy_checkmark)
		
	var easy_button = Button.new()
	easy_button.connect("pressed",self,"_on_EasyDifficultyButton_pressed")	
	easy_button.set_size(Vector2(options_form.texture.get_width() * .7,50))
	Chrome.invisible_button(easy_button)
	easy_button.anchor_top = .12
	easy_button.anchor_left = .15
	options_form.add_child(easy_button)	
	
	_medium_checkmark = TextureRect.new()
	_medium_checkmark.texture = assets.textures.checkmark_large
	_medium_checkmark.anchor_top = .285
	_medium_checkmark.anchor_left = .245
	_medium_checkmark.margin_left = -(_medium_checkmark.texture.get_width()/2)
	_medium_checkmark.margin_top = -(_medium_checkmark.texture.get_height()/2)
	options_form.add_child(_medium_checkmark)
	
	var medium_button = Button.new()
	Chrome.invisible_button(medium_button)
	medium_button.connect("pressed",self,"_on_MediumDifficultyButton_pressed")	
	medium_button.set_size(Vector2(options_form.texture.get_width() * .7,60))
	medium_button.anchor_top = .22
	medium_button.anchor_left = .15
	options_form.add_child(medium_button)
	
	_hard_checkmark = TextureRect.new()
	_hard_checkmark.texture = assets.textures.checkmark_large
	_hard_checkmark.anchor_top = .39
	_hard_checkmark.anchor_left = .245
	_hard_checkmark.margin_left = -(_hard_checkmark.texture.get_width()/2)
	_hard_checkmark.margin_top = -(_hard_checkmark.texture.get_height()/2)
	options_form.add_child(_hard_checkmark)
	
	var hard_button = Button.new()
	Chrome.invisible_button(hard_button)
	hard_button.connect("pressed",self,"_on_HardDifficultyButton_pressed")	
	hard_button.set_size(Vector2(options_form.texture.get_width() * .7,70))
	hard_button.anchor_top = .34
	hard_button.anchor_left = .15
	options_form.add_child(hard_button)
	
	_permadeath_checkmark = TextureRect.new()
	_permadeath_checkmark.texture = assets.textures.checkmark_small
	_permadeath_checkmark.anchor_top = .55
	_permadeath_checkmark.anchor_left = .22
	_permadeath_checkmark.margin_left = -(_permadeath_checkmark.texture.get_width()/2)
	_permadeath_checkmark.margin_top = -(_permadeath_checkmark.texture.get_height()/2)
	options_form.add_child(_permadeath_checkmark)
	
	var permadeath_button = Button.new()
	Chrome.invisible_button(permadeath_button)
	permadeath_button.connect("pressed",self,"_on_PermadeathButton_pressed")	
	permadeath_button.set_size(Vector2(options_form.texture.get_width() * .7,60))
	permadeath_button.anchor_top = .50
	permadeath_button.anchor_left = .15
	options_form.add_child(permadeath_button)
	
	_no_time_to_grind_checkmark = TextureRect.new()
	_no_time_to_grind_checkmark.texture = assets.textures.checkmark_small
	_no_time_to_grind_checkmark.anchor_top = .71
	_no_time_to_grind_checkmark.anchor_left = .22
	_no_time_to_grind_checkmark.margin_left = -(_no_time_to_grind_checkmark.texture.get_width()/2)
	_no_time_to_grind_checkmark.margin_top = -(_no_time_to_grind_checkmark.texture.get_height()/2)
	options_form.add_child(_no_time_to_grind_checkmark)
	
	var no_time_to_grind_button = Button.new()
	Chrome.invisible_button(no_time_to_grind_button)
	no_time_to_grind_button.connect("pressed",self,"_on_NoTimeToGrindButton_pressed")	
	no_time_to_grind_button.set_size(Vector2(options_form.texture.get_width() * .7,60))
	no_time_to_grind_button.anchor_top = .65
	no_time_to_grind_button.anchor_left = .15
	options_form.add_child(no_time_to_grind_button)	
	
	_select_difficulty(DungeonSettings.get_settings().difficulty)
	_permadeath_checkmark.visible = _permadeath_enabled
	_no_time_to_grind_checkmark.visible = _no_time_to_grind_enabled

func _on_DoneButton_pressed():
	Scenes.goto(Scenes.SKILLS_MENU)
	pass

func _on_BackButton_pressed():
	Scenes.goto(Scenes.MAIN_MENU)

func _select_difficulty(mode):
	_easy_checkmark.visible = mode == DungeonSettings.Difficulty.Easy
	_medium_checkmark.visible = mode == DungeonSettings.Difficulty.Medium
	_hard_checkmark.visible = mode == DungeonSettings.Difficulty.Hard
	DungeonSettings.set_difficulty(mode)

func _on_EasyDifficultyButton_pressed():
	_select_difficulty(DungeonSettings.Difficulty.Easy)
	
func _on_MediumDifficultyButton_pressed():
	_select_difficulty(DungeonSettings.Difficulty.Medium)
	
func _on_HardDifficultyButton_pressed():
	_select_difficulty(DungeonSettings.Difficulty.Hard)

func _on_PermadeathButton_pressed():
	_permadeath_enabled = !_permadeath_enabled
	_permadeath_checkmark.visible = _permadeath_enabled
	DungeonSettings.set_permadeath(_permadeath_enabled)
	
func _on_NoTimeToGrindButton_pressed():
	_no_time_to_grind_enabled = !_no_time_to_grind_enabled
	_no_time_to_grind_checkmark.visible = _no_time_to_grind_enabled
	DungeonSettings.set_no_time_to_grind(_no_time_to_grind_enabled)
