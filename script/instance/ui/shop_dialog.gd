extends CanvasLayer

class_name ShopDialog

var _on_close_callback = null

func show_pedestal_dialog(pedestal, shop, zorkmids_ref, player_bag, on_close = Callable(), on_steal = Callable(), on_tab = Callable()):
	layer = 10
	_on_close_callback = on_close
	var dialog_assets = OD.Assets.dialog()
	var ink_color = Color(0.12, 0.08, 0.05)
	var viewport_size = _get_viewport_size()
	var target_width = clamp(viewport_size.x * 0.48, 460.0, 620.0)
	var panel = _create_nine_patch_dialog(dialog_assets.textures.alert_bigger, Vector2(target_width, 0))

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(content_vbox)

	var header_hbox = HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(header_hbox)

	var close_btn = _make_close_button(dialog_assets)
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size = close_btn.custom_minimum_size
	header_hbox.add_child(header_spacer)

	var item = pedestal.item_data
	var title_label = Label.new()
	title_label.text = item.name if item != null else "Empty Pedestal"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(title_label, dialog_assets.font, 26, ink_color)
	header_hbox.add_child(title_label)

	header_hbox.add_child(close_btn)

	if item != null and item.icon != "" and OD.Load.exists(item.icon):
		var icon_rect = TextureRect.new()
		icon_rect.texture = OD.Load.image(item.icon)
		icon_rect.custom_minimum_size = Vector2(56, 56)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content_vbox.add_child(icon_rect)

	var desc_label = Label.new()
	desc_label.text = item.description if item != null and item.description != "" else "A fine piece of dungeon merchandise."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(desc_label, dialog_assets.font, 18, ink_color)
	content_vbox.add_child(desc_label)

	var price_label = Label.new()
	price_label.text = "Price: " + str(item.price) + " zm   |   Your Zorkmids: " + str(zorkmids_ref.value)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(price_label, dialog_assets.font, 19, ink_color)
	content_vbox.add_child(price_label)

	var status_label = Label.new()
	status_label.text = ""
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(status_label, dialog_assets.font, 17, Color(0.55, 0.1, 0.1))
	content_vbox.add_child(status_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_theme_constant_override("separation", 12)
	content_vbox.add_child(btn_hbox)

	var buy_btn = OD.Chrome.button(dialog_assets.textures.buy)
	buy_btn.offset_left = 0
	buy_btn.offset_top = 0
	buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_btn.pressed.connect(func():
		if zorkmids_ref.value >= item.price:
			zorkmids_ref.value -= item.price
			OD.Audio.play_sfx("item_purchase")
			player_bag.append({
				name = item.name,
				icon = item.icon,
				sell_price = item.sell_price,
				description = item.description
			})
			pedestal.clear_item(true)
			_dismiss()
		else:
			OD.Audio.play_sfx("zorkmidslow1")
			status_label.text = "Not enough Zorkmids!"
			status_label.visible = true
	)
	btn_hbox.add_child(buy_btn)

	var tab_btn = _make_styled_button("Take (Tab)", dialog_assets.font, ink_color, dialog_assets)
	tab_btn.pressed.connect(func():
		if shop != null:
			shop.unpaid_total += item.price
		player_bag.append({
			name = item.name,
			icon = item.icon,
			sell_price = item.sell_price,
			description = item.description
		})
		pedestal.clear_item(false)
		OD.Audio.play_sfx("metal_get")
		if shop != null and not shop.is_hostile and on_tab.is_valid():
			on_tab.call()
		if shop != null and shop.is_hostile and on_steal.is_valid():
			on_steal.call()
		_dismiss()
	)
	btn_hbox.add_child(tab_btn)

	var cancel_btn = OD.Chrome.button(dialog_assets.textures.dont_buy)
	cancel_btn.offset_left = 0
	cancel_btn.offset_top = 0
	cancel_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cancel_btn.pressed.connect(_dismiss)
	btn_hbox.add_child(cancel_btn)

func show_brax_dialog(shop, zorkmids_ref, player_bag, on_close = Callable(), on_steal = Callable(), on_pay_tab = Callable()):
	layer = 10
	_on_close_callback = on_close
	var dialog_assets = OD.Assets.dialog()
	var ink_color = Color(0.12, 0.08, 0.05)
	var viewport_size = _get_viewport_size()
	var target_width = clamp(viewport_size.x * 0.58, 560.0, 780.0)
	var target_height = clamp(viewport_size.y * 0.72, 420.0, 660.0)
	var panel = _create_nine_patch_dialog(dialog_assets.textures.alert_bigger, Vector2(target_width, target_height))

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(content_vbox)

	var header_hbox = HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(header_hbox)

	var close_btn = _make_close_button(dialog_assets)
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size = close_btn.custom_minimum_size
	header_hbox.add_child(header_spacer)

	var title_label = Label.new()
	title_label.text = "Brax's Emporium"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(title_label, dialog_assets.font, 28, ink_color)
	header_hbox.add_child(title_label)

	header_hbox.add_child(close_btn)

	var status_label = Label.new()
	status_label.text = "Welcome! Browse my wares or sell your loot."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(status_label, dialog_assets.font, 18, ink_color)
	content_vbox.add_child(status_label)

	var wallet_label = Label.new()
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(wallet_label, dialog_assets.font, 20, ink_color)
	content_vbox.add_child(wallet_label)

	var pay_tab_btn = _make_styled_button("Pay Tab", dialog_assets.font, ink_color, dialog_assets)
	pay_tab_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var refresh_wallet = func():
		wallet_label.text = "Zorkmids: " + str(zorkmids_ref.value) + "   |   Unpaid Tab: " + str(shop.unpaid_total) + " zm"
		pay_tab_btn.visible = shop.unpaid_total > 0
		pay_tab_btn.text = "Pay Tab (" + str(shop.unpaid_total) + " zm)"

	pay_tab_btn.pressed.connect(func():
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
	tab_bar.add_theme_constant_override("separation", 10)
	content_vbox.add_child(tab_bar)

	var summary_tab_btn = _make_styled_button("Summary", dialog_assets.font, ink_color, dialog_assets)
	var buy_tab_btn = _make_styled_button("Buy", dialog_assets.font, ink_color, dialog_assets)
	var sell_tab_btn = _make_styled_button("Sell", dialog_assets.font, ink_color, dialog_assets)
	tab_bar.add_child(summary_tab_btn)
	tab_bar.add_child(buy_tab_btn)
	tab_bar.add_child(sell_tab_btn)

	var tab_pages = Control.new()
	tab_pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(tab_pages)

	var summary_page = VBoxContainer.new()
	summary_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	summary_page.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_page.add_theme_constant_override("separation", 16)
	tab_pages.add_child(summary_page)

	var summary_desc = Label.new()
	summary_desc.text = "Settle your unpaid tab, browse pedestal wares in Buy, or offload loot in Sell."
	summary_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(summary_desc, dialog_assets.font, 18, ink_color)
	summary_page.add_child(summary_desc)

	summary_page.add_child(pay_tab_btn)

	var summary_actions = HBoxContainer.new()
	summary_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_actions.add_theme_constant_override("separation", 18)
	summary_page.add_child(summary_actions)

	var steal_btn = _make_styled_button("Attempt Theft", dialog_assets.font, Color(0.55, 0.08, 0.08), dialog_assets)
	steal_btn.pressed.connect(func():
		if on_steal.is_valid():
			on_steal.call()
		_dismiss()
	)
	summary_actions.add_child(steal_btn)

	var done_btn = OD.Chrome.button(dialog_assets.textures.ok)
	done_btn.offset_left = 0
	done_btn.offset_top = 0
	done_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	done_btn.pressed.connect(_dismiss)
	summary_actions.add_child(done_btn)

	var buy_scroll = ScrollContainer.new()
	buy_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	buy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_pages.add_child(buy_scroll)

	var buy_margin = MarginContainer.new()
	buy_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_margin.add_theme_constant_override("margin_right", 12)
	buy_scroll.add_child(buy_margin)

	var buy_vbox = VBoxContainer.new()
	buy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_vbox.add_theme_constant_override("separation", 8)
	buy_margin.add_child(buy_vbox)

	var sell_scroll = ScrollContainer.new()
	sell_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	sell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_pages.add_child(sell_scroll)

	var sell_margin = MarginContainer.new()
	sell_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_margin.add_theme_constant_override("margin_right", 12)
	sell_scroll.add_child(sell_margin)

	var sell_vbox = VBoxContainer.new()
	sell_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_vbox.add_theme_constant_override("separation", 8)
	sell_margin.add_child(sell_vbox)

	_populate_buy_list(buy_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet, sell_vbox)
	_populate_sell_list(sell_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet)

	var select_tab = func(tab_idx):
		summary_page.visible = (tab_idx == 0)
		buy_scroll.visible = (tab_idx == 1)
		sell_scroll.visible = (tab_idx == 2)
		summary_tab_btn.modulate = Color.WHITE if tab_idx == 0 else Color(0.82, 0.78, 0.72)
		buy_tab_btn.modulate = Color.WHITE if tab_idx == 1 else Color(0.82, 0.78, 0.72)
		sell_tab_btn.modulate = Color.WHITE if tab_idx == 2 else Color(0.82, 0.78, 0.72)

	summary_tab_btn.pressed.connect(func(): select_tab.call(0))
	buy_tab_btn.pressed.connect(func(): select_tab.call(1))
	sell_tab_btn.pressed.connect(func(): select_tab.call(2))
	select_tab.call(0)

func _populate_buy_list(buy_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet, sell_vbox):
	for child in buy_vbox.get_children():
		child.queue_free()
	var any_stock = false
	for pedestal in shop.pedestals:
		if not is_instance_valid(pedestal) or not pedestal.has_item():
			continue
		any_stock = true
		var item = pedestal.item_data
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		buy_vbox.add_child(row)
		if item.icon != "" and OD.Load.exists(item.icon):
			var icon_rect = TextureRect.new()
			icon_rect.texture = OD.Load.image(item.icon)
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon_rect)
		var item_label = Label.new()
		item_label.text = item.name + " (" + str(item.price) + " zm)"
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(item_label, dialog_assets.font, 17, ink_color)
		row.add_child(item_label)
		var buy_btn = OD.Chrome.button(dialog_assets.textures.buy)
		buy_btn.offset_left = 0
		buy_btn.offset_top = 0
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy_btn.pressed.connect(func():
			if zorkmids_ref.value >= item.price:
				zorkmids_ref.value -= item.price
				OD.Audio.play_sfx("item_purchase")
				player_bag.append({
					name = item.name,
					icon = item.icon,
					sell_price = item.sell_price,
					description = item.description
				})
				pedestal.clear_item(true)
				status_label.text = "Purchased " + item.name + "!"
				refresh_wallet.call()
				_populate_buy_list(buy_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet, sell_vbox)
				_populate_sell_list(sell_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet)
			else:
				OD.Audio.play_sfx("zorkmidslow1")
				status_label.text = "Not enough Zorkmids!"
		)
		row.add_child(buy_btn)
	if not any_stock:
		var empty_buy = Label.new()
		empty_buy.text = "No items remaining on pedestals."
		empty_buy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(empty_buy, dialog_assets.font, 16, ink_color)
		buy_vbox.add_child(empty_buy)

func _populate_sell_list(sell_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet):
	for child in sell_vbox.get_children():
		child.queue_free()
	if player_bag.is_empty():
		var empty_sell = Label.new()
		empty_sell.text = "Your bag is empty."
		empty_sell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_label(empty_sell, dialog_assets.font, 16, ink_color)
		sell_vbox.add_child(empty_sell)
		return
	for idx in range(player_bag.size()):
		var bag_item = player_bag[idx]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		sell_vbox.add_child(row)
		if bag_item.get("icon", "") != "" and OD.Load.exists(bag_item.icon):
			var icon_rect = TextureRect.new()
			icon_rect.texture = OD.Load.image(bag_item.icon)
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon_rect)
		var sell_val = int(bag_item.get("sell_price", 5))
		var item_label = Label.new()
		item_label.text = bag_item.name + " (+" + str(sell_val) + " zm)"
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_label(item_label, dialog_assets.font, 17, ink_color)
		row.add_child(item_label)
		var sell_btn = OD.Chrome.button(dialog_assets.textures.sell)
		sell_btn.offset_left = 0
		sell_btn.offset_top = 0
		sell_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sell_btn.pressed.connect(func():
			zorkmids_ref.value += sell_val
			OD.Audio.play_sfx("item_purchase")
			player_bag.remove_at(idx)
			status_label.text = "Sold " + bag_item.name + " for " + str(sell_val) + " zm!"
			refresh_wallet.call()
			_populate_sell_list(sell_vbox, shop, zorkmids_ref, player_bag, dialog_assets, ink_color, status_label, refresh_wallet)
		)
		row.add_child(sell_btn)

func _dismiss():
	if _on_close_callback.is_valid():
		_on_close_callback.call()
	queue_free()

func _get_viewport_size():
	var vp = get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return Vector2(1280, 720)

func _style_label(label, font, font_size, color):
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

func _make_close_button(dialog_assets):
	var close_btn = OD.Chrome.button(dialog_assets.textures.close)
	var scaled_size = close_btn.texture_normal.get_size() * 2.0
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.custom_minimum_size = scaled_size
	close_btn.size = scaled_size
	close_btn.offset_left = 0
	close_btn.offset_top = 0
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_dismiss)
	return close_btn

func _make_styled_button(text_value, font, text_color, dialog_assets = null):
	var blank_textures = dialog_assets.textures.get("blank", null) if dialog_assets != null else null
	return OD.Chrome.parchment_button(text_value, font, text_color, blank_textures)

func _create_nine_patch_dialog(bg_texture, min_size):
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_ctrl)

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.45)
	root_ctrl.add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(center)

	var style_box = StyleBoxTexture.new()
	style_box.texture = bg_texture
	style_box.texture_margin_left = 44
	style_box.texture_margin_right = 44
	style_box.texture_margin_top = 44
	style_box.texture_margin_bottom = 44
	style_box.content_margin_left = 36
	style_box.content_margin_right = 36
	style_box.content_margin_top = 30
	style_box.content_margin_bottom = 32

	var panel = PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", style_box)
	center.add_child(panel)
	return panel
