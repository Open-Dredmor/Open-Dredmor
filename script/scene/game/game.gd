extends Node2D

const CoreHudScript = preload("res://script/instance/ui/core_hud.gd")
const BuffBarScript = preload("res://script/instance/ui/buff_bar.gd")
const InventoryDialogScript = preload("res://script/instance/ui/inventory_dialog.gd")

static func init_container():
	return Node2D.new()

var moveable_container
var _dungeon = null
var _core_hud = null
var _buff_bar = null
var _hud_layer = null
var _death_dialog = null
var _inventory_dialog = null

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	if OD.DungeonSettings.get_settings().hero == null:
		await _dev_seed()

	if OD.Loading != null:
		await OD.Loading.step("Loading game audio & assets...", 80.0)
	var assets = OD.Assets.game()
	var container = OD.Scenes.container()

	var centered_container = Panel.new()
	centered_container.set_size(OD.Settings.display_size())
	centered_container.name = "CenteredContainer"
	container.add_child(centered_container)
	var hbox = HBoxContainer.new()
	hbox.anchor_left = .3
	hbox.anchor_top = .2
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.name = "HBox"
	centered_container.add_child(hbox)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.name = "VBox"
	hbox.add_child(vbox)

	moveable_container = Node2D.new()
	moveable_container.name = "MoveableContainer"
	vbox.add_child(moveable_container)

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
		on_inventory = toggle_inventory,
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
	var wait_ev = InputEventKey.new()
	wait_ev.keycode = KEY_SPACE
	wait_ev.pressed = true
	_dungeon.handle_dungeon_input(wait_ev)

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

	var vp_size = OD.Settings.display_size()
	var dialog_w = clamp(vp_size.x * 0.48, 420.0, 640.0)
	var dialog_h = clamp(vp_size.y * 0.55, 340.0, 520.0)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(dialog_w, dialog_h)
	var dialog_assets = OD.Assets.dialog()
	var bg_tex = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	if bg_tex != null:
		var style_box = StyleBoxTexture.new()
		style_box.texture = bg_tex
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

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(header_hbox)

	if OD.Load != null and OD.Load.exists("ui/dredmor_grave.png"):
		var grave_tex = OD.Load.image("ui/dredmor_grave.png")
		if grave_tex != null:
			var grave_rect = TextureRect.new()
			grave_rect.texture = grave_tex
			grave_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			grave_rect.custom_minimum_size = Vector2(64, 64)
			header_hbox.add_child(grave_rect)

	var title = Label.new()
	title.text = "Here Lies " + str(entry.get("name", "Unknown"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", dialog_assets.font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.58, 0.08, 0.08))
	header_hbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var details = Label.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_override("font", dialog_assets.font)
	details.add_theme_font_size_override("font_size", 20)
	details.add_theme_color_override("font_color", Color(0.16, 0.1, 0.06))
	var skills_str = ", ".join(entry.get("skills", []))
	var lines = [
		"Level: %d | Floor: %d | Difficulty: %s" % [int(entry.get("level", 1)), int(entry.get("floor", 1)), str(entry.get("difficulty", "Medium"))],
		"Slain by: %s" % str(entry.get("cause_of_death", "Unknown")),
		"Final Score: %d" % int(entry.get("score", 0)),
		"Skills: %s" % (skills_str if skills_str != "" else "None")
	]
	if perma_deleted:
		lines.append("Permadeath: Save file deleted.")
	details.text = "\n".join(lines)
	scroll.add_child(details)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vbox.add_child(btn_row)

	var ink_color = Color(0.18, 0.12, 0.08)
	var blank_tex = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var scores_btn = OD.Chrome.parchment_button("High Scores", dialog_assets.font, ink_color, blank_tex, 20)
	scores_btn.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.HIGH_SCORES_MENU))
	btn_row.add_child(scores_btn)

	var menu_btn = OD.Chrome.parchment_button("Main Menu", dialog_assets.font, ink_color, blank_tex, 20)
	menu_btn.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.MAIN_MENU))
	btn_row.add_child(menu_btn)

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
var _drag_start_pos = Vector2.ZERO
var _drag_press_time_ms = 0
var _total_pan_px = 0.0
var old_position

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
	_inventory_dialog = InventoryDialogScript.new().init(player, {
		on_drop_inventory = func(inv_idx, count): _dungeon.drop_inventory_item(inv_idx, count),
		on_drop_equipped = func(slot_name): _dungeon.drop_equipped_item(slot_name),
		on_use_inventory = func(inv_idx):
			var use_res = _dungeon.begin_use_inventory_item(inv_idx)
			if typeof(use_res) == TYPE_DICTIONARY and use_res.get("open_crafting", false):
				toggle_inventory()
				_dungeon.open_crafting_dialog(str(use_res.get("tool_tag", "")))
			elif typeof(use_res) == TYPE_DICTIONARY and use_res.get("targeting", false):
				toggle_inventory(),
		on_pickup = func(): _dungeon.pickup_loot_at_player(),
		on_close = func(): _inventory_dialog = null
	})
	_hud_layer.add_child(_inventory_dialog)

func _input(ev):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if is_instance_valid(_inventory_dialog):
		return
	if ev is InputEventKey and ev.is_pressed() and not ev.echo and ev.keycode == KEY_I:
		if not _dungeon.is_dialog_open() and (_core_hud == null or not _core_hud.is_modal_open()):
			toggle_inventory()
			return
	if ev is InputEventKey and ev.is_pressed() and not ev.echo and ev.keycode == KEY_C:
		if not _dungeon.is_dialog_open() and (_core_hud == null or not _core_hud.is_modal_open()):
			_dungeon.open_crafting_dialog()
			return
	if _core_hud != null and _core_hud.handle_key_input(ev):
		return
	if _core_hud != null and _core_hud.is_modal_open():
		return
	if ev is InputEventKey and ev.is_pressed() and not ev.echo and ev.keycode == KEY_ESCAPE and not _dungeon.is_dialog_open() and _dungeon.get_pending_spell_name() == "":
		if _core_hud != null:
			_core_hud.toggle_pause_menu()
			return
	if _dungeon.is_dialog_open():
		drag_enabled = false
		_is_dragging = false
		_dungeon.handle_dungeon_input(ev)
		return
	var mapper = _dungeon.get_input_mapper()
	var cam_action = mapper.translate_camera_input(ev) if mapper != null else null
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
					_drag_start_pos = cam_action.position
					_drag_press_time_ms = Time.get_ticks_msec()
					_total_pan_px = 0.0
					old_position = get_global_mouse_position()
				else:
					var held_ms = Time.get_ticks_msec() - _drag_press_time_ms
					var was_drag = _is_dragging or _total_pan_px >= DRAG_THRESHOLD_PX or cam_action.position.distance_to(_drag_start_pos) >= DRAG_THRESHOLD_PX or held_ms >= CLICK_MAX_HOLD_MS
					drag_enabled = false
					_is_dragging = false
					if not was_drag:
						_dungeon.handle_dungeon_input(ev)
				return
			"drag_motion":
				if drag_enabled and cam_action.position.distance_to(_drag_start_pos) >= DRAG_THRESHOLD_PX:
					_is_dragging = true
			"zoom":
				_zoom_at(cam_action.factor)
				return
			"reset_zoom":
				_reset_zoom()
				return
			"ignore":
				return
	_dungeon.handle_dungeon_input(ev)

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
