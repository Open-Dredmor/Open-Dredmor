extends Node2D

const CoreHudScript = preload("res://script/instance/ui/core_hud.gd")
const BuffBarScript = preload("res://script/instance/ui/buff_bar.gd")
const InventoryDialogScript = preload("res://script/instance/ui/inventory_dialog.gd")
const FloatingWindowScript = preload("res://script/instance/ui/floating_window.gd")

static func init_container():
	return Node2D.new()

var moveable_container
var _dungeon = null
var _core_hud = null
var _buff_bar = null
var _hud_layer = null
var _death_dialog = null
var _inventory_dialog = null
var _character_dialog = null

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	if OD.DungeonSettings.get_settings().hero == null:
		await _dev_seed()
	else:
		if OD.Audio != null and OD.Audio._root == null:
			OD.Audio.setup(get_tree().get_root())
		if OD.Database.packs == null:
			await OD.Database.ingest_async(10.0, 75.0)
		elif OD.DungeonSettings.has_initialized_packs() and OD.Database.get_active_packs() != OD.DungeonSettings.get_active_packs():
			OD.Database.set_active_packs(OD.DungeonSettings.get_active_packs())

	if OD.Loading != null:
		await OD.Loading.step("Loading game audio & assets...", 80.0)
	var assets = OD.Assets.game()
	var container = OD.Scenes.container()

	var centered_container = Panel.new()
	centered_container.set_size(OD.Settings.display_size())
	centered_container.name = "CenteredContainer"
	container.add_child(centered_container)
	var horizontal_box = HBoxContainer.new()
	horizontal_box.anchor_left = .3
	horizontal_box.anchor_top = .2
	horizontal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	horizontal_box.name = "HBox"
	centered_container.add_child(horizontal_box)
	var vertical_box = VBoxContainer.new()
	vertical_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vertical_box.name = "VBox"
	horizontal_box.add_child(vertical_box)

	moveable_container = Node2D.new()
	moveable_container.name = "MoveableContainer"
	vertical_box.add_child(moveable_container)

	if OD.Loading != null:
		await OD.Loading.step("Generating dungeon floor...", 82.0)
	_dungeon = Dungeon.new()
	_dungeon.name = "Dungeon"
	moveable_container.add_child(_dungeon)
	await _dungeon.init_async()

	if OD.Loading != null:
		await OD.Loading.step("Building HUD...", 97.0)
	var hud_layer = CanvasLayer.new()
	hud_layer.name = "FloorHudLayer"
	container.add_child(hud_layer)
	_hud_layer = hud_layer
	_core_hud = CoreHudScript.new().init(_dungeon, {
		on_character = toggle_character,
		on_inventory = toggle_inventory,
		on_crafting = _toggle_crafting,
		on_before_open_modal = _close_game_modals,
		on_wait = _submit_wait_turn
	})
	hud_layer.add_child(_core_hud)
	_buff_bar = BuffBarScript.new().init(_dungeon.get_player())
	hud_layer.add_child(_buff_bar)
	_dungeon.floor_changed.connect(_on_floor_changed)
	_dungeon.player_died.connect(_on_player_died)
	_dungeon.get_turn_scheduler().turn_started.connect(_on_turn_started)
	_dungeon.get_turn_scheduler().turn_completed.connect(_on_turn_completed)
	_dungeon.get_input_mapper().sync_from_settings()
	_dungeon.get_gamepad_invoker().sync_from_settings()
	if OD.EventLog != null:
		OD.EventLog.notify("Welcome to Dungeons of Dredmor!")
	call_deferred("_center_on_player")

	OD.Audio.play(assets.music.default)
	if OD.Loading != null:
		OD.Loading.hide_loading()

func _center_on_player():
	if moveable_container == null or _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player_global = _dungeon.get_player_global_position()
	if player_global == null:
		return
	var target_screen = OD.Settings.display_size() / 2.0
	moveable_container.global_position += target_screen - player_global

func _on_floor_changed(floor_level, branch_name):
	if OD.EventLog != null:
		OD.EventLog.notify("Descended to Floor " + str(floor_level) + " - " + str(branch_name) + ".")
	_camera_follow_enabled = true
	call_deferred("_center_on_player")

func _on_turn_started(_turn_number):
	_camera_follow_enabled = true

func _on_turn_completed(_turn_number, _summary):
	pass

func _submit_wait_turn():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	var mapper = _dungeon.get_input_mapper()
	if mapper != null and mapper.has_method("create_wait_command"):
		_dungeon.submit_command(mapper.create_wait_command())
		return
	var wait_event = InputEventKey.new()
	wait_event.keycode = KEY_SPACE
	wait_event.pressed = true
	_dungeon.handle_dungeon_input(wait_event)

func _on_player_died(summary):
	if _hud_layer == null or is_instance_valid(_death_dialog):
		return
	var entry = summary.get("score_entry", {})
	var perma_deleted = bool(summary.get("permadeath_deleted", false))

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	_hud_layer.add_child(backdrop)
	_death_dialog = backdrop

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var viewport_size = OD.Settings.display_size()
	var dialog_w = clamp(viewport_size.x * 0.48, 420.0, 640.0)
	var dialog_h = clamp(viewport_size.y * 0.55, 340.0, 520.0)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(dialog_w, dialog_h)
	var dialog_assets = OD.Assets.dialog()
	var background_texture = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	if background_texture != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = background_texture
		style_box.texture_margin_left = 44
		style_box.texture_margin_right = 44
		style_box.texture_margin_top = 44
		style_box.texture_margin_bottom = 44
		style_box.content_margin_left = 40
		style_box.content_margin_right = 40
		style_box.content_margin_top = 34
		style_box.content_margin_bottom = 36
		panel.add_theme_stylebox_override("panel", style_box)
	center.add_child(panel)

	var vertical_box = VBoxContainer.new()
	vertical_box.add_theme_constant_override("separation", 12)
	panel.add_child(vertical_box)

	var header_horizontal_box = HBoxContainer.new()
	header_horizontal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header_horizontal_box.add_theme_constant_override("separation", 14)
	vertical_box.add_child(header_horizontal_box)

	if OD.Load != null and OD.Load.exists("ui/dredmor_grave.png"):
		var grave_texture = OD.Load.image("ui/dredmor_grave.png")
		if grave_texture != null:
			var grave_rect = TextureRect.new()
			grave_rect.texture = grave_texture
			grave_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			grave_rect.custom_minimum_size = Vector2(64, 64)
			header_horizontal_box.add_child(grave_rect)

	var title = Label.new()
	title.text = "Here Lies " + str(entry.get("name", "Unknown"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", dialog_assets.font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.58, 0.08, 0.08))
	header_horizontal_box.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_box.add_child(scroll)

	var details = Label.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_override("font", dialog_assets.font)
	details.add_theme_font_size_override("font_size", 20)
	details.add_theme_color_override("font_color", Color(0.16, 0.1, 0.06))
	var skills_text = ", ".join(entry.get("skills", []))
	var lines = [
		"Level: %d | Floor: %d | Difficulty: %s" % [int(entry.get("level", 1)), int(entry.get("floor", 1)), str(entry.get("difficulty", "Medium"))],
		"Slain by: %s" % str(entry.get("cause_of_death", "Unknown")),
		"Final Score: %d" % int(entry.get("score", 0)),
		"Skills: %s" % (skills_text if skills_text != "" else "None")
	]
	if perma_deleted:
		lines.append("Permadeath: Save file deleted.")
	details.text = "\n".join(lines)
	scroll.add_child(details)

	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 18)
	vertical_box.add_child(button_row)

	var ink_color = Color(0.18, 0.12, 0.08)
	var blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var scores_button = OD.Chrome.parchment_button("High Scores", dialog_assets.font, ink_color, blank_texture, 20)
	scores_button.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.HIGH_SCORES_MENU))
	button_row.add_child(scores_button)

	var menu_button = OD.Chrome.parchment_button("Main Menu", dialog_assets.font, ink_color, blank_texture, 20)
	menu_button.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.MAIN_MENU))
	button_row.add_child(menu_button)

	scores_button.call_deferred("grab_focus")

func _dev_seed():
	OD.Audio.setup(get_tree().get_root())
	await OD.Database.ingest_async(10.0, 75.0)
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_difficulty(OD.DungeonSettings.Difficulty.Medium)
	OD.DungeonSettings.set_permadeath(false)
	OD.DungeonSettings.set_no_time_to_grind(false)
	OD.DungeonSettings.set_hero("heroine")
	OD.DungeonSettings.set_character_name("Eyebrows")
	OD.DungeonSettings.set_starting_skill_ids([0,1,2,3,4,5,6])

const DRAG_THRESHOLD_PX = 6.0
const CLICK_MAX_HOLD_MS = 160

var speed = 200
var drag_enabled = false
var _is_dragging = false
var _camera_follow_enabled = true
var _target_zoom = 1.0
var _zoom_anchor_local = Vector2.ZERO
var _has_zoom_anchor = false
var _drag_start_position = Vector2.ZERO
var _drag_press_time_ms = 0
var _total_pan_px = 0.0
var old_position

func _close_game_modals():
	if is_instance_valid(_inventory_dialog):
		_inventory_dialog.dismiss()
		_inventory_dialog = null
	if is_instance_valid(_character_dialog):
		_character_dialog.dismiss()
		_character_dialog = null
	if _dungeon != null and is_instance_valid(_dungeon) and _dungeon.has_method("close_crafting_dialog"):
		_dungeon.close_crafting_dialog()

func _toggle_crafting():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	_dungeon.open_crafting_dialog()

func _create_item_window_callbacks(close_function):
	return {
		on_drop_inventory = func(inv_idx, count): _dungeon.drop_inventory_item(inv_idx, count),
		on_drop_equipped = func(slot_name): _dungeon.drop_equipped_item(slot_name),
		on_use_inventory = func(inv_idx):
			var use_result = _dungeon.begin_use_inventory_item(inv_idx)
			if typeof(use_result) == TYPE_DICTIONARY and use_result.get("open_crafting", false):
				_dungeon.open_crafting_dialog(str(use_result.get("tool_tag", "")))
			elif typeof(use_result) == TYPE_DICTIONARY and use_result.get("targeting", false):
				_close_game_modals(),
		on_pickup = func(): _dungeon.pickup_loot_at_player(),
		on_close = close_function
	}

func toggle_character():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if is_instance_valid(_character_dialog):
		_character_dialog.dismiss()
		_character_dialog = null
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	_character_dialog = InventoryDialogScript.new().init(player, _create_item_window_callbacks(func(): _character_dialog = null), "character")
	_hud_layer.add_child(_character_dialog)

func toggle_inventory():
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if is_instance_valid(_inventory_dialog):
		_inventory_dialog.dismiss()
		_inventory_dialog = null
		return
	var player = _dungeon.get_player()
	if player == null:
		return
	_inventory_dialog = InventoryDialogScript.new().init(player, _create_item_window_callbacks(func(): _inventory_dialog = null), "inventory")
	_hud_layer.add_child(_inventory_dialog)

func _is_mouse_over_hud():
	if _hud_layer == null or not is_instance_valid(_hud_layer):
		return false
	var hovered = get_viewport().gui_get_hovered_control()
	return hovered != null and _hud_layer.is_ancestor_of(hovered)

func _has_any_floating_window():
	return FloatingWindowScript.get_topmost_window(get_tree()) != null

func _handle_ui_action(ui_action):
	match ui_action.kind:
		"toggle_inventory":
			if not _dungeon.has_interaction_dialog_open():
				toggle_inventory()
				return true
		"toggle_character":
			if not _dungeon.has_interaction_dialog_open():
				toggle_character()
				return true
		"toggle_skill_tree":
			if not _dungeon.has_interaction_dialog_open() and _core_hud != null:
				_core_hud.toggle_skill_tree()
				return true
		"toggle_crafting":
			if not _dungeon.has_interaction_dialog_open():
				_toggle_crafting()
				return true
		"toggle_pause":
			if not _dungeon.has_interaction_dialog_open() and _core_hud != null:
				_core_hud.toggle_pause_menu()
				return true
		"cancel":
			if _dungeon.get_pending_spell_name() != "":
				_dungeon.cancel_spell_targeting()
				return true
			var top_window = FloatingWindowScript.get_topmost_window(get_tree())
			if top_window != null:
				var window_owner = top_window.get_parent()
				if window_owner != null and window_owner.has_method("dismiss"):
					window_owner.dismiss()
					return true
			if not _dungeon.has_interaction_dialog_open() and _core_hud != null:
				_core_hud.toggle_pause_menu()
				return true
		"cycle_minimap_zoom":
			if _core_hud != null and _core_hud.has_method("cycle_minimap_zoom"):
				_core_hud.cycle_minimap_zoom()
				return true
	return false

func _input(event):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if is_instance_valid(_death_dialog):
		return
	if _core_hud != null and _core_hud.is_modal_open():
		return
	if _has_any_floating_window():
		if event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_ESCAPE:
			var top_window = FloatingWindowScript.get_topmost_window(get_tree())
			if top_window != null:
				var window_owner = top_window.get_parent()
				if window_owner != null and window_owner.has_method("dismiss"):
					window_owner.dismiss()
					get_viewport().set_input_as_handled()
					return
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
			var top_window = FloatingWindowScript.get_topmost_window(get_tree())
			if top_window != null:
				var window_owner = top_window.get_parent()
				if window_owner != null and window_owner.has_method("dismiss"):
					window_owner.dismiss()
					get_viewport().set_input_as_handled()
					return
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return
	for invoker in _dungeon.get_command_invokers():
		if invoker != null and invoker.has_method("translate_ui_action"):
			var ui_action = invoker.translate_ui_action(event)
			if ui_action != null and _handle_ui_action(ui_action):
				get_viewport().set_input_as_handled()
				return
	if event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_I:
		if not _dungeon.has_interaction_dialog_open():
			get_viewport().set_input_as_handled()
			toggle_inventory()
			return
	if event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_C:
		if not _dungeon.has_interaction_dialog_open():
			get_viewport().set_input_as_handled()
			toggle_character()
			return
	if event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_R:
		if not _dungeon.has_interaction_dialog_open():
			get_viewport().set_input_as_handled()
			_toggle_crafting()
			return
	if _core_hud != null and _core_hud.handle_key_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_ESCAPE and not _dungeon.has_interaction_dialog_open() and _dungeon.get_pending_spell_name() == "":
		var top_window = FloatingWindowScript.get_topmost_window(get_tree())
		if top_window != null:
			var window_owner = top_window.get_parent()
			if window_owner != null and window_owner.has_method("dismiss"):
				window_owner.dismiss()
				get_viewport().set_input_as_handled()
				return
		if _core_hud != null:
			get_viewport().set_input_as_handled()
			_core_hud.toggle_pause_menu()
			return
	if event is InputEventMouse and (FloatingWindowScript.is_point_over_any(get_tree(), event.position) or _is_mouse_over_hud()):
		drag_enabled = false
		_is_dragging = false
		return
	if _dungeon.has_interaction_dialog_open():
		drag_enabled = false
		_is_dragging = false
		_dungeon.handle_dungeon_input(event)
		return
	for invoker in _dungeon.get_command_invokers():
		var cam_action = invoker.translate_camera_input(event) if invoker != null and invoker.has_method("translate_camera_input") else null
		if cam_action != null:
			match cam_action.kind:
				"pan":
					_camera_follow_enabled = false
					moveable_container.position += cam_action.delta * speed
					return
				"center_camera":
					_camera_follow_enabled = true
					_center_on_player()
					return
				"drag":
					if cam_action.pressed:
						drag_enabled = true
						_is_dragging = false
						_drag_start_position = cam_action.position
						_drag_press_time_ms = Time.get_ticks_msec()
						_total_pan_px = 0.0
						old_position = get_global_mouse_position()
					else:
						var held_ms = Time.get_ticks_msec() - _drag_press_time_ms
						var was_drag = _is_dragging or _total_pan_px >= DRAG_THRESHOLD_PX or cam_action.position.distance_to(_drag_start_position) >= DRAG_THRESHOLD_PX or held_ms >= CLICK_MAX_HOLD_MS
						drag_enabled = false
						_is_dragging = false
						if not was_drag:
							_dungeon.handle_dungeon_input(event)
					return
				"drag_motion":
					if drag_enabled and cam_action.position.distance_to(_drag_start_position) >= DRAG_THRESHOLD_PX:
						_is_dragging = true
				"zoom":
					_zoom_at(cam_action.factor)
					return
				"reset_zoom":
					_reset_zoom()
					return
				"ignore":
					return
	_dungeon.handle_dungeon_input(event)

func _zoom_at(zoom_factor):
	if moveable_container == null:
		return
	_target_zoom = clamp(_target_zoom * zoom_factor, 0.25, 4.0)
	_zoom_anchor_local = moveable_container.get_parent().get_local_mouse_position()
	_has_zoom_anchor = true

func _reset_zoom():
	if moveable_container == null:
		return
	_target_zoom = 1.0
	_zoom_anchor_local = moveable_container.get_parent().get_local_mouse_position()
	_has_zoom_anchor = true

func _apply_smooth_zoom(delta):
	if moveable_container == null:
		return
	var old_scale = moveable_container.scale.x
	if abs(old_scale - _target_zoom) < 0.001:
		if not is_equal_approx(old_scale, _target_zoom):
			var snap_ratio = _target_zoom / old_scale
			if _has_zoom_anchor:
				moveable_container.position = _zoom_anchor_local - (_zoom_anchor_local - moveable_container.position) * snap_ratio
			moveable_container.scale = Vector2(_target_zoom, _target_zoom)
		_has_zoom_anchor = false
		return
	var new_scale = lerp(old_scale, _target_zoom, min(1.0, delta * 16.0))
	var ratio = new_scale / old_scale
	if _has_zoom_anchor:
		moveable_container.position = _zoom_anchor_local - (_zoom_anchor_local - moveable_container.position) * ratio
	moveable_container.scale = Vector2(new_scale, new_scale)

func _physics_process(delta):
	_apply_smooth_zoom(delta)
	var modal_blocking = is_instance_valid(_death_dialog) or (_core_hud != null and _core_hud.is_modal_open()) or _has_any_floating_window() or (_dungeon != null and is_instance_valid(_dungeon) and _dungeon.has_interaction_dialog_open())
	if not modal_blocking and _dungeon != null and is_instance_valid(_dungeon):
		_dungeon.process_continuous_invokers(delta)
		for invoker in _dungeon.get_command_invokers():
			if invoker != null and invoker.has_method("get_continuous_camera_pan"):
				var pan_delta = invoker.get_continuous_camera_pan(delta)
				if pan_delta != Vector2.ZERO:
					_camera_follow_enabled = false
					moveable_container.position += pan_delta
			if invoker != null and invoker.has_method("get_continuous_camera_zoom"):
				var zoom_factor = invoker.get_continuous_camera_zoom(delta)
				if not is_equal_approx(zoom_factor, 1.0):
					_target_zoom = clamp(_target_zoom * zoom_factor, 0.25, 4.0)
					_zoom_anchor_local = OD.Settings.display_size() * 0.5
					_has_zoom_anchor = true
	if old_position != null and drag_enabled:
		var new_position = get_global_mouse_position()
		var delta_position = new_position - old_position
		if delta_position.length() > 0.0:
			moveable_container.position.x += delta_position.x
			moveable_container.position.y += delta_position.y
			_total_pan_px += delta_position.length()
			old_position = new_position
		if _total_pan_px >= DRAG_THRESHOLD_PX or (Time.get_ticks_msec() - _drag_press_time_ms) >= CLICK_MAX_HOLD_MS:
			_is_dragging = true
			_camera_follow_enabled = false
	elif _camera_follow_enabled and moveable_container != null and _dungeon != null and is_instance_valid(_dungeon):
		var player_global = _dungeon.get_player_global_position()
		if player_global != null:
			var target_screen = OD.Settings.display_size() / 2.0
			var offset = target_screen - player_global
			if offset.length() > 0.5:
				moveable_container.global_position += offset * min(1.0, delta * 12.0)
			elif offset.length() > 0.0:
				moveable_container.global_position += offset
