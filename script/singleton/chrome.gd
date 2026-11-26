extends Node

var hidden_button_style = null
var deselected_button_style = null

func button(textures):
	var node = TextureButton.new()
	for key in textures.keys():
		node['texture_'+key] = textures[key]
	node.offset_left = -(textures.normal.get_width()/2)
	node.offset_top = -(textures.normal.get_height()/2)	
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return node

var highlight_color = Color(1,1,1,1)
func highlight(node):
	node.set_modulate(highlight_color)

var darken_color = Color(0.5,0.5,0.5,1)
func darken(node):
	node.set_modulate(darken_color)

func highlight_on_hover_button(texture):
	var button = TextureButton.new()
	button.set_modulate(darken_color)
	button.mouse_entered.connect(highlight.bind(button))
	button.mouse_exited.connect(darken.bind(button))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.texture_normal = texture
	return button
	
func invisible_button():
	var node = Button.new()
	if hidden_button_style == null:
		hidden_button_style = StyleBoxFlat.new()
		hidden_button_style.bg_color = Color(0,0,0,0)
	node.add_theme_stylebox_override("normal",hidden_button_style)
	node.add_theme_stylebox_override("hover",hidden_button_style)
	node.add_theme_stylebox_override("focus",hidden_button_style)
	node.add_theme_stylebox_override("pressed",hidden_button_style)
	node.add_theme_stylebox_override("disabled",hidden_button_style)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return node

func parchment_button(text_value, font, text_color, textures = null, font_size = 20):
	var button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(152, 40)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	if textures != null and textures.get("normal", null) != null:
		for state in ["normal", "hover", "pressed"]:
			var state_texture = textures.get(state, textures.normal)
			var texture_box = StyleBoxTexture.new()
			texture_box.texture = state_texture
			texture_box.texture_margin_left = 18
			texture_box.texture_margin_right = 18
			texture_box.texture_margin_top = 10
			texture_box.texture_margin_bottom = 10
			texture_box.content_margin_left = 22
			texture_box.content_margin_right = 22
			texture_box.content_margin_top = 6
			texture_box.content_margin_bottom = 6
			button.add_theme_stylebox_override(state, texture_box)
			if state == "normal":
				button.add_theme_stylebox_override("focus", texture_box)
	else:
		var normal_box = StyleBoxFlat.new()
		normal_box.bg_color = Color(0.84, 0.76, 0.63, 1.0)
		normal_box.border_color = Color(0.45, 0.34, 0.24, 1.0)
		normal_box.set_border_width_all(2)
		normal_box.content_margin_left = 22
		normal_box.content_margin_right = 22
		normal_box.content_margin_top = 6
		normal_box.content_margin_bottom = 6
		var hover_box = normal_box.duplicate()
		hover_box.bg_color = Color(0.91, 0.84, 0.71, 1.0)
		var pressed_box = normal_box.duplicate()
		pressed_box.bg_color = Color(0.75, 0.66, 0.53, 1.0)
		button.add_theme_stylebox_override("normal", normal_box)
		button.add_theme_stylebox_override("hover", hover_box)
		button.add_theme_stylebox_override("pressed", pressed_box)
		button.add_theme_stylebox_override("focus", normal_box)
	return button
