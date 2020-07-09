extends Control

var background_images = [
	"ui/dredmor_main_big_org.png",
	"expansion/ui/dredmor_main_big.png",
	"expansion2/ui/dredmor_main_big.png",
	"expansion3/ui/dredmor_main_big.png"
]

var background_image_index = 0

func load_background_image():
	var bg_image = Util.load_image(background_images[background_image_index])
	$Background.texture = bg_image
	$Background.rect_min_size = Vector2(bg_image.get_width(), bg_image.get_height())

func _ready():
	load_background_image()
	
	var bg_button_image = Util.load_image("ui/menus/main_bg_button0.png")
	$BackgroundButton.texture_normal = bg_button_image
	$BackgroundButton.texture_hover = Util.load_image("ui/menus/main_bg_button1.png")
	$BackgroundButton.texture_pressed = Util.load_image("ui/menus/main_bg_button2.png")
	

func _on_BackgroundButton_pressed():
	background_image_index += 1
	if background_image_index > (background_images.size() - 1):
		background_image_index = 0
	load_background_image()
