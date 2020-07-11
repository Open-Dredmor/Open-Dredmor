extends Control

func _ready():	
	call_deferred("_build_gui")
	
func _build_gui():
	DungeonSettings.reset()
	var assets = Assets.skills_menu()
	var container = get_node("../Container")
	container.set_size(Settings.display_size())

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.rect_size = Vector2(Settings.display_size().x, header_background.texture.get_height())
	container.add_child(header_background)
	
	var back_button = TextureButton.new()
	Chrome.button(back_button, assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.margin_left = 0
	back_button.margin_top = 0
	back_button.connect("pressed",self,"_on_BackButton_pressed")
	container.add_child(back_button)
	
	var header_text = TextureRect.new()
	header_text.texture = assets.textures.skills_header
	header_text.anchor_left = .5
	header_text.margin_left = - (header_text.texture.get_width()/2)
	container.add_child(header_text)	
	
	var done_button = TextureButton.new()
	Chrome.button(done_button, assets.textures.done_button)
	done_button.anchor_left = 1
	done_button.anchor_top = 0
	done_button.margin_left = -done_button.texture_normal.get_width()
	done_button.margin_top = 0
	done_button.connect("pressed",self,"_on_DoneButton_pressed")
	container.add_child(done_button)	
		


func _on_DoneButton_pressed():
	# TODO Implement
	print("Not yet implemented")
	pass

func _on_BackButton_pressed():
	Scenes.goto(Scenes.DifficultyMenu)
