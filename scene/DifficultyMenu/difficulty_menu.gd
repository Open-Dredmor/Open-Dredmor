extends Control

func _ready():
	call_deferred("_build_gui")
	
func _build_gui():
	var assets = Assets.difficulty_menu()
	var difficulty_menu = get_node("../Container")
	difficulty_menu.set_size(Settings.display_size())
	
	var header = HBoxContainer.new()	
	difficulty_menu.add_child(header)
	
	var back_button = TextureButton.new()
	Chrome.button(back_button, assets.textures.back_button)
	back_button.connect("pressed",self,"_on_BackButton_pressed")
	header.add_child(back_button)
	
	var header_title = Panel.new()		
	header.add_child(header_title)
	
	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_title.add_child(header_background)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.choose_header
	header_title.add_child(header_text)
	
	header_title.set_size(Vector2(header_background.texture.get_width(), header_background.texture.get_height()))
	
	var done_button = TextureButton.new()
	Chrome.button(done_button, assets.textures.done_button)
	done_button.connect("pressed",self,"_on_DoneButton_pressed")
	header.add_child(done_button)
	
	var options_form = TextureRect.new()
	options_form.texture = assets.textures.options_form
	options_form.rect_min_size = Vector2(options_form.texture.get_width(), options_form.texture.get_height())
	options_form.anchor_left = .5
	options_form.anchor_top = .5
	options_form.margin_left = -(options_form.texture.get_width()/2)	
	options_form.margin_top = -(options_form.texture.get_height()/2)
	difficulty_menu.add_child(options_form)	

func _on_DoneButton_pressed():
	# TODO Implement
	print("Not yet implemented")
	pass

func _on_BackButton_pressed():
	Scenes.goto(Scenes.MainMenu)
