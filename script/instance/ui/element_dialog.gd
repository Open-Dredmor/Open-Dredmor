extends CanvasLayer

var _on_close_callback = null
var _on_broken_callback = null

func show_element_dialog(element, zorkmids_ref, lutefisk_ref, on_close = Callable(), on_broken = Callable()):
	layer = 10
	_on_close_callback = on_close
	_on_broken_callback = on_broken
	var result = element.interact()
	_build_from_result(element, result, zorkmids_ref, lutefisk_ref)

func show_custom_result(result, zorkmids_ref, lutefisk_ref, element = null, on_close = Callable(), on_broken = Callable()):
	layer = 10
	_on_close_callback = on_close
	_on_broken_callback = on_broken
	_build_from_result(element, result, zorkmids_ref, lutefisk_ref)

func _dismiss():
	if _on_close_callback.is_valid():
		_on_close_callback.call()
	queue_free()

func _style_label(label, font, font_size, color, outline_size = 0):
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline_size > 0:
		label.add_theme_constant_override("outline_size", outline_size)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))

func _build_from_result(element, result, zorkmids_ref, lutefisk_ref):
	var dialog_assets = OD.Assets.dialog()
	var kind = result.get("kind", "info")
	match kind:
		"krong":
			_build_krong_window(result, dialog_assets)
		"krong_select":
			_build_krong_select_window(element, result, zorkmids_ref, lutefisk_ref, dialog_assets)
		"lutefisk":
			_build_lutefisk_window(element, result, lutefisk_ref, dialog_assets)
		_:
			_build_standard_window(element, result, zorkmids_ref, dialog_assets)

func _create_base_overlay(bg_texture, custom_size = null):
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_ctrl)

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.45)
	root_ctrl.add_child(backdrop)

	var win_size = custom_size if custom_size != null else Vector2(bg_texture.get_width(), bg_texture.get_height())
	var panel = null
	if custom_size != null:
		var nine_patch = NinePatchRect.new()
		nine_patch.texture = bg_texture
		nine_patch.patch_margin_left = 24
		nine_patch.patch_margin_right = 24
		nine_patch.patch_margin_top = 24
		nine_patch.patch_margin_bottom = 24
		panel = nine_patch
	else:
		var tex_rect = TextureRect.new()
		tex_rect.texture = bg_texture
		panel = tex_rect
	panel.custom_minimum_size = win_size
	panel.size = win_size
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.offset_left = -win_size.x / 2.0
	panel.offset_top = -win_size.y / 2.0
	panel.offset_right = win_size.x / 2.0
	panel.offset_bottom = win_size.y / 2.0
	root_ctrl.add_child(panel)
	return panel

func _add_close_button(panel, dialog_assets):
	var close_btn = OD.Chrome.button(dialog_assets.textures.close)
	var scaled_size = close_btn.texture_normal.get_size() * 2.0
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.custom_minimum_size = scaled_size
	close_btn.size = scaled_size
	close_btn.anchor_left = 1.0
	close_btn.anchor_top = 0.0
	close_btn.offset_left = -scaled_size.x - 8
	close_btn.offset_top = 8
	close_btn.pressed.connect(_dismiss)
	panel.add_child(close_btn)

func _build_krong_select_window(element, result, zorkmids_ref, lutefisk_ref, dialog_assets):
	var ink_color = Color(0.12, 0.08, 0.05)
	var panel = _create_base_overlay(dialog_assets.textures.alert_bigger, Vector2(460, 380))
	_add_close_button(panel, dialog_assets)

	var content_vbox = VBoxContainer.new()
	content_vbox.anchor_right = 1.0
	content_vbox.anchor_bottom = 1.0
	content_vbox.offset_left = 28
	content_vbox.offset_top = 24
	content_vbox.offset_right = -28
	content_vbox.offset_bottom = -68
	content_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(content_vbox)

	var title_label = Label.new()
	title_label.text = result.get("title", "Anvil of Krong")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, dialog_assets.font, 26, ink_color)
	content_vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, 18, ink_color)
	content_vbox.add_child(msg_label)

	var candidate_items = []
	for category_name in ["weapon", "armour"]:
		for entry in OD.Database.get_items_by_category(category_name):
			if entry.icon != "" and OD.Load.exists(entry.icon):
				candidate_items.append(entry)
				if candidate_items.size() >= 4:
					break
		if candidate_items.size() >= 4:
			break
	if candidate_items.is_empty():
		candidate_items.append({ name = "Wooden Sword", icon = "items/sword_wooden.png" })

	var items_scroll = ScrollContainer.new()
	items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_vbox.add_child(items_scroll)

	var items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", 8)
	items_scroll.add_child(items_vbox)

	for gear in candidate_items:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		items_vbox.add_child(row)

		if gear.icon != "" and OD.Load.exists(gear.icon):
			var icon_rect = TextureRect.new()
			icon_rect.texture = OD.Load.image(gear.icon)
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(icon_rect)

		var name_label = Label.new()
		name_label.text = gear.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(name_label, dialog_assets.font, 18, ink_color)
		row.add_child(name_label)

		var select_btn = Button.new()
		select_btn.text = "Enchant"
		select_btn.pressed.connect(func():
			var next_res = element.enchant_item_on_anvil(gear) if element != null else { kind = "krong", cursed = false, icon = gear.icon, message = gear.name + "\n\n+1 Burliness" }
			for child in get_children():
				child.queue_free()
			_build_from_result(element, next_res, zorkmids_ref, lutefisk_ref)
		)
		row.add_child(select_btn)

	var cancel_btn = OD.Chrome.button(dialog_assets.textures.ok)
	cancel_btn.anchor_left = 0.5
	cancel_btn.anchor_top = 1.0
	cancel_btn.offset_left = -cancel_btn.texture_normal.get_width() / 2.0
	cancel_btn.offset_top = -cancel_btn.texture_normal.get_height() - 14
	cancel_btn.pressed.connect(_dismiss)
	panel.add_child(cancel_btn)

func _build_krong_window(result, dialog_assets):
	var is_cursed = result.get("cursed", false)
	var krong_texture = dialog_assets.textures.krong_displeased if is_cursed else dialog_assets.textures.krong_pleased
	var dismiss_textures = dialog_assets.textures.shucks if is_cursed else dialog_assets.textures.awesome
	var frame_size = Vector2(560, 440)
	var frame_panel = _create_base_overlay(dialog_assets.textures.alert_bigger, frame_size)
	_add_close_button(frame_panel, dialog_assets)

	var panel = TextureRect.new()
	panel.texture = krong_texture
	panel.position = Vector2(20, 20)
	panel.size = Vector2(krong_texture.get_width(), krong_texture.get_height())
	frame_panel.add_child(panel)

	var icon_path = result.get("icon", "")
	if icon_path != "" and OD.Load.exists(icon_path):
		var slot_icon = TextureRect.new()
		slot_icon.texture = OD.Load.image(icon_path)
		slot_icon.position = Vector2(154, 174)
		slot_icon.size = Vector2(56, 56)
		slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(slot_icon)

	var stats_box = VBoxContainer.new()
	stats_box.position = Vector2(298, 200)
	stats_box.size = Vector2(184, 164)
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(stats_box)

	var msg_label = Label.new()
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, 18, Color(0.95, 0.9, 0.8), 2)
	stats_box.add_child(msg_label)

	var dismiss_btn = OD.Chrome.button(dismiss_textures)
	dismiss_btn.position = Vector2(182 - dismiss_btn.texture_normal.get_width() / 2.0, 356)
	dismiss_btn.pressed.connect(_dismiss)
	panel.add_child(dismiss_btn)

func _build_lutefisk_window(element, result, lutefisk_ref, dialog_assets):
	var panel = _create_base_overlay(dialog_assets.textures.lutefisk_bg)
	_add_close_button(panel, dialog_assets)

	var reward_icon = TextureRect.new()
	reward_icon.position = Vector2(228, 106)
	reward_icon.size = Vector2(64, 64)
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_icon.modulate.a = 0.0
	panel.add_child(reward_icon)

	var msg_label = Label.new()
	msg_label.position = Vector2(110, 174)
	msg_label.size = Vector2(300, 78)
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, 20, Color(0.96, 0.94, 0.86), 3)
	panel.add_child(msg_label)

	var offer_btn = Button.new()
	offer_btn.position = Vector2(160, 260)
	offer_btn.size = Vector2(200, 32)
	offer_btn.text = "Offer 5 Lutefisk (Have: " + str(lutefisk_ref.value) + ")"
	offer_btn.pressed.connect(func():
		if element == null:
			return
		var offer_amount = min(5, lutefisk_ref.value)
		lutefisk_ref.value -= offer_amount
		var offer_res = element.offer_lutefisk(offer_amount)
		msg_label.text = offer_res.message
		if offer_res.icon != "" and OD.Load.exists(offer_res.icon):
			reward_icon.texture = OD.Load.image(offer_res.icon)
			reward_icon.tooltip_text = offer_res.tooltip
			reward_icon.modulate.a = 1.0
		else:
			reward_icon.texture = null
			reward_icon.tooltip_text = ""
			reward_icon.modulate.a = 0.0
		offer_btn.text = "Offer 5 Lutefisk (Have: " + str(lutefisk_ref.value) + ")"
	)
	panel.add_child(offer_btn)

	var ok_btn = OD.Chrome.button(dialog_assets.textures.ok)
	ok_btn.anchor_left = 0.5
	ok_btn.anchor_top = 1.0
	ok_btn.offset_left = -ok_btn.texture_normal.get_width() / 2.0
	ok_btn.offset_top = -ok_btn.texture_normal.get_height() - 18
	ok_btn.pressed.connect(_dismiss)
	panel.add_child(ok_btn)

func _build_standard_window(element, result, zorkmids_ref, dialog_assets):
	var kind = result.get("kind", "info")
	var ink_color = Color(0.12, 0.08, 0.05)
	var bg_texture = dialog_assets.textures.alert_bigger if kind == "vending" else dialog_assets.textures.alert
	var custom_size = Vector2(580, 520) if kind == "vending" else null

	var panel = _create_base_overlay(bg_texture, custom_size)
	_add_close_button(panel, dialog_assets)

	var content_vbox = VBoxContainer.new()
	content_vbox.anchor_right = 1.0
	content_vbox.anchor_bottom = 1.0
	content_vbox.offset_left = 28
	content_vbox.offset_top = 24
	content_vbox.offset_right = -28
	content_vbox.offset_bottom = -68
	content_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(content_vbox)

	var title_label = Label.new()
	title_label.text = result.get("title", "Element")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, dialog_assets.font, 26, ink_color)
	content_vbox.add_child(title_label)

	var icon_path = result.get("icon", "")
	if icon_path != "" and OD.Load.exists(icon_path):
		var item_icon = TextureRect.new()
		item_icon.texture = OD.Load.image(icon_path)
		item_icon.custom_minimum_size = Vector2(64, 64)
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_icon.tooltip_text = result.get("tooltip", "")
		content_vbox.add_child(item_icon)

	var msg_label = Label.new()
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, 20, ink_color)
	content_vbox.add_child(msg_label)

	if kind == "broken":
		if _on_broken_callback.is_valid():
			_on_broken_callback.call()
	elif kind == "vending":
		var zorkmid_label = Label.new()
		zorkmid_label.text = "Zorkmids: " + str(zorkmids_ref.value)
		zorkmid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(zorkmid_label, dialog_assets.font, 20, ink_color)
		content_vbox.add_child(zorkmid_label)

		var stock_scroll = ScrollContainer.new()
		stock_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stock_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stock_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_vbox.add_child(stock_scroll)

		var stock_vbox = VBoxContainer.new()
		stock_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stock_vbox.add_theme_constant_override("separation", 6)
		stock_scroll.add_child(stock_vbox)

		for item in result.get("stock", []):
			var item_row = HBoxContainer.new()
			item_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_row.add_theme_constant_override("separation", 10)
			stock_vbox.add_child(item_row)
			if item.has("icon") and item.icon != "" and OD.Load.exists(item.icon):
				var icon_rect = TextureRect.new()
				icon_rect.texture = OD.Load.image(item.icon)
				icon_rect.custom_minimum_size = Vector2(32, 32)
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				item_row.add_child(icon_rect)
			var item_label = Label.new()
			item_label.text = item.name + " (" + str(item.price) + " zm)"
			item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_style_label(item_label, dialog_assets.font, 18, ink_color)
			item_row.add_child(item_label)
			var buy_btn = OD.Chrome.button(dialog_assets.textures.buy)
			buy_btn.offset_left = 0
			buy_btn.offset_top = 0
			buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			buy_btn.pressed.connect(func():
				if zorkmids_ref.value >= item.price:
					zorkmids_ref.value -= item.price
					OD.Audio.play_sfx("item_purchase")
					zorkmid_label.text = "Zorkmids: " + str(zorkmids_ref.value)
					msg_label.text = "Purchased " + item.name + "!"
				else:
					OD.Audio.play_sfx("zorkmidslow1")
					msg_label.text = "Not enough Zorkmids!"
			)
			item_row.add_child(buy_btn)
	elif kind == "dredmorstatue":
		var smash_btn = Button.new()
		smash_btn.text = "Smash Statue"
		smash_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		smash_btn.pressed.connect(func():
			if element == null:
				return
			var broken_res = element.break_element()
			if _on_broken_callback.is_valid():
				_on_broken_callback.call()
			msg_label.text = broken_res.message
			smash_btn.disabled = true
		)
		content_vbox.add_child(smash_btn)

	var dismiss_btn = OD.Chrome.button(dialog_assets.textures.ok)
	dismiss_btn.anchor_left = 0.5
	dismiss_btn.anchor_top = 1.0
	dismiss_btn.offset_left = -dismiss_btn.texture_normal.get_width() / 2.0
	dismiss_btn.offset_top = -dismiss_btn.texture_normal.get_height() - 14
	dismiss_btn.pressed.connect(_dismiss)
	panel.add_child(dismiss_btn)
