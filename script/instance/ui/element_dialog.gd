extends CanvasLayer

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

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
	UiHelpers.style_label(label, font_size, color, font, outline_size)

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

func _create_base_overlay(background_texture, custom_size = null):
	var overlay = UiHelpers.create_modal_overlay(self, 0.45)

	var window_size = custom_size if custom_size != null else Vector2(background_texture.get_width(), background_texture.get_height())
	var panel = null
	if custom_size != null:
		var nine_patch = NinePatchRect.new()
		nine_patch.texture = background_texture
		nine_patch.patch_margin_left = NINE_PATCH_MARGIN
		nine_patch.patch_margin_right = NINE_PATCH_MARGIN
		nine_patch.patch_margin_top = NINE_PATCH_MARGIN
		nine_patch.patch_margin_bottom = NINE_PATCH_MARGIN
		panel = nine_patch
	else:
		var texture_rect = TextureRect.new()
		texture_rect.texture = background_texture
		panel = texture_rect
	panel.custom_minimum_size = window_size
	panel.size = window_size
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.offset_left = -window_size.x / 2.0
	panel.offset_top = -window_size.y / 2.0
	panel.offset_right = window_size.x / 2.0
	panel.offset_bottom = window_size.y / 2.0
	overlay.root.add_child(panel)
	return panel

func _add_close_button(panel, dialog_assets):
	var close_button = UiHelpers.make_close_button(dialog_assets, _dismiss, CLOSE_BTN_SCALE)
	close_button.anchor_left = 1.0
	close_button.anchor_top = 0.0
	close_button.offset_left = -close_button.size.x - CLOSE_BTN_MARGIN.x
	close_button.offset_top = CLOSE_BTN_MARGIN.y
	panel.add_child(close_button)

func _build_krong_select_window(element, result, zorkmids_ref, lutefisk_ref, dialog_assets):
	var ink_color = Color(0.12, 0.08, 0.05)
	var panel = _create_base_overlay(dialog_assets.textures.alert_bigger, KRONG_SELECT_SIZE)
	_add_close_button(panel, dialog_assets)

	var content_vertical_box = VBoxContainer.new()
	content_vertical_box.anchor_right = 1.0
	content_vertical_box.anchor_bottom = 1.0
	content_vertical_box.offset_left = CONTENT_MARGINS.left
	content_vertical_box.offset_top = CONTENT_MARGINS.top
	content_vertical_box.offset_right = CONTENT_MARGINS.right
	content_vertical_box.offset_bottom = CONTENT_MARGINS.bottom
	content_vertical_box.add_theme_constant_override("separation", KRONG_SELECT_SEPARATION)
	panel.add_child(content_vertical_box)

	var title_label = Label.new()
	title_label.text = result.get("title", "Anvil of Krong")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, dialog_assets.font, KRONG_SELECT_TITLE_FONT_SIZE, ink_color)
	content_vertical_box.add_child(title_label)

	var message_label = Label.new()
	message_label.text = result.get("message", "")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(message_label, dialog_assets.font, KRONG_SELECT_MSG_FONT_SIZE, ink_color)
	content_vertical_box.add_child(message_label)

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
	content_vertical_box.add_child(items_scroll)

	var items_vertical_box = VBoxContainer.new()
	items_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vertical_box.add_theme_constant_override("separation", KRONG_SELECT_LIST_SEPARATION)
	items_scroll.add_child(items_vertical_box)

	for gear in candidate_items:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", KRONG_SELECT_ROW_SEPARATION)
		items_vertical_box.add_child(row)

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

		var select_button = Button.new()
		select_button.text = "Enchant"
		select_button.pressed.connect(func():
			var next_result = element.enchant_item_on_anvil(gear) if element != null else { kind = "krong", cursed = false, icon = gear.icon, message = gear.name + "\n\n+1 Burliness" }
			for child in get_children():
				child.queue_free()
			_build_from_result(element, next_result, zorkmids_ref, lutefisk_ref)
		)
		row.add_child(select_button)

	var cancel_button = OD.Chrome.button(dialog_assets.textures.ok)
	cancel_button.anchor_left = 0.5
	cancel_button.anchor_top = 1.0
	cancel_button.offset_left = -cancel_button.texture_normal.get_width() / 2.0
	cancel_button.offset_top = -cancel_button.texture_normal.get_height() - OK_BTN_BOTTOM_MARGIN
	cancel_button.pressed.connect(_dismiss)
	panel.add_child(cancel_button)

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

	var message_label = Label.new()
	message_label.text = result.get("message", "")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(message_label, dialog_assets.font, KRONG_MSG_FONT_SIZE, Color(0.95, 0.9, 0.8), 2)
	stats_box.add_child(message_label)

	var dismiss_button = OD.Chrome.button(dismiss_textures)
	dismiss_button.position = Vector2(KRONG_DISMISS_BTN_CENTER_X - dismiss_button.texture_normal.get_width() / 2.0, KRONG_DISMISS_BTN_Y)
	dismiss_button.pressed.connect(_dismiss)
	panel.add_child(dismiss_button)

func _build_lutefisk_window(element, result, lutefisk_ref, dialog_assets):
	var panel = _create_base_overlay(dialog_assets.textures.lutefisk_bg)
	_add_close_button(panel, dialog_assets)

	var reward_icon = TextureRect.new()
	reward_icon.position = LUTEFISK_REWARD_ICON_RECT.position
	reward_icon.size = LUTEFISK_REWARD_ICON_RECT.size
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_icon.modulate.a = 0.0
	panel.add_child(reward_icon)

	var message_label = Label.new()
	message_label.position = LUTEFISK_MSG_RECT.position
	message_label.size = LUTEFISK_MSG_RECT.size
	message_label.text = result.get("message", "")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(message_label, dialog_assets.font, LUTEFISK_MSG_FONT_SIZE, Color(0.96, 0.94, 0.86), 3)
	panel.add_child(message_label)

	var offer_button = Button.new()
	offer_button.position = LUTEFISK_OFFER_BTN_RECT.position
	offer_button.size = LUTEFISK_OFFER_BTN_RECT.size
	offer_button.text = "Offer 5 Lutefisk (Have: " + str(lutefisk_ref.value) + ")"
	offer_button.pressed.connect(func():
		if element == null:
			return
		var offer_amount = min(5, lutefisk_ref.value)
		lutefisk_ref.value -= offer_amount
		var offer_result = element.offer_lutefisk(offer_amount)
		if offer_result.has("granted_item") and offer_result.granted_item != null and _on_item_granted_callback != null and _on_item_granted_callback.is_valid():
			_on_item_granted_callback.call(offer_result.granted_item)
		message_label.text = offer_result.message
		if offer_result.icon != "" and OD.Load.exists(offer_result.icon):
			reward_icon.texture = OD.Load.image(offer_result.icon)
			reward_icon.tooltip_text = offer_result.tooltip
			reward_icon.modulate.a = 1.0
		else:
			reward_icon.texture = null
			reward_icon.tooltip_text = ""
			reward_icon.modulate.a = 0.0
		offer_button.text = "Offer 5 Lutefisk (Have: " + str(lutefisk_ref.value) + ")"
	)
	panel.add_child(offer_button)

	var ok_button = OD.Chrome.button(dialog_assets.textures.ok)
	ok_button.anchor_left = 0.5
	ok_button.anchor_top = 1.0
	ok_button.offset_left = -ok_button.texture_normal.get_width() / 2.0
	ok_button.offset_top = -ok_button.texture_normal.get_height() - LUTEFISK_OK_BTN_BOTTOM_MARGIN
	ok_button.pressed.connect(_dismiss)
	panel.add_child(ok_button)

func _build_standard_window(element, result, zorkmids_ref, dialog_assets):
	var kind = result.get("kind", "info")
	var ink_color = Color(0.12, 0.08, 0.05)
	var background_texture = dialog_assets.textures.alert_bigger if kind == "vending" else dialog_assets.textures.alert
	var custom_size = VENDING_WINDOW_SIZE if kind == "vending" else null

	var panel = _create_base_overlay(background_texture, custom_size)
	_add_close_button(panel, dialog_assets)

	var content_vertical_box = VBoxContainer.new()
	content_vertical_box.anchor_right = 1.0
	content_vertical_box.anchor_bottom = 1.0
	content_vertical_box.offset_left = CONTENT_MARGINS.left
	content_vertical_box.offset_top = CONTENT_MARGINS.top
	content_vertical_box.offset_right = CONTENT_MARGINS.right
	content_vertical_box.offset_bottom = CONTENT_MARGINS.bottom
	content_vertical_box.add_theme_constant_override("separation", STANDARD_CONTENT_SEPARATION)
	panel.add_child(content_vertical_box)

	var title_label = Label.new()
	title_label.text = result.get("title", "Element")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, dialog_assets.font, STANDARD_TITLE_FONT_SIZE, ink_color)
	content_vertical_box.add_child(title_label)

	var icon_path = result.get("icon", "")
	if icon_path != "" and OD.Load.exists(icon_path):
		var item_icon = TextureRect.new()
		item_icon.texture = OD.Load.image(icon_path)
		item_icon.custom_minimum_size = STANDARD_ICON_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_icon.tooltip_text = result.get("tooltip", "")
		content_vertical_box.add_child(item_icon)

	var message_label = Label.new()
	message_label.text = result.get("message", "")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(message_label, dialog_assets.font, STANDARD_MSG_FONT_SIZE, ink_color)
	content_vertical_box.add_child(message_label)

	if kind == "broken":
		if _on_broken_callback.is_valid():
			_on_broken_callback.call()
	elif kind == "vending":
		var zorkmid_label = Label.new()
		zorkmid_label.text = "Zorkmids: " + str(zorkmids_ref.value)
		zorkmid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(zorkmid_label, dialog_assets.font, VENDING_ZORKMID_FONT_SIZE, ink_color)
		content_vertical_box.add_child(zorkmid_label)

		var stock_scroll = ScrollContainer.new()
		stock_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stock_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stock_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_vertical_box.add_child(stock_scroll)

		var stock_vertical_box = VBoxContainer.new()
		stock_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stock_vertical_box.add_theme_constant_override("separation", VENDING_STOCK_SEPARATION)
		stock_scroll.add_child(stock_vertical_box)

		for item in result.get("stock", []):
			var item_row = HBoxContainer.new()
			item_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_row.add_theme_constant_override("separation", VENDING_ROW_SEPARATION)
			stock_vertical_box.add_child(item_row)
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
			var buy_button = OD.Chrome.button(dialog_assets.textures.buy)
			buy_button.offset_left = 0
			buy_button.offset_top = 0
			buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			buy_button.pressed.connect(func():
				if zorkmids_ref.value >= item.price:
					zorkmids_ref.value -= item.price
					OD.Audio.play_sfx("item_purchase")
					zorkmid_label.text = "Zorkmids: " + str(zorkmids_ref.value)
					message_label.text = "Purchased " + item.name + "!"
				else:
					OD.Audio.play_sfx("zorkmidslow1")
					message_label.text = "Not enough Zorkmids!"
			)
			item_row.add_child(buy_button)
	elif kind == "dredmorstatue":
		var smash_button = Button.new()
		smash_button.text = "Smash Statue"
		smash_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		smash_button.pressed.connect(func():
			if element == null:
				return
			var broken_result = element.break_element()
			if _on_broken_callback.is_valid():
				_on_broken_callback.call()
			message_label.text = broken_result.message
			smash_button.disabled = true
		)
		content_vertical_box.add_child(smash_button)

	var dismiss_button = OD.Chrome.button(dialog_assets.textures.ok)
	dismiss_button.anchor_left = 0.5
	dismiss_button.anchor_top = 1.0
	dismiss_button.offset_left = -dismiss_button.texture_normal.get_width() / 2.0
	dismiss_button.offset_top = -dismiss_button.texture_normal.get_height() - OK_BTN_BOTTOM_MARGIN
	dismiss_button.pressed.connect(_dismiss)
	panel.add_child(dismiss_button)
