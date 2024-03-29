extends Control

static func init_container():
	return Control.new()

var _done_button = null
var _select_hero_button = null
var _select_heroine_button = null

var _selected_hero = null
var _character_name = null


func _ready():
	call_deferred("_build_gui")
	
func _process(_delta):
	if _done_button != null:
		_done_button.visible = _selected_hero != null and _character_name != null
	if _selected_hero != null:
		if _selected_hero == "hero":
			OD.Chrome.highlight(_select_hero_button)
			OD.Chrome.darken(_select_heroine_button)
		elif _selected_hero == "heroine":
			OD.Chrome.highlight(_select_heroine_button)
			OD.Chrome.darken(_select_hero_button)
	
func _build_gui():
	var assets = OD.Assets.character_menu()
	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())	
	
	var horizontal_container = HBoxContainer.new()
	horizontal_container.anchor_left = 0
	horizontal_container.anchor_top = 0
	horizontal_container.anchor_right = 1
	horizontal_container.anchor_bottom = 1
	horizontal_container.alignment = BoxContainer.ALIGN_CENTER
	container.add_child(horizontal_container)
	
	var hero_container = VBoxContainer.new()
	hero_container.alignment = BoxContainer.ALIGN_CENTER
	hero_container.name = 'HeroContainer'
	horizontal_container.add_child(hero_container)
	
	var choose_name_background = TextureRect.new()
	choose_name_background.texture = assets.textures.choose_name_background
	hero_container.add_child(choose_name_background)
	
	var name_edit_style = StyleBoxFlat.new()
	name_edit_style.bg_color = Color(0,0,0,0)
	
	var name_edit = LineEdit.new()
	name_edit.anchor_top = .3
	name_edit.anchor_left = .2
	name_edit.anchor_bottom = .7
	name_edit.anchor_right = .8
	name_edit.placeholder_text = "Enter a name (up to 14)"
	name_edit.placeholder_alpha = .3
	name_edit.max_length = 14
	name_edit.add_font_override("font",assets.fonts.name_edit)
	name_edit.add_color_override("font_color", Color(0,0,0))
	name_edit.add_stylebox_override("focus", name_edit_style)
	name_edit.add_stylebox_override("normal", name_edit_style)
	name_edit.connect("text_changed", self, "_on_NameEdit_changed")
	choose_name_background.add_child(name_edit)
	
	var choose_hero_background = TextureRect.new()
	choose_hero_background.name = "ChooseHeroBackground"
	choose_hero_background.texture = assets.textures.choose_hero_background
	hero_container.add_child(choose_hero_background)
	
	_select_hero_button = OD.Chrome.highlight_on_hover_button(assets.textures.hero_portrait)
	_select_hero_button.name = "SelectHeroButton"
	_select_hero_button.anchor_left = .265
	_select_hero_button.anchor_top = .4
	_select_hero_button.connect("pressed", self, "_select_hero", ['hero'])
	choose_hero_background.add_child(_select_hero_button)
	_select_heroine_button = OD.Chrome.highlight_on_hover_button(assets.textures.heroine_portrait)	
	_select_heroine_button.name = "SelectHeroineButton"
	_select_heroine_button.anchor_left = .57
	_select_heroine_button.anchor_top = .4
	_select_heroine_button.connect("pressed", self, "_select_hero", ['heroine'])
	choose_hero_background.add_child(_select_heroine_button)

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.rect_size = Vector2(OD.Settings.display_size().x, header_background.texture.get_height())
	container.add_child(header_background)
	
	var back_button = OD.Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.margin_left = 0
	back_button.margin_top = 0
	back_button.connect("pressed",self,"_on_BackButton_pressed")
	container.add_child(back_button)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.character_header
	header_text.anchor_left = .5
	header_text.margin_left = - (header_text.texture.get_width()/2)
	container.add_child(header_text)	
	
	_done_button = OD.Chrome.button(assets.textures.done_button)
	_done_button.anchor_left = 1
	_done_button.anchor_top = 0
	_done_button.margin_left = -_done_button.texture_normal.get_width()
	_done_button.margin_top = 0
	_done_button.connect("pressed",self,"_on_DoneButton_pressed")
	_done_button.visible = false
	container.add_child(_done_button)

func _on_DoneButton_pressed():
	OD.Scenes.goto(OD.Scenes.INTRO_ONE)

func _on_BackButton_pressed():
	OD.Scenes.goto(OD.Scenes.SKILLS_MENU)

func _on_NameEdit_changed(new_text):
	_character_name = new_text
	OD.DungeonSettings.set_name(new_text)

func _select_hero(selection):
	_selected_hero = selection
	OD.DungeonSettings.set_hero(selection)
			
