extends Node

var hidden_button_style = null
var deselected_button_style = null

func button(node, textures):
	for key in textures.keys():
		node['texture_'+key] = textures[key]
	node.margin_left = -(textures.normal.get_width()/2)
	node.margin_top = -(textures.normal.get_height()/2)	
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

var highlight_color = Color(1,1,1,1)
func highlight(node):
	node.set_modulate(highlight_color)

var darken_color = Color(0.5,0.5,0.5,1)
func darken(node):
	node.set_modulate(darken_color)

func highlight_on_hover_button(texture):
	var button = TextureButton.new()
	button.set_modulate(darken_color)
	button.connect("mouse_entered", self, "highlight", [button])
	button.connect("mouse_exited", self, "darken", [button])
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.texture_normal = texture
	return button
	
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
