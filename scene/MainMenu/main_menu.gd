extends Control

var assets = null
var main_menu = null
var background = null
var background_image_index = 0

func load_background_image():		
	background.texture = assets.textures.backgrounds[background_image_index]
	background.rect_size = Vector2(background.texture.get_width(), background.texture.get_height())

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	main_menu = get_node("../Container")
	main_menu.set_size(Settings.display_size())
	assets = Assets.main_menu()
	
	background = TextureRect.new()
	main_menu.add_child(background)		
	
	var menu_chrome = TextureRect.new()
	menu_chrome.texture = assets.textures.chrome
	menu_chrome.rect_min_size = Vector2(menu_chrome.texture.get_width(), menu_chrome.texture.get_height())
	menu_chrome.anchor_left = .8
	menu_chrome.anchor_top = .1	
	background.add_child(menu_chrome)
	
	var new_game_button = TextureButton.new()
	Chrome.button(new_game_button, assets.textures.new_game_button)
	new_game_button.anchor_left = .5
	new_game_button.anchor_top = .18
	new_game_button.connect("pressed",self,"_on_NewGameButton_pressed")
	menu_chrome.add_child(new_game_button)
	
	var load_game_button = TextureButton.new()
	Chrome.button(load_game_button, assets.textures.load_game_button)
	load_game_button.anchor_left = .5
	load_game_button.anchor_top = .28
	load_game_button.connect("pressed",self,"_on_LoadGameButton_pressed")
	menu_chrome.add_child(load_game_button)
	
	var settings_button = TextureButton.new()
	Chrome.button(settings_button, assets.textures.settings_button)
	settings_button.anchor_left = .5
	settings_button.anchor_top = .68
	settings_button.connect("pressed",self,"_on_SettingsButton_pressed")
	menu_chrome.add_child(settings_button)
	
	var quit_button = TextureButton.new()
	Chrome.button(quit_button, assets.textures.quit_button)
	quit_button.anchor_left = .5
	quit_button.anchor_top = .78
	quit_button.connect("pressed",self,"_on_QuitButton_pressed")
	menu_chrome.add_child(quit_button)
	
	var background_button = TextureButton.new()
	Chrome.button(background_button, assets.textures.background_button)
	background_button.anchor_left = .5
	background_button.anchor_top = .89
	background_button.connect("pressed", self, "_on_BackgroundButton_pressed")
	menu_chrome.add_child(background_button)
	
	Audio.play(assets.music.title)
	
	load_background_image()	

func _on_NewGameButton_pressed():
	Scenes.goto(Scenes.DifficultyMenu)
	pass
	
func _on_LoadGameButton_pressed():
	# TODO Implement
	print("Load game not yet implemented")
	pass

func _on_SettingsButton_pressed():
	Scenes.goto(Scenes.SettingsMenu)
	pass

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_BackgroundButton_pressed():
	background_image_index += 1
	if background_image_index > (assets.textures.backgrounds.size() - 1):
		background_image_index = 0
	load_background_image()
