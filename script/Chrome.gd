extends Node

var hidden_button_style = null

func button(node, textures):
	node.texture_normal = textures.normal
	node.texture_hover = textures.hover
	node.texture_pressed = textures.pressed
	node.margin_left = -(textures.normal.get_width()/2)
	node.margin_top = -(textures.normal.get_height()/2)	
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func invisible_button(node):
	if hidden_button_style == null:
		hidden_button_style = StyleBoxFlat.new()
		hidden_button_style.bg_color = Color(0,0,0,0)
	node.add_stylebox_override("normal",hidden_button_style)
	node.add_stylebox_override("hover",hidden_button_style)
	node.add_stylebox_override("focus",hidden_button_style)
	node.add_stylebox_override("pressed",hidden_button_style)
	node.add_stylebox_override("disabled",hidden_button_style)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
