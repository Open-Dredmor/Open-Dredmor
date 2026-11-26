extends RefCounted

const FloatingWindowScript = preload("res://script/instance/ui/floating_window.gd")
const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)

static func dialog_font():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	return dialog_assets.font if dialog_assets != null else null

static func load_texture(path, cache = null):
	if path == "" or OD.Load == null:
		return null
	if cache != null and cache.has(path):
		return cache[path]
	var texture = OD.Load.image(path) if OD.Load.exists(path) else null
	if cache != null:
		cache[path] = texture
	return texture

static func viewport_size(node, default_size = DEFAULT_VIEWPORT_SIZE):
	if node != null and is_instance_valid(node):
		var viewport = node.get_viewport()
		if viewport != null:
			return viewport.get_visible_rect().size
	return default_size

static func style_label(label, font_size, font_color, font = null, outline_size = 0):
	var resolved_font = font if font != null else dialog_font()
	if resolved_font != null:
		label.add_theme_font_override("font", resolved_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	if outline_size > 0:
		label.add_theme_constant_override("outline_size", outline_size)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	return label

static func make_texture_button(texture_paths, minimum_size, cache = null):
	var button = TextureButton.new()
	button.custom_minimum_size = minimum_size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if texture_paths.has("normal"):
		button.texture_normal = load_texture(texture_paths.normal, cache)
	if texture_paths.has("hover"):
		button.texture_hover = load_texture(texture_paths.hover, cache)
	if texture_paths.has("pressed"):
		button.texture_pressed = load_texture(texture_paths.pressed, cache)
	if texture_paths.has("disabled"):
		button.texture_disabled = load_texture(texture_paths.disabled, cache)
	return button

static func make_close_button(dialog_assets, on_pressed, scale_factor = 2.0):
	var close_button = OD.Chrome.button(dialog_assets.textures.close)
	var scaled_size = close_button.texture_normal.get_size() * scale_factor
	close_button.ignore_texture_size = true
	close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_button.custom_minimum_size = scaled_size
	close_button.size = scaled_size
	close_button.offset_left = 0
	close_button.offset_top = 0
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if on_pressed.is_valid():
		close_button.pressed.connect(on_pressed)
	return close_button

static func create_panel_style(background_texture, texture_margins, content_margins, fallback_background = Color(0.16, 0.13, 0.10, 0.96), fallback_border = Color(0.62, 0.50, 0.32, 0.95), fallback_border_width = 3, fallback_content_margin = 28):
	if background_texture != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = background_texture
		if typeof(texture_margins) == TYPE_DICTIONARY:
			style_box.texture_margin_left = texture_margins.get("left", 44)
			style_box.texture_margin_right = texture_margins.get("right", 44)
			style_box.texture_margin_top = texture_margins.get("top", 44)
			style_box.texture_margin_bottom = texture_margins.get("bottom", 44)
		else:
			var margin_value = int(texture_margins)
			style_box.texture_margin_left = margin_value
			style_box.texture_margin_right = margin_value
			style_box.texture_margin_top = margin_value
			style_box.texture_margin_bottom = margin_value
		if typeof(content_margins) == TYPE_DICTIONARY:
			style_box.content_margin_left = content_margins.get("left", 36)
			style_box.content_margin_right = content_margins.get("right", 36)
			style_box.content_margin_top = content_margins.get("top", 30)
			style_box.content_margin_bottom = content_margins.get("bottom", 32)
		else:
			var content_value = int(content_margins)
			style_box.content_margin_left = content_value
			style_box.content_margin_right = content_value
			style_box.content_margin_top = content_value
			style_box.content_margin_bottom = content_value
		return style_box
	var fallback = StyleBoxFlat.new()
	fallback.bg_color = fallback_background
	fallback.border_color = fallback_border
	fallback.set_border_width_all(fallback_border_width)
	fallback.set_content_margin_all(fallback_content_margin)
	return fallback

static func create_modal_overlay(parent_node, backdrop_alpha = 0.45):
	var root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent_node.add_child(root_control)

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, backdrop_alpha)
	root_control.add_child(backdrop)
	return { root = root_control, backdrop = backdrop }

static func create_floating_window(parent_node, base_size, minimum_scale = 0.72, maximum_scale = 1.15, minimum_window_ratio = 0.65, vertical_factor = 0.45, margin = Vector2(80.0, 80.0)):
	var current_viewport_size = viewport_size(parent_node)
	var initial_scale = clamp(min((current_viewport_size.x - margin.x) / base_size.x, (current_viewport_size.y - margin.y) / base_size.y), minimum_scale, maximum_scale)
	var floating_window = FloatingWindowScript.new()
	floating_window.min_window_size = base_size * minimum_window_ratio
	floating_window.set_base_size(base_size, initial_scale)
	floating_window.position = Vector2((current_viewport_size.x - floating_window.size.x) * 0.5, max(24.0, (current_viewport_size.y - floating_window.size.y) * vertical_factor))
	parent_node.add_child(floating_window)
	return floating_window

static func create_tooltip(parent_node, minimum_width = 240, font_size = 14):
	var tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.z_index = 50
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.94)
	style.border_color = Color(0.68, 0.56, 0.34, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	tooltip_panel.add_theme_stylebox_override("panel", style)
	parent_node.add_child(tooltip_panel)

	var tooltip_label = Label.new()
	tooltip_label.custom_minimum_size = Vector2(minimum_width, 0)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style_label(tooltip_label, font_size, Color(0.95, 0.92, 0.85))
	tooltip_panel.add_child(tooltip_label)
	return { panel = tooltip_panel, label = tooltip_label }

static func position_tooltip(tooltip_panel, mouse_position, current_viewport_size, offset = Vector2(16, 16), screen_margin = 8.0, flip_margin = 12.0):
	if tooltip_panel == null or not tooltip_panel.visible:
		return
	var tooltip_size = tooltip_panel.size
	var target_position = mouse_position + offset
	if target_position.x + tooltip_size.x + screen_margin > current_viewport_size.x:
		target_position.x = max(screen_margin, mouse_position.x - tooltip_size.x - flip_margin)
	if target_position.y + tooltip_size.y + screen_margin > current_viewport_size.y:
		target_position.y = max(screen_margin, current_viewport_size.y - tooltip_size.y - screen_margin)
	tooltip_panel.position = target_position

static func clear_children(container):
	if container == null or not is_instance_valid(container):
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

static func invoke_callback(callbacks, key):
	if callbacks.has(key) and callbacks[key] is Callable and callbacks[key].is_valid():
		callbacks[key].call()
