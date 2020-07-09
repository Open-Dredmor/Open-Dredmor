extends Control

var background_image_index = 0
var background_images = []

func load_background_image():	
	var bg_image = background_images[background_image_index]
	$Background.texture = bg_image
	$Background.rect_min_size = Vector2(bg_image.get_width(), bg_image.get_height())

func _ready():
	background_images = Assets.main_menu_backgrounds()
	var button_images = Assets.main_menu_button()
	
	load_background_image()
	
	$BackgroundButton.texture_normal = button_images.normal
	$BackgroundButton.texture_hover = button_images.hover
	$BackgroundButton.texture_pressed = button_images.pressed
	
	$MusicPlayer.stream = Assets.main_menu_music()
	$MusicPlayer.play()
	

func _on_BackgroundButton_pressed():
	background_image_index += 1
	if background_image_index > (background_images.size() - 1):
		background_image_index = 0
	load_background_image()
