extends Control

class_name BuffBar

var _player = null
var _row = null

func init(player):
	_player = player
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -460
	offset_top = 12
	offset_right = -12
	offset_bottom = 84
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_END
	_row.add_theme_constant_override("separation", 6)
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
	box.set_border_width_all(2)
	box.set_content_margin_all(4)
	return box

func _load_icon_texture(icon_path):
	if icon_path == "" or OD.Load == null:
		return null
	if OD.Load.exists(icon_path):
		return OD.Load.image(icon_path)
	return null

func _add_badge(title, icon_path, counter_text, tooltip_str, is_bad, on_click = Callable()):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 52)
	panel.add_theme_stylebox_override("panel", _make_badge_style(is_bad))
	panel.tooltip_text = tooltip_str

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var tex = _load_icon_texture(icon_path)
	if tex != null:
		var icon_rect = TextureRect.new()
		icon_rect.texture = tex
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vbox.add_child(icon_rect)
	else:
		var fallback = Label.new()
		fallback.text = title.substr(0, 4)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 11)
		vbox.add_child(fallback)

	var dur_lbl = Label.new()
	dur_lbl.text = counter_text
	dur_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dur_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(dur_lbl)

	if on_click.is_valid():
		panel.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and (ev.button_index == MOUSE_BUTTON_LEFT or ev.button_index == MOUSE_BUTTON_RIGHT):
				on_click.call()
		)

	_row.add_child(panel)

func refresh():
	if _row == null or _player == null or not is_instance_valid(_player):
		return
	for child in _row.get_children():
		child.queue_free()

	for buff in _player.get_active_buffs():
		var b_name = str(buff.get("name", "Buff"))
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
		var counter_str = " ".join(parts) if not parts.is_empty() else "ON"
		var tip = b_name
		if str(buff.get("description", "")) != "":
			tip += "\n" + str(buff.get("description", ""))
		if bool(buff.get("removable", false)) and not is_bad:
			tip += "\n(Click to dismiss)"
			var dismiss_cb = func(): _player.dismiss_buff(b_name)
			_add_badge(b_name, str(buff.get("icon", "")), counter_str, tip, is_bad, dismiss_cb)
		else:
			_add_badge(b_name, str(buff.get("icon", "")), counter_str, tip, is_bad)

	for dot in _player.get_active_dots():
		var dot_spell = str(dot.get("spell", "DoT"))
		var rem = int(dot.get("remaining_turns", 0))
		_add_badge(dot_spell, "", str(rem) + "t", "DoT: " + dot_spell + " (" + str(rem) + " turns)", true)

	var flags = _player.get_status_flags()
	for flag_key in flags.keys():
		var turns = int(flags[flag_key])
		_add_badge(str(flag_key), "", str(turns) + "t", "Status: " + str(flag_key) + " (" + str(turns) + " turns)", true)
