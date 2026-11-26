extends CanvasLayer

class_name ShopDialog

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)
const CLOSE_BTN_SCALE = 2.0

const DIALOG_TEXTURE_MARGIN = 44
const DIALOG_CONTENT_MARGIN_LEFT = 36
const DIALOG_CONTENT_MARGIN_RIGHT = 36
const DIALOG_CONTENT_MARGIN_TOP = 30
const DIALOG_CONTENT_MARGIN_BOTTOM = 32

const PEDESTAL_WIDTH_RATIO = 0.48
const PEDESTAL_MIN_WIDTH = 460.0
const PEDESTAL_MAX_WIDTH = 620.0
const PEDESTAL_CONTENT_SEPARATION = 12
const PEDESTAL_TITLE_FONT_SIZE = 26
const PEDESTAL_ICON_SIZE = Vector2(56, 56)
const PEDESTAL_DESC_FONT_SIZE = 18
const PEDESTAL_PRICE_FONT_SIZE = 19
const PEDESTAL_STATUS_FONT_SIZE = 17
const PEDESTAL_BTN_SEPARATION = 12

const BRAX_WIDTH_RATIO = 0.58
const BRAX_MIN_WIDTH = 560.0
const BRAX_MAX_WIDTH = 780.0
const BRAX_HEIGHT_RATIO = 0.72
const BRAX_MIN_HEIGHT = 420.0
const BRAX_MAX_HEIGHT = 660.0
const BRAX_CONTENT_SEPARATION = 10
const BRAX_TITLE_FONT_SIZE = 28
const BRAX_STATUS_FONT_SIZE = 18
const BRAX_WALLET_FONT_SIZE = 20
const BRAX_TAB_BAR_SEPARATION = 10
const BRAX_SUMMARY_SEPARATION = 16
const BRAX_SUMMARY_DESC_FONT_SIZE = 18
const BRAX_SUMMARY_ACTIONS_SEPARATION = 18
const BRAX_LIST_MARGIN_RIGHT = 12
const BRAX_LIST_SEPARATION = 8
const BRAX_ROW_SEPARATION = 10
const BRAX_ROW_ICON_SIZE = Vector2(32, 32)
const BRAX_ROW_FONT_SIZE = 17
const BRAX_EMPTY_FONT_SIZE = 16

var _on_close_callback = null

func _add_to_bag(player_bag, item):
	var instance = OD.Database.create_item_instance(item.name) if OD.Database != null else null
	if instance == null:
		instance = {
			name = item.name,
			icon = item.icon,
			sell_price = item.sell_price,
			description = item.description
		}
	if typeof(player_bag) == TYPE_ARRAY:
		player_bag.append(instance)
		return true
	if player_bag != null and player_bag.has_method("add_item"):
		return player_bag.add_item(instance).added
	return false

func show_pedestal_dialog(pedestal, shop, zorkmids_ref, player_bag, on_close = Callable(), on_steal = Callable(), on_tab = Callable()):
	layer = 10
	_on_close_callback = on_close
	var dialog_assets = OD.Assets.dialog()
	var ink_color = Color(0.12, 0.08, 0.05)
	var viewport_size = _get_viewport_size()
	var target_width = clamp(viewport_size.x * PEDESTAL_WIDTH_RATIO, PEDESTAL_MIN_WIDTH, PEDESTAL_MAX_WIDTH)
	var panel = _create_nine_patch_dialog(dialog_assets.textures.alert_bigger, Vector2(target_width, 0))

	var content_vertical_box = VBoxContainer.new()
	content_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vertical_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vertical_box.add_theme_constant_override("separation", PEDESTAL_CONTENT_SEPARATION)
	panel.add_child(content_vertical_box)

	var header_horizontal_box = HBoxContainer.new()
	header_horizontal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vertical_box.add_child(header_horizontal_box)

	var close_button = _make_close_button(dialog_assets)
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size = close_button.custom_minimum_size
	header_horizontal_box.add_child(header_spacer)

	var item = pedestal.item_data
	var title_label = Label.new()
	title_label.text = item.name if item != null else "Empty Pedestal"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(title_label, dialog_assets.font, PEDESTAL_TITLE_FONT_SIZE, ink_color)
	header_horizontal_box.add_child(title_label)

	header_horizontal_box.add_child(close_button)

	if item != null and item.icon != "" and OD.Load.exists(item.icon):
		var icon_rect = TextureRect.new()
		icon_rect.texture = OD.Load.image(item.icon)
		icon_rect.custom_minimum_size = PEDESTAL_ICON_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content_vertical_box.add_child(icon_rect)

	var description_label = Label.new()
	description_label.text = item.description if item != null and item.description != "" else "A fine piece of dungeon merchandise."
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(description_label, dialog_assets.font, PEDESTAL_DESC_FONT_SIZE, ink_color)
	content_vertical_box.add_child(description_label)

	var price_label = Label.new()
	price_label.text = "Price: " + str(item.price) + " zm   |   Your Zorkmids: " + str(zorkmids_ref.value)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(price_label, dialog_assets.font, PEDESTAL_PRICE_FONT_SIZE, ink_color)
	content_vertical_box.add_child(price_label)

	var status_label = Label.new()
	status_label.text = ""
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(status_label, dialog_assets.font, PEDESTAL_STATUS_FONT_SIZE, Color(0.55, 0.1, 0.1))
	content_vertical_box.add_child(status_label)

	var button_horizontal_box = HBoxContainer.new()
	button_horizontal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_horizontal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_horizontal_box.add_theme_constant_override("separation", PEDESTAL_BTN_SEPARATION)
	content_vertical_box.add_child(button_horizontal_box)

	var buy_button = OD.Chrome.button(dialog_assets.textures.buy)
	buy_button.offset_left = 0
	buy_button.offset_top = 0
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.pressed.connect(func():
		if zorkmids_ref.value >= item.price:
			if not _add_to_bag(player_bag, item):
				status_label.text = "Inventory is full!"
				status_label.visible = true
				return
			zorkmids_ref.value -= item.price
			OD.Audio.play_sfx("item_purchase")
			pedestal.clear_item(true)
			status_label.visible = false
			_dismiss()
		else:
			OD.Audio.play_sfx("zorkmidslow1")
			status_label.text = "Not enough Zorkmids!"
			status_label.visible = true
	)
	button_horizontal_box.add_child(buy_button)

	var tab_button = _make_styled_button("Take (Tab)", dialog_assets.font, ink_color, dialog_assets)
	tab_button.pressed.connect(func():
		if not _add_to_bag(player_bag, item):
			status_label.text = "Inventory is full!"
			status_label.visible = true
			return
		if shop != null:
			shop.unpaid_total += item.price
		pedestal.clear_item(false)
		OD.Audio.play_sfx("metal_get")
		if shop != null and not shop.is_hostile and on_tab.is_valid():
			on_tab.call()
		if shop != null and shop.is_hostile and on_steal.is_valid():
			on_steal.call()
		_dismiss()
	)
	button_horizontal_box.add_child(tab_button)

	var cancel_button = OD.Chrome.button(dialog_assets.textures.dont_buy)
	cancel_button.offset_left = 0
	cancel_button.offset_top = 0
	cancel_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cancel_button.pressed.connect(_dismiss)
	button_horizontal_box.add_child(cancel_button)
	UiHelpers.enable_gamepad_focus_in_tree(panel, buy_button)

func show_brax_dialog(shop, zorkmids_ref, player_bag, on_close = Callable(), on_steal = Callable(), on_pay_tab = Callable()):
	layer = 10
	_on_close_callback = on_close
	var dialog_assets = OD.Assets.dialog()
	var ink_color = Color(0.12, 0.08, 0.05)
	var viewport_size = _get_viewport_size()
	var target_width = clamp(viewport_size.x * BRAX_WIDTH_RATIO, BRAX_MIN_WIDTH, BRAX_MAX_WIDTH)
	var target_height = clamp(viewport_size.y * BRAX_HEIGHT_RATIO, BRAX_MIN_HEIGHT, BRAX_MAX_HEIGHT)
	var panel = _create_nine_patch_dialog(dialog_assets.textures.alert_bigger, Vector2(target_width, target_height))

	var content_vertical_box = VBoxContainer.new()
	content_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vertical_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vertical_box.add_theme_constant_override("separation", BRAX_CONTENT_SEPARATION)
	panel.add_child(content_vertical_box)

	var header_horizontal_box = HBoxContainer.new()
	header_horizontal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vertical_box.add_child(header_horizontal_box)

	var close_button = _make_close_button(dialog_assets)
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size = close_button.custom_minimum_size
	header_horizontal_box.add_child(header_spacer)

	var title_label = Label.new()
	title_label.text = "Brax's Emporium"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(title_label, dialog_assets.font, BRAX_TITLE_FONT_SIZE, ink_color)
	header_horizontal_box.add_child(title_label)

	header_horizontal_box.add_child(close_button)

	var status_label = Label.new()
	status_label.text = "Welcome! Browse my wares or sell your loot."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(status_label, dialog_assets.font, BRAX_STATUS_FONT_SIZE, ink_color)
	content_vertical_box.add_child(status_label)

	var wallet_label = Label.new()
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(wallet_label, dialog_assets.font, BRAX_WALLET_FONT_SIZE, ink_color)
	content_vertical_box.add_child(wallet_label)

	var pay_tab_button = _make_styled_button("Pay Tab", dialog_assets.font, ink_color, dialog_assets)
	pay_tab_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var refresh_wallet = func():
		wallet_label.text = "Zorkmids: " + str(zorkmids_ref.value) + "   |   Unpaid Tab: " + str(shop.unpaid_total) + " zm"
		pay_tab_button.visible = shop.unpaid_total > 0
		pay_tab_button.text = "Pay Tab (" + str(shop.unpaid_total) + " zm)"

	pay_tab_button.pressed.connect(func():
		if zorkmids_ref.value >= shop.unpaid_total:
			zorkmids_ref.value -= shop.unpaid_total
			shop.unpaid_total = 0
			OD.Audio.play_sfx("item_purchase")
			status_label.text = "Tab paid in full! Brax nods approvingly."
			refresh_wallet.call()
			if on_pay_tab.is_valid():
				on_pay_tab.call()
		else:
			OD.Audio.play_sfx("zorkmidslow1")
			status_label.text = "Not enough Zorkmids to pay your tab!"
	)
	refresh_wallet.call()

	var tab_bar = HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.add_theme_constant_override("separation", BRAX_TAB_BAR_SEPARATION)
	content_vertical_box.add_child(tab_bar)

	var summary_tab_button = _make_styled_button("Summary", dialog_assets.font, ink_color, dialog_assets)
	var buy_tab_button = _make_styled_button("Buy", dialog_assets.font, ink_color, dialog_assets)
	var sell_tab_button = _make_styled_button("Sell", dialog_assets.font, ink_color, dialog_assets)
	tab_bar.add_child(summary_tab_button)
	tab_bar.add_child(buy_tab_button)
	tab_bar.add_child(sell_tab_button)

	var tab_pages = Control.new()
	tab_pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vertical_box.add_child(tab_pages)

	var summary_page = VBoxContainer.new()
	summary_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	summary_page.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_page.add_theme_constant_override("separation", BRAX_SUMMARY_SEPARATION)
	tab_pages.add_child(summary_page)

	var summary_description = Label.new()
	summary_description.text = "Settle your unpaid tab, browse pedestal wares in Buy, or offload loot in Sell."
	summary_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(summary_description, dialog_assets.font, BRAX_SUMMARY_DESC_FONT_SIZE, ink_color)
	summary_page.add_child(summary_description)

	summary_page.add_child(pay_tab_button)

	var summary_actions = HBoxContainer.new()
	summary_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_actions.add_theme_constant_override("separation", BRAX_SUMMARY_ACTIONS_SEPARATION)
	summary_page.add_child(summary_actions)

	var steal_button = _make_styled_button("Attempt Theft", dialog_assets.font, Color(0.55, 0.08, 0.08), dialog_assets)
	steal_button.pressed.connect(func():
		if on_steal.is_valid():
			on_steal.call()
		_dismiss()
	)
	summary_actions.add_child(steal_button)

	var done_button = OD.Chrome.button(dialog_assets.textures.ok)
	done_button.offset_left = 0
	done_button.offset_top = 0
	done_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	done_button.pressed.connect(_dismiss)
	summary_actions.add_child(done_button)

	var buy_scroll = ScrollContainer.new()
	buy_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	buy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_pages.add_child(buy_scroll)

	var buy_margin = MarginContainer.new()
	buy_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_margin.add_theme_constant_override("margin_right", BRAX_LIST_MARGIN_RIGHT)
	buy_scroll.add_child(buy_margin)

	var buy_vertical_box = VBoxContainer.new()
	buy_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_vertical_box.add_theme_constant_override("separation", BRAX_LIST_SEPARATION)
	buy_margin.add_child(buy_vertical_box)

	var sell_scroll = ScrollContainer.new()
	sell_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	sell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_pages.add_child(sell_scroll)

	var sell_margin = MarginContainer.new()
	sell_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_margin.add_theme_constant_override("margin_right", BRAX_LIST_MARGIN_RIGHT)
	sell_scroll.add_child(sell_margin)

	var sell_vertical_box = VBoxContainer.new()
	sell_vertical_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_vertical_box.add_theme_constant_override("separation", BRAX_LIST_SEPARATION)
	sell_margin.add_child(sell_vertical_box)

	_populate_buy_list(buy_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet, sell_vertical_box)
	_populate_sell_list(sell_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet)

	var select_tab = func(tab_idx):
		summary_page.visible = (tab_idx == 0)
		buy_scroll.visible = (tab_idx == 1)
		sell_scroll.visible = (tab_idx == 2)
		summary_tab_button.modulate = Color.WHITE if tab_idx == 0 else Color(0.82, 0.78, 0.72)
		buy_tab_button.modulate = Color.WHITE if tab_idx == 1 else Color(0.82, 0.78, 0.72)
		sell_tab_button.modulate = Color.WHITE if tab_idx == 2 else Color(0.82, 0.78, 0.72)

	summary_tab_button.pressed.connect(func(): select_tab.call(0))
	buy_tab_button.pressed.connect(func(): select_tab.call(1))
	sell_tab_button.pressed.connect(func(): select_tab.call(2))
	select_tab.call(0)

func _populate_buy_list(buy_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet, sell_vertical_box):
	for child in buy_vertical_box.get_children():
		child.queue_free()
	var any_stock = false
	for pedestal in shop.pedestals:
		if not is_instance_valid(pedestal) or not pedestal.has_item():
			continue
		any_stock = true
		var item = pedestal.item_data
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", BRAX_ROW_SEPARATION)
		buy_vertical_box.add_child(row)
		if item.icon != "" and OD.Load.exists(item.icon):
			var icon_rect = TextureRect.new()
			icon_rect.texture = OD.Load.image(item.icon)
			icon_rect.custom_minimum_size = BRAX_ROW_ICON_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon_rect)
		var item_label = Label.new()
		item_label.text = item.name + " (" + str(item.price) + " zm)"
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(item_label, dialog_assets.font, BRAX_ROW_FONT_SIZE, ink_color)
		row.add_child(item_label)
		var buy_button = OD.Chrome.button(dialog_assets.textures.buy)
		buy_button.offset_left = 0
		buy_button.offset_top = 0
		buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy_button.pressed.connect(func():
			if zorkmids_ref.value >= item.price:
				if not _add_to_bag(player_bag, item):
					status_label.text = "Inventory is full!"
					return
				zorkmids_ref.value -= item.price
				OD.Audio.play_sfx("item_purchase")
				pedestal.clear_item(true)
				status_label.text = "Purchased " + item.name + "!"
				refresh_wallet.call()
				_populate_buy_list(buy_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet, sell_vertical_box)
				_populate_sell_list(sell_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet)
			else:
				OD.Audio.play_sfx("zorkmidslow1")
				status_label.text = "Not enough Zorkmids!"
		)
		row.add_child(buy_button)
	if not any_stock:
		var empty_buy = Label.new()
		empty_buy.text = "No items remaining on pedestals."
		empty_buy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(empty_buy, dialog_assets.font, BRAX_EMPTY_FONT_SIZE, ink_color)
		buy_vertical_box.add_child(empty_buy)

func _populate_sell_list(sell_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet):
	for child in sell_vertical_box.get_children():
		child.queue_free()
	var entries = []
	if typeof(player_bag) == TYPE_ARRAY:
		for index in range(player_bag.size()):
			entries.append({ slot_index = index, item = player_bag[index] })
	elif player_bag != null and player_bag.has_method("get_inventory_items"):
		entries = player_bag.get_inventory_items()
	if entries.is_empty():
		var empty_sell = Label.new()
		empty_sell.text = "Your bag is empty."
		empty_sell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(empty_sell, dialog_assets.font, BRAX_EMPTY_FONT_SIZE, ink_color)
		sell_vertical_box.add_child(empty_sell)
		return
	for entry in entries:
		var slot_idx = entry.slot_index
		var bag_item = entry.item
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", BRAX_ROW_SEPARATION)
		sell_vertical_box.add_child(row)
		if bag_item.get("icon", "") != "" and OD.Load.exists(bag_item.icon):
			var icon_rect = TextureRect.new()
			icon_rect.texture = OD.Load.image(bag_item.icon)
			icon_rect.custom_minimum_size = BRAX_ROW_ICON_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon_rect)
		var sell_value = max(1, int(bag_item.get("sell_price", 5)))
		var item_count = int(bag_item.get("count", 1))
		var count_suffix = " x" + str(item_count) if item_count > 1 else ""
		var item_label = Label.new()
		item_label.text = bag_item.name + count_suffix + " (+" + str(sell_value) + " zm)"
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(item_label, dialog_assets.font, BRAX_ROW_FONT_SIZE, ink_color)
		row.add_child(item_label)
		var sell_button = OD.Chrome.button(dialog_assets.textures.sell)
		sell_button.offset_left = 0
		sell_button.offset_top = 0
		sell_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sell_button.pressed.connect(func():
			zorkmids_ref.value += sell_value
			OD.Audio.play_sfx("item_purchase")
			if typeof(player_bag) == TYPE_ARRAY:
				player_bag.remove_at(slot_idx)
			elif player_bag != null and player_bag.has_method("remove_item_at"):
				player_bag.remove_item_at(slot_idx, 1)
			status_label.text = "Sold " + bag_item.name + " for " + str(sell_value) + " zm!"
			refresh_wallet.call()
			_populate_sell_list(sell_vertical_box, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet)
		)
		row.add_child(sell_button)

func _dismiss():
	if _on_close_callback.is_valid():
		_on_close_callback.call()
	queue_free()

func _unhandled_input(event):
	if (event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_ESCAPE) or UiHelpers.is_gamepad_cancel(event):
		get_viewport().set_input_as_handled()
		_dismiss()

func _get_viewport_size():
	return UiHelpers.viewport_size(self, DEFAULT_VIEWPORT_SIZE)

func _style_label(label, font, font_size, color):
	UiHelpers.style_label(label, font_size, color, font)

func _make_close_button(dialog_assets):
	return UiHelpers.make_close_button(dialog_assets, _dismiss, CLOSE_BTN_SCALE)

func _make_styled_button(text_value, font, text_color, dialog_assets = null):
	var blank_textures = dialog_assets.textures.get("blank", null) if dialog_assets != null else null
	return OD.Chrome.parchment_button(text_value, font, text_color, blank_textures)

func _create_nine_patch_dialog(background_texture, minimum_size):
	var overlay = UiHelpers.create_modal_overlay(self, 0.45)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.root.add_child(center)

	var style_box = UiHelpers.create_panel_style(
		background_texture,
		DIALOG_TEXTURE_MARGIN,
		{
			left = DIALOG_CONTENT_MARGIN_LEFT,
			right = DIALOG_CONTENT_MARGIN_RIGHT,
			top = DIALOG_CONTENT_MARGIN_TOP,
			bottom = DIALOG_CONTENT_MARGIN_BOTTOM
		}
	)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", style_box)
	center.add_child(panel)
	UiHelpers.enable_gamepad_focus_in_tree(panel)
	return panel
