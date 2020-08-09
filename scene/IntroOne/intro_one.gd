extends Control

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	var assets = Assets.intro()
	var container = get_node("/root/Container")
	container.set_size(Settings.display_size())
	
	var horizontal = HBoxContainer.new()
	horizontal.alignment = BoxContainer.ALIGN_CENTER
	horizontal.anchor_right = 1
	horizontal.anchor_bottom = 1
	container.add_child(horizontal)
	
	var vertical = VBoxContainer.new()
	vertical.alignment = BoxContainer.ALIGN_CENTER
	vertical.anchor_right = 1
	vertical.anchor_bottom = 1
	horizontal.add_child(vertical)
	
	var info_graphic = TextureRect.new()
	info_graphic.texture = assets.textures.primary
	vertical.add_child(info_graphic)
	
	var next_button = Chrome.invisible_button()	
	next_button.connect("pressed",self,"_on_NextButton_pressed")	
	next_button.anchor_bottom = 1
	next_button.anchor_right = 1
	container.add_child(next_button)

func _on_NextButton_pressed():
	Scenes.goto(Scenes.INTRO_TWO)
