extends Node

func button(node, textures):
	node.texture_normal = textures.normal
	node.texture_hover = textures.hover
	node.texture_pressed = textures.pressed
	node.margin_left = -(textures.normal.get_width()/2)
	node.margin_top = -(textures.normal.get_height()/2)	
