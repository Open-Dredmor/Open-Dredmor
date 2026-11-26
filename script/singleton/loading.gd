extends Node

var _layer = null
var _root = null
var _status_label = null
var _percent_label = null
var _progress_bar = null

func _ensure_ui():
	if _layer != null and is_instance_valid(_layer):
		return
	_layer = CanvasLayer.new()
	_layer.name = "LoadingOverlayLayer"
	_layer.layer = 120
	_layer.visible = false
	add_child(_layer)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.05, 0.04, 0.03, 1.0)
	_root.add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 190)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.09, 0.07, 0.94)
	panel_style.border_color = Color(0.62, 0.48, 0.28, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vertical_box = VBoxContainer.new()
	vertical_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vertical_box.add_theme_constant_override("separation", 14)
	panel.add_child(vertical_box)

	var title_label = Label.new()
	title_label.text = "Open Dredmor"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vertical_box.add_child(title_label)

	_status_label = Label.new()
	_status_label.text = "Loading..."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.84))
	vertical_box.add_child(_status_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(460, 22)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	var bar_background = StyleBoxFlat.new()
	bar_background.bg_color = Color(0.06, 0.05, 0.04, 1.0)
	bar_background.border_color = Color(0.45, 0.36, 0.24, 1.0)
	bar_background.set_border_width_all(1)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.68, 0.22, 0.16, 1.0)
	_progress_bar.add_theme_stylebox_override("background", bar_background)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	vertical_box.add_child(_progress_bar)

	_percent_label = Label.new()
	_percent_label.text = "0%"
	_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_percent_label.add_theme_font_size_override("font_size", 14)
	_percent_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	vertical_box.add_child(_percent_label)

func show_progress(status_text, percent):
	_ensure_ui()
	var clamped = clamp(float(percent), 0.0, 100.0)
	_status_label.text = str(status_text)
	_progress_bar.value = clamped
	_percent_label.text = str(int(round(clamped))) + "%"
	_layer.visible = true

func step(status_text, percent):
	show_progress(status_text, percent)
	if get_tree() != null:
		await get_tree().process_frame

func hide_loading():
	if _layer != null and is_instance_valid(_layer):
		_layer.visible = false
