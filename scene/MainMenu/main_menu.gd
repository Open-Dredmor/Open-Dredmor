extends Control

var background_image_index = 0
var background_images = []

func load_background_image():	
	$Background.texture = background_images[background_image_index]
	$Background.rect_min_size = Vector2($Background.texture.get_width(), $Background.texture.get_height())

func _ready():
	background_images = Assets.main_menu_backgrounds()
	
	load_background_image()
	
	var menu_chrome = $Background/MenuChrome
	menu_chrome.texture = Assets.main_menu_chrome()
	menu_chrome.rect_min_size = Vector2(menu_chrome.texture.get_width(), menu_chrome.texture.get_height())
	menu_chrome.anchor_left = .8
	menu_chrome.anchor_top = .1
		
	var background_button = $Background/MenuChrome/BackgroundButton
	Chrome.button(background_button, Assets.main_menu_background_button())
	background_button.anchor_left = .5
	background_button.anchor_top = .89
	background_button.margin_left = -(background_button.texture_normal.get_width()/2)
	background_button.margin_top = -(background_button.texture_normal.get_height()/2)	
	
	var quit_button = TextureButton.new()
	Chrome.button(quit_button, Assets.main_menu_quit_button())
	quit_button.anchor_left = .5
	quit_button.anchor_top = .78
	quit_button.margin_left = -(quit_button.texture_normal.get_width()/2)
	quit_button.margin_top = -(quit_button.texture_normal.get_height()/2)	
	quit_button.connect("pressed",self,"_on_QuitButton_pressed")
	menu_chrome.add_child(quit_button)
	
	$MusicPlayer.stream = Assets.main_menu_music()
	$MusicPlayer.play()
	

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_BackgroundButton_pressed():
	background_image_index += 1
	if background_image_index > (background_images.size() - 1):
		background_image_index = 0
	load_background_image()
