extends Node2D

const SpellHotbarScript = preload("res://script/instance/ui/spell_hotbar.gd")
const BuffBarScript = preload("res://script/instance/ui/buff_bar.gd")

static func init_container():
	return Node2D.new()

var moveable_container
var _dungeon = null
var _floor_label = null
var _turn_label = null
var _spell_hotbar = null
var _buff_bar = null

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	# TODO Remove unless testing
	if OD.DungeonSettings.get_settings().hero == null:
		_dev_seed()
	
	var assets = OD.Assets.game()	
	var	container = OD.Scenes.container()
	
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
	
	_dungeon = Dungeon.new()
	_dungeon.init()
	_dungeon.name = "Dungeon"
	moveable_container.add_child(_dungeon)
	
	var gui = Control.new()
	gui.name = "GUI"
	moveable_container.add_child(gui)

	var hud_layer = CanvasLayer.new()
	hud_layer.name = "FloorHudLayer"
	container.add_child(hud_layer)
	_floor_label = Label.new()
	_floor_label.position = Vector2(16, 12)
	_floor_label.add_theme_font_override("font", OD.Assets.dialog().font)
	_floor_label.add_theme_font_size_override("font_size", 20)
	_floor_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.65))
	_floor_label.add_theme_constant_override("outline_size", 3)
	_floor_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_floor_label.text = "Floor " + str(_dungeon.get_floor_level()) + " - " + _dungeon.get_branch_name()
	hud_layer.add_child(_floor_label)
	_turn_label = Label.new()
	_turn_label.position = Vector2(16, 38)
	_turn_label.add_theme_font_override("font", OD.Assets.dialog().font)
	_turn_label.add_theme_font_size_override("font_size", 16)
	_turn_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_turn_label.add_theme_constant_override("outline_size", 2)
	_turn_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_turn_label.text = "Turn 0"
	hud_layer.add_child(_turn_label)
	_spell_hotbar = SpellHotbarScript.new().init(_dungeon)
	hud_layer.add_child(_spell_hotbar)
	_buff_bar = BuffBarScript.new().init(_dungeon.get_player())
	hud_layer.add_child(_buff_bar)
	_dungeon.floor_changed.connect(_on_floor_changed)
	_dungeon.get_turn_scheduler().turn_started.connect(_on_turn_started)
	_dungeon.get_turn_scheduler().turn_completed.connect(_on_turn_completed)
	_dungeon.get_input_mapper().sync_from_settings()
	call_deferred("_center_on_player")
	
	OD.Audio.play(assets.music.default)

func _center_on_player():
	if moveable_container == null or _dungeon == null or not is_instance_valid(_dungeon):
		return
	var player_global = _dungeon.get_player_global_position()
	if player_global == null:
		return
	var target_screen = OD.Settings.display_size() / 2.0
	moveable_container.global_position += target_screen - player_global

func _on_floor_changed(floor_level, branch_name):
	if is_instance_valid(_floor_label):
		_floor_label.text = "Floor " + str(floor_level) + " - " + branch_name
	_camera_follow_enabled = true
	call_deferred("_center_on_player")

func _on_turn_started(_turn_number):
	_camera_follow_enabled = true

func _on_turn_completed(turn_number, _summary):
	if is_instance_valid(_turn_label):
		_turn_label.text = "Turn " + str(turn_number)

func _dev_seed():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
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

func _input(ev):
	if _dungeon == null or not is_instance_valid(_dungeon):
		return
	if _spell_hotbar != null and _spell_hotbar.handle_key_input(ev):
		return
	if _spell_hotbar != null and _spell_hotbar.is_spellbook_open():
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
