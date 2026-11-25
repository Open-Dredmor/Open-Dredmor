extends CanvasLayer

const NINE_PATCH_MARGIN = 24
const CLOSE_BTN_SCALE = 2.0
const CLOSE_BTN_MARGIN = Vector2(8, 8)
const OK_BTN_BOTTOM_MARGIN = 14
const LUTEFISK_OK_BTN_BOTTOM_MARGIN = 18

const CONTENT_MARGINS = { left = 28, top = 24, right = -28, bottom = -68 }

const KRONG_SELECT_SIZE = Vector2(460, 380)
const KRONG_SELECT_SEPARATION = 10
const KRONG_SELECT_TITLE_FONT_SIZE = 26
const KRONG_SELECT_MSG_FONT_SIZE = 18
const KRONG_SELECT_LIST_SEPARATION = 8
const KRONG_SELECT_ROW_SEPARATION = 10
const KRONG_SELECT_ICON_SIZE = Vector2(32, 32)
const KRONG_SELECT_ITEM_FONT_SIZE = 18

const KRONG_FRAME_SIZE = Vector2(560, 440)
const KRONG_PANEL_POS = Vector2(20, 20)
const KRONG_ITEM_ICON_RECT = Rect2(154, 174, 56, 56)
const KRONG_STATS_BOX_RECT = Rect2(298, 200, 184, 164)
const KRONG_MSG_FONT_SIZE = 18
const KRONG_DISMISS_BTN_CENTER_X = 182
const KRONG_DISMISS_BTN_Y = 356

const LUTEFISK_REWARD_ICON_RECT = Rect2(228, 106, 64, 64)
const LUTEFISK_MSG_RECT = Rect2(110, 174, 300, 78)
const LUTEFISK_MSG_FONT_SIZE = 20
const LUTEFISK_OFFER_BTN_RECT = Rect2(160, 260, 200, 32)

const VENDING_WINDOW_SIZE = Vector2(580, 520)
const STANDARD_CONTENT_SEPARATION = 8
const STANDARD_TITLE_FONT_SIZE = 26
const STANDARD_ICON_SIZE = Vector2(64, 64)
const STANDARD_MSG_FONT_SIZE = 20
const VENDING_ZORKMID_FONT_SIZE = 20
const VENDING_STOCK_SEPARATION = 6
const VENDING_ROW_SEPARATION = 10
const VENDING_ITEM_ICON_SIZE = Vector2(32, 32)
const VENDING_ITEM_FONT_SIZE = 18

var _on_close_callback = null
var _on_broken_callback = null
var _on_item_granted_callback = null
var _on_recipe_learned_callback = null

func show_element_dialog(element, zorkmids_ref, lutefisk_ref, on_close = Callable(), on_broken = Callable(), on_item_granted = Callable(), on_recipe_learned = Callable()):
	layer = 10
	_on_close_callback = on_close
	_on_broken_callback = on_broken
	_on_item_granted_callback = on_item_granted
	_on_recipe_learned_callback = on_recipe_learned
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
	if result.has("granted_item") and result.granted_item != null and _on_item_granted_callback != null and _on_item_granted_callback.is_valid():
		_on_item_granted_callback.call(result.granted_item)
	if result.has("discovered_recipe") and result.discovered_recipe != null and _on_recipe_learned_callback != null and _on_recipe_learned_callback.is_valid():
		_on_recipe_learned_callback.call(result.discovered_recipe)
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
		nine_patch.patch_margin_left = NINE_PATCH_MARGIN
		nine_patch.patch_margin_right = NINE_PATCH_MARGIN
		nine_patch.patch_margin_top = NINE_PATCH_MARGIN
		nine_patch.patch_margin_bottom = NINE_PATCH_MARGIN
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
	var scaled_size = close_btn.texture_normal.get_size() * CLOSE_BTN_SCALE
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.custom_minimum_size = scaled_size
	close_btn.size = scaled_size
	close_btn.anchor_left = 1.0
	close_btn.anchor_top = 0.0
	close_btn.offset_left = -scaled_size.x - CLOSE_BTN_MARGIN.x
	close_btn.offset_top = CLOSE_BTN_MARGIN.y
	close_btn.pressed.connect(_dismiss)
	panel.add_child(close_btn)

func _build_krong_select_window(element, result, zorkmids_ref, lutefisk_ref, dialog_assets):
	var ink_color = Color(0.12, 0.08, 0.05)
	var panel = _create_base_overlay(dialog_assets.textures.alert_bigger, KRONG_SELECT_SIZE)
	_add_close_button(panel, dialog_assets)

	var content_vbox = VBoxContainer.new()
	content_vbox.anchor_right = 1.0
	content_vbox.anchor_bottom = 1.0
	content_vbox.offset_left = CONTENT_MARGINS.left
	content_vbox.offset_top = CONTENT_MARGINS.top
	content_vbox.offset_right = CONTENT_MARGINS.right
	content_vbox.offset_bottom = CONTENT_MARGINS.bottom
	content_vbox.add_theme_constant_override("separation", KRONG_SELECT_SEPARATION)
	panel.add_child(content_vbox)

	var title_label = Label.new()
	title_label.text = result.get("title", "Anvil of Krong")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, dialog_assets.font, KRONG_SELECT_TITLE_FONT_SIZE, ink_color)
	content_vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, KRONG_SELECT_MSG_FONT_SIZE, ink_color)
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
	items_vbox.add_theme_constant_override("separation", KRONG_SELECT_LIST_SEPARATION)
	items_scroll.add_child(items_vbox)

	for gear in candidate_items:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", KRONG_SELECT_ROW_SEPARATION)
		items_vbox.add_child(row)

		if gear.icon != "" and OD.Load.exists(gear.icon):
			var icon_rect = TextureRect.new()
			icon_rect.texture = OD.Load.image(gear.icon)
			icon_rect.custom_minimum_size = KRONG_SELECT_ICON_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(icon_rect)

		var name_label = Label.new()
		name_label.text = gear.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(name_label, dialog_assets.font, KRONG_SELECT_ITEM_FONT_SIZE, ink_color)
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
	cancel_btn.offset_top = -cancel_btn.texture_normal.get_height() - OK_BTN_BOTTOM_MARGIN
	cancel_btn.pressed.connect(_dismiss)
	panel.add_child(cancel_btn)

func _build_krong_window(result, dialog_assets):
	var is_cursed = result.get("cursed", false)
	var krong_texture = dialog_assets.textures.krong_displeased if is_cursed else dialog_assets.textures.krong_pleased
	var dismiss_textures = dialog_assets.textures.shucks if is_cursed else dialog_assets.textures.awesome
	var frame_panel = _create_base_overlay(dialog_assets.textures.alert_bigger, KRONG_FRAME_SIZE)
	_add_close_button(frame_panel, dialog_assets)

	var panel = TextureRect.new()
	panel.texture = krong_texture
	panel.position = KRONG_PANEL_POS
	panel.size = Vector2(krong_texture.get_width(), krong_texture.get_height())
	frame_panel.add_child(panel)

	var icon_path = result.get("icon", "")
	if icon_path != "" and OD.Load.exists(icon_path):
		var slot_icon = TextureRect.new()
		slot_icon.texture = OD.Load.image(icon_path)
		slot_icon.position = KRONG_ITEM_ICON_RECT.position
		slot_icon.size = KRONG_ITEM_ICON_RECT.size
		slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(slot_icon)

	var stats_box = VBoxContainer.new()
	stats_box.position = KRONG_STATS_BOX_RECT.position
	stats_box.size = KRONG_STATS_BOX_RECT.size
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(stats_box)

	var msg_label = Label.new()
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, KRONG_MSG_FONT_SIZE, Color(0.95, 0.9, 0.8), 2)
	stats_box.add_child(msg_label)

	var dismiss_btn = OD.Chrome.button(dismiss_textures)
	dismiss_btn.position = Vector2(KRONG_DISMISS_BTN_CENTER_X - dismiss_btn.texture_normal.get_width() / 2.0, KRONG_DISMISS_BTN_Y)
	dismiss_btn.pressed.connect(_dismiss)
	panel.add_child(dismiss_btn)

func _build_lutefisk_window(element, result, lutefisk_ref, dialog_assets):
	var panel = _create_base_overlay(dialog_assets.textures.lutefisk_bg)
	_add_close_button(panel, dialog_assets)

	var reward_icon = TextureRect.new()
	reward_icon.position = LUTEFISK_REWARD_ICON_RECT.position
	reward_icon.size = LUTEFISK_REWARD_ICON_RECT.size
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_icon.modulate.a = 0.0
	panel.add_child(reward_icon)

	var msg_label = Label.new()
	msg_label.position = LUTEFISK_MSG_RECT.position
	msg_label.size = LUTEFISK_MSG_RECT.size
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, LUTEFISK_MSG_FONT_SIZE, Color(0.96, 0.94, 0.86), 3)
	panel.add_child(msg_label)

	var offer_btn = Button.new()
	offer_btn.position = LUTEFISK_OFFER_BTN_RECT.position
	offer_btn.size = LUTEFISK_OFFER_BTN_RECT.size
	offer_btn.text = "Offer 5 Lutefisk (Have: " + str(lutefisk_ref.value) + ")"
	offer_btn.pressed.connect(func():
		if element == null:
			return
		var offer_amount = min(5, lutefisk_ref.value)
		lutefisk_ref.value -= offer_amount
		var offer_res = element.offer_lutefisk(offer_amount)
		if offer_res.has("granted_item") and offer_res.granted_item != null and _on_item_granted_callback != null and _on_item_granted_callback.is_valid():
			_on_item_granted_callback.call(offer_res.granted_item)
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
	ok_btn.offset_top = -ok_btn.texture_normal.get_height() - LUTEFISK_OK_BTN_BOTTOM_MARGIN
	ok_btn.pressed.connect(_dismiss)
	panel.add_child(ok_btn)

func _build_standard_window(element, result, zorkmids_ref, dialog_assets):
	var kind = result.get("kind", "info")
	var ink_color = Color(0.12, 0.08, 0.05)
	var bg_texture = dialog_assets.textures.alert_bigger if kind == "vending" else dialog_assets.textures.alert
	var custom_size = VENDING_WINDOW_SIZE if kind == "vending" else null

	var panel = _create_base_overlay(bg_texture, custom_size)
	_add_close_button(panel, dialog_assets)

	var content_vbox = VBoxContainer.new()
	content_vbox.anchor_right = 1.0
	content_vbox.anchor_bottom = 1.0
	content_vbox.offset_left = CONTENT_MARGINS.left
	content_vbox.offset_top = CONTENT_MARGINS.top
	content_vbox.offset_right = CONTENT_MARGINS.right
	content_vbox.offset_bottom = CONTENT_MARGINS.bottom
	content_vbox.add_theme_constant_override("separation", STANDARD_CONTENT_SEPARATION)
	panel.add_child(content_vbox)

	var title_label = Label.new()
	title_label.text = result.get("title", "Element")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, dialog_assets.font, STANDARD_TITLE_FONT_SIZE, ink_color)
	content_vbox.add_child(title_label)

	var icon_path = result.get("icon", "")
	if icon_path != "" and OD.Load.exists(icon_path):
		var item_icon = TextureRect.new()
		item_icon.texture = OD.Load.image(icon_path)
		item_icon.custom_minimum_size = STANDARD_ICON_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_icon.tooltip_text = result.get("tooltip", "")
		content_vbox.add_child(item_icon)

	var msg_label = Label.new()
	msg_label.text = result.get("message", "")
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, dialog_assets.font, STANDARD_MSG_FONT_SIZE, ink_color)
	content_vbox.add_child(msg_label)

	if kind == "broken":
		if _on_broken_callback.is_valid():
			_on_broken_callback.call()
	elif kind == "vending":
		var zorkmid_label = Label.new()
		zorkmid_label.text = "Zorkmids: " + str(zorkmids_ref.value)
		zorkmid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(zorkmid_label, dialog_assets.font, VENDING_ZORKMID_FONT_SIZE, ink_color)
		content_vbox.add_child(zorkmid_label)

		var stock_scroll = ScrollContainer.new()
		stock_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stock_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stock_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_vbox.add_child(stock_scroll)

		var stock_vbox = VBoxContainer.new()
		stock_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stock_vbox.add_theme_constant_override("separation", VENDING_STOCK_SEPARATION)
		stock_scroll.add_child(stock_vbox)

		for item in result.get("stock", []):
			var item_row = HBoxContainer.new()
			item_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_row.add_theme_constant_override("separation", VENDING_ROW_SEPARATION)
			stock_vbox.add_child(item_row)
			if item.has("icon") and item.icon != "" and OD.Load.exists(item.icon):
				var icon_rect = TextureRect.new()
				icon_rect.texture = OD.Load.image(item.icon)
				icon_rect.custom_minimum_size = VENDING_ITEM_ICON_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				item_row.add_child(icon_rect)
			var item_label = Label.new()
			item_label.text = item.name + " (" + str(item.price) + " zm)"
			item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_style_label(item_label, dialog_assets.font, VENDING_ITEM_FONT_SIZE, ink_color)
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
	dismiss_btn.offset_top = -dismiss_btn.texture_normal.get_height() - OK_BTN_BOTTOM_MARGIN
	dismiss_btn.pressed.connect(_dismiss)
	panel.add_child(dismiss_btn)
