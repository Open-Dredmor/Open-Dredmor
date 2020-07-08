extends Control

func _ready():
	var bg_image = Util.load_image("ui/dredmor_main_big_org.png")
	$Background.texture = bg_image
	$Background.rect_min_size = Vector2(bg_image.get_width(), bg_image.get_height())
	
	var bg_button_image = Util.load_image("ui/menus/main_bg_button0.png")
	$BackgroundButton.texture_normal = bg_button_image
	$BackgroundButton.texture_hover = Util.load_image("ui/menus/main_bg_button1.png")
	$BackgroundButton.texture_pressed = Util.load_image("ui/menus/main_bg_button2.png")
	$BackgroundButton.rect_min_size = Vector2(bg_button_image.get_width(), bg_button_image.get_height())
	
