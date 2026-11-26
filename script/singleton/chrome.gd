extends Node

signal input_mode_changed(gamepad_active)

const JOY_MOTION_THRESHOLD = 0.35

var hidden_button_style = null
var deselected_button_style = null
var _gamepad_active = false

func is_gamepad_active():
	return _gamepad_active

func set_gamepad_active(active):
	var next_state = bool(active)
	if _gamepad_active == next_state:
		return
	_gamepad_active = next_state
	input_mode_changed.emit(_gamepad_active)

func _input(event):
	if event is InputEventJoypadButton and event.pressed:
		set_gamepad_active(true)
	elif event is InputEventJoypadMotion and abs(event.axis_value) >= JOY_MOTION_THRESHOLD:
		set_gamepad_active(true)
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		set_gamepad_active(false)

func attach_focus_ring(control):
	if control == null or not is_instance_valid(control):
		return control
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	if control.has_node("_FocusRing"):
		return control
	var ring = ReferenceRect.new()
	ring.name = "_FocusRing"
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.border_color = Color(1.0, 0.85, 0.30, 0.95)
	ring.border_width = 3.0
	ring.editor_only = false
	ring.visible = control.has_focus() and _gamepad_active
	control.add_child(ring)
	var update_ring = func():
		if is_instance_valid(ring) and is_instance_valid(control):
			ring.visible = _gamepad_active and control.has_focus()
	control.focus_entered.connect(update_ring)
	control.focus_exited.connect(update_ring)
	var mode_handler = func(_active): update_ring.call()
	input_mode_changed.connect(mode_handler)
	control.tree_exited.connect(func():
		if input_mode_changed.is_connected(mode_handler):
			input_mode_changed.disconnect(mode_handler)
	)
	return control

func button(textures):
	var node = TextureButton.new()
	for key in textures.keys():
		node['texture_'+key] = textures[key]
	node.offset_left = -(textures.normal.get_width()/2)
	node.offset_top = -(textures.normal.get_height()/2)	
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	attach_focus_ring(node)
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
	button.focus_entered.connect(func():
		if _gamepad_active:
			highlight(button)
	)
	button.focus_exited.connect(func():
		if not button.is_hovered():
			darken(button)
	)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.texture_normal = texture
	attach_focus_ring(button)
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
	attach_focus_ring(node)
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
	attach_focus_ring(button)
	return button
