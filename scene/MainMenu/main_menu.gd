extends Control

var background = null
var background_image_index = 0
var background_images = []

func load_background_image():	
	background.texture = background_images[background_image_index]
	background.rect_min_size = Vector2(background.texture.get_width(), background.texture.get_height())

func _ready():
	var main_menu = get_tree().get_root()
	background_images = Assets.main_menu_backgrounds()	
	background = TextureRect.new()
	
	main_menu.add_child(background)	
	load_background_image()	
	
	var menu_chrome = TextureRect.new()
	menu_chrome.texture = Assets.main_menu_chrome()
	menu_chrome.rect_min_size = Vector2(menu_chrome.texture.get_width(), menu_chrome.texture.get_height())
	menu_chrome.anchor_left = .8
	menu_chrome.anchor_top = .1	
	background.add_child(menu_chrome)
	
	var quit_button = TextureButton.new()
	Chrome.button(quit_button, Assets.main_menu_quit_button())
	quit_button.anchor_left = .5
	quit_button.anchor_top = .78
	quit_button.margin_left = -(quit_button.texture_normal.get_width()/2)
	quit_button.margin_top = -(quit_button.texture_normal.get_height()/2)	
	quit_button.connect("pressed",self,"_on_QuitButton_pressed")
	menu_chrome.add_child(quit_button)
	
	var background_button = TextureButton.new()
	Chrome.button(background_button, Assets.main_menu_background_button())
	background_button.anchor_left = .5
	background_button.anchor_top = .89
	background_button.margin_left = -(background_button.texture_normal.get_width()/2)
	background_button.margin_top = -(background_button.texture_normal.get_height()/2)	
	background_button.connect("pressed", self, "_on_BackgroundButton_pressed")
	menu_chrome.add_child(background_button)
	
	var music_player = AudioStreamPlayer.new()	
	music_player.stream = Assets.main_menu_music()
	music_player.play()
	main_menu.add_child(music_player)

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_BackgroundButton_pressed():
	background_image_index += 1
	if background_image_index > (background_images.size() - 1):
		background_image_index = 0
	load_background_image()
