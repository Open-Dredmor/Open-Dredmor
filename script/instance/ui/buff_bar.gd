extends Control

class_name BuffBar

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const BAR_OFFSET_LEFT = -460
const BAR_OFFSET_TOP = 12
const BAR_OFFSET_RIGHT = -12
const BAR_OFFSET_BOTTOM = 84
const ROW_SEPARATION = 6

const BADGE_MIN_SIZE = Vector2(44, 52)
const BADGE_BORDER_WIDTH = 2
const BADGE_CONTENT_MARGIN = 4
const BADGE_BOX_SEPARATION = 2
const BADGE_ICON_SIZE = Vector2(32, 32)
const BADGE_FONT_SIZE = 11

var _player = null
var _row = null

func init(player):
	_player = player
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = BAR_OFFSET_LEFT
	offset_top = BAR_OFFSET_TOP
	offset_right = BAR_OFFSET_RIGHT
	offset_bottom = BAR_OFFSET_BOTTOM
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_END
	_row.add_theme_constant_override("separation", ROW_SEPARATION)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)

	if _player != null:
		if _player.has_signal("buffs_changed"):
			_player.buffs_changed.connect(refresh)
		if _player.has_signal("stats_changed"):
			_player.stats_changed.connect(refresh)
	refresh()
	return self

func _make_badge_style(is_bad):
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.14, 0.08, 0.08, 0.88) if is_bad else Color(0.09, 0.14, 0.18, 0.88)
	box.border_color = Color(0.85, 0.25, 0.2, 0.95) if is_bad else Color(0.35, 0.72, 0.95, 0.95)
	box.set_border_width_all(BADGE_BORDER_WIDTH)
	box.set_content_margin_all(BADGE_CONTENT_MARGIN)
	return box

func _add_badge(title, icon_path, counter_text, tooltip_string, is_bad, on_click = Callable()):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = BADGE_MIN_SIZE
	panel.add_theme_stylebox_override("panel", _make_badge_style(is_bad))
	panel.tooltip_text = tooltip_string

	var badge_box = VBoxContainer.new()
	badge_box.add_theme_constant_override("separation", BADGE_BOX_SEPARATION)
	panel.add_child(badge_box)

	var icon_texture = UiHelpers.load_texture(icon_path)
	if icon_texture != null:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.custom_minimum_size = BADGE_ICON_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge_box.add_child(icon_rect)
	else:
		var fallback = Label.new()
		fallback.text = title.substr(0, 4)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
		badge_box.add_child(fallback)

	var duration_label = Label.new()
	duration_label.text = counter_text
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duration_label.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
	badge_box.add_child(duration_label)

	if on_click.is_valid():
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
				on_click.call()
		)

	_row.add_child(panel)

func refresh():
	if _row == null or _player == null or not is_instance_valid(_player):
		return
	UiHelpers.clear_children(_row)

	for buff in _player.get_active_buffs():
		var buff_name = str(buff.get("name", "Buff"))
		var is_bad = bool(buff.get("bad", false))
		var parts = []
		if bool(buff.get("use_timer", false)):
			parts.append(str(int(buff.get("remaining_turns", 0))) + "t")
		if int(buff.get("brittle_remaining", 0)) > 0:
			parts.append("B:" + str(int(buff.get("brittle_remaining", 0))))
		if int(buff.get("attacks_remaining", 0)) > 0:
			parts.append("A:" + str(int(buff.get("attacks_remaining", 0))))
		if int(buff.get("stacks", 1)) > 1:
			parts.append("x" + str(int(buff.get("stacks", 1))))
		var counter_text = " ".join(parts) if not parts.is_empty() else "ON"
		var tooltip_string = buff_name
		if str(buff.get("description", "")) != "":
			tooltip_string += "\n" + str(buff.get("description", ""))
		if bool(buff.get("removable", false)) and not is_bad:
			tooltip_string += "\n(Click to dismiss)"
			var dismiss_callback = func(): _player.dismiss_buff(buff_name)
			_add_badge(buff_name, str(buff.get("icon", "")), counter_text, tooltip_string, is_bad, dismiss_callback)
		else:
			_add_badge(buff_name, str(buff.get("icon", "")), counter_text, tooltip_string, is_bad)

	for dot in _player.get_active_dots():
		var dot_spell = str(dot.get("spell", "DoT"))
		var remaining_turns = int(dot.get("remaining_turns", 0))
		_add_badge(dot_spell, "", str(remaining_turns) + "t", "DoT: " + dot_spell + " (" + str(remaining_turns) + " turns)", true)

	var flags = _player.get_status_flags()
	for flag_key in flags.keys():
		var turns = int(flags[flag_key])
		_add_badge(str(flag_key), "", str(turns) + "t", "Status: " + str(flag_key) + " (" + str(turns) + " turns)", true)
