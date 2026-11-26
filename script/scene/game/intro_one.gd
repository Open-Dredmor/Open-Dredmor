extends Control

static func init_container():
	return Control.new()

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	var assets = OD.Assets.intro()
	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())
	
	var horizontal = HBoxContainer.new()
	horizontal.alignment = BoxContainer.ALIGNMENT_CENTER
	horizontal.anchor_right = 1
	horizontal.anchor_bottom = 1
	container.add_child(horizontal)
	
	var vertical = VBoxContainer.new()
	vertical.alignment = BoxContainer.ALIGNMENT_CENTER
	vertical.anchor_right = 1
	vertical.anchor_bottom = 1
	horizontal.add_child(vertical)
	
	var info_graphic = TextureRect.new()
	info_graphic.texture = assets.textures.primary
	vertical.add_child(info_graphic)
	
	var next_button = OD.Chrome.invisible_button()	
	next_button.pressed.connect(_on_NextButton_pressed)	
	next_button.anchor_bottom = 1
	next_button.anchor_right = 1
	container.add_child(next_button)
	next_button.call_deferred("grab_focus")

func _unhandled_input(event):
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]:
			get_viewport().set_input_as_handled()
			_on_NextButton_pressed()

func _on_NextButton_pressed():
	OD.Scenes.goto(OD.Scenes.INTRO_TWO)
