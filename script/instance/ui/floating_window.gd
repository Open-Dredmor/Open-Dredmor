extends Control

class_name FloatingWindow

signal focused
signal closed

const GROUP_NAME = "od_floating_windows"
const BASE_LAYER = 12
const MAX_LAYER_BEFORE_COMPACT = 26

const DRAG_BAR_HEIGHT = 36.0
const EDGE_MARGIN = 8.0
const CORNER_SIZE = 18.0
const MIN_VISIBLE_X = 80.0
const MIN_VISIBLE_Y = 48.0

var min_window_size = Vector2(280, 220)
var max_window_size = Vector2(1400, 1000)
var base_size = Vector2.ZERO

var _content_root = null
var _grip_overlay = null
var _drag_mode = ""
var _drag_start_mouse = Vector2.ZERO
var _drag_start_pos = Vector2.ZERO
var _drag_start_size = Vector2.ZERO

static func raise_window(win):
	if win == null or not is_instance_valid(win):
		return
	var host = win.get_parent()
	if not (host is CanvasLayer):
		return
	var tree = win.get_tree()
	if tree == null:
		return
	var windows = tree.get_nodes_in_group(GROUP_NAME)
	var layers = []
	for node in windows:
		if node == win or not is_instance_valid(node):
			continue
		var parent_layer = node.get_parent()
		if parent_layer is CanvasLayer:
			layers.append({ layer_node = parent_layer, z = parent_layer.layer })
	layers.sort_custom(func(aa, bb): return aa.z < bb.z)
	var next_z = BASE_LAYER
	if not layers.is_empty() and layers[layers.size() - 1].z < MAX_LAYER_BEFORE_COMPACT:
		next_z = layers[layers.size() - 1].z + 1
	else:
		for item in layers:
			item.layer_node.layer = next_z
			next_z += 1
	host.layer = next_z
	win.focused.emit()

static func is_point_over_any(tree, screen_pos):
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(GROUP_NAME):
		if not is_instance_valid(node) or not node.visible:
			continue
		if node.is_interacting():
			return true
		if node.get_global_rect().has_point(screen_pos):
			return true
	return false

static func get_topmost_window(tree):
	if tree == null:
		return null
	var best_win = null
	var best_layer = -1
	for node in tree.get_nodes_in_group(GROUP_NAME):
		if not is_instance_valid(node) or not node.visible:
			continue
		var parent_layer = node.get_parent()
		var z_val = parent_layer.layer if parent_layer is CanvasLayer else 0
		if best_win == null or z_val >= best_layer:
			best_win = node
			best_layer = z_val
	return best_win

func _ready():
	add_to_group(GROUP_NAME)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_grip_overlay()
	raise_window(self)

func _ensure_grip_overlay():
	if _grip_overlay != null and is_instance_valid(_grip_overlay):
		return
	_grip_overlay = Control.new()
	_grip_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grip_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grip_overlay.z_index = 20
	_grip_overlay.draw.connect(_draw_grip)
	add_child(_grip_overlay)

func get_content_root():
	if _content_root == null or not is_instance_valid(_content_root):
		_content_root = Control.new()
		_content_root.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_content_root)
		if _grip_overlay != null and is_instance_valid(_grip_overlay):
			_grip_overlay.move_to_front()
	return _content_root

func set_base_size(target_base_size, initial_scale = 1.0):
	base_size = target_base_size
	var root = get_content_root()
	root.custom_minimum_size = base_size
	root.size = base_size
	size = base_size * initial_scale
	_sync_content_scale()
	if _grip_overlay != null and is_instance_valid(_grip_overlay):
		_grip_overlay.queue_redraw()

func get_current_scale():
	if base_size.x <= 0.0:
		return 1.0
	return size.x / base_size.x

func _sync_content_scale():
	if _content_root == null or not is_instance_valid(_content_root) or base_size.x <= 0.0:
		return
	var scale_factor = size.x / base_size.x
	_content_root.scale = Vector2(scale_factor, scale_factor)

func is_interacting():
	return _drag_mode != ""

func _get_viewport_bounds():
	var vp = get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return Vector2(1280, 720)

func clamp_to_viewport():
	var vp_size = _get_viewport_bounds()
	var max_w = min(max_window_size.x, vp_size.x - 16.0)
	var max_h = min(max_window_size.y, vp_size.y - 16.0)
	if size.x > 0.0 and size.y > 0.0:
		var min_scale = max(min_window_size.x / size.x, min_window_size.y / size.y)
		var max_scale = min(max_w / size.x, max_h / size.y)
		if max_scale < 1.0 or min_scale > 1.0:
			var clamped_scale = clamp(1.0, min_scale, max(min_scale, max_scale))
			size = size * clamped_scale
	_sync_content_scale()
	var min_x = -size.x + MIN_VISIBLE_X
	var max_x = vp_size.x - MIN_VISIBLE_X
	var min_y = -size.y + MIN_VISIBLE_Y
	var max_y = vp_size.y - MIN_VISIBLE_Y
	position = Vector2(clamp(position.x, min_x, max_x), clamp(position.y, min_y, max_y))

func _detect_hit_zone(local_pos):
	if not Rect2(Vector2.ZERO, size).has_point(local_pos):
		return ""
	var in_right = local_pos.x >= size.x - EDGE_MARGIN and local_pos.x <= size.x + 2.0
	var in_bottom = local_pos.y >= size.y - EDGE_MARGIN and local_pos.y <= size.y + 2.0
	var in_corner = local_pos.x >= size.x - CORNER_SIZE and local_pos.y >= size.y - CORNER_SIZE
	if in_corner or (in_right and in_bottom):
		return "resize_both"
	if in_right:
		return "resize_x"
	if in_bottom:
		return "resize_y"
	return "move"

func _update_cursor_for_zone(zone):
	match zone:
		"resize_both":
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		"resize_x":
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		"resize_y":
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
		"move":
			mouse_default_cursor_shape = Control.CURSOR_MOVE if _drag_mode == "move" else Control.CURSOR_ARROW
		_:
			mouse_default_cursor_shape = Control.CURSOR_ARROW

func _input(ev):
	if not visible:
		return
	if ev is InputEventMouseButton and ev.pressed:
		if get_global_rect().has_point(ev.position):
			var top_win = get_topmost_window(get_tree())
			if top_win == self or not is_point_over_higher_window(ev.position):
				raise_window(self)
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if is_point_over_higher_window(ev.position):
				return
			var local_pos = ev.position - global_position
			var zone = _detect_hit_zone(local_pos)
			if zone != "" and (zone != "move" or not _is_point_on_interactive_child(ev.position)):
				_drag_mode = zone
				_drag_start_mouse = ev.position
				_drag_start_pos = position
				_drag_start_size = size
				_update_cursor_for_zone(zone)
				get_viewport().set_input_as_handled()
	elif ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _drag_mode != "":
			_drag_mode = ""
			_update_cursor_for_zone("")
			get_viewport().set_input_as_handled()
	elif ev is InputEventMouseMotion:
		if _drag_mode != "":
			_apply_drag_motion(ev.position)
			get_viewport().set_input_as_handled()
		else:
			var local_pos = ev.position - global_position
			if Rect2(Vector2.ZERO, size).has_point(local_pos) and not is_point_over_higher_window(ev.position):
				_update_cursor_for_zone(_detect_hit_zone(local_pos))

func is_point_over_higher_window(screen_pos):
	var my_layer = get_parent().layer if get_parent() is CanvasLayer else 0
	var tree = get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(GROUP_NAME):
		if node == self or not is_instance_valid(node) or not node.visible:
			continue
		var other_layer = node.get_parent().layer if node.get_parent() is CanvasLayer else 0
		if other_layer > my_layer and node.get_global_rect().has_point(screen_pos):
			return true
	return false

func _is_point_on_interactive_child(screen_pos):
	return _check_interactive_recursive(self, screen_pos)

func _check_interactive_recursive(node, screen_pos):
	for child in node.get_children():
		if child is Control and child.visible:
			var is_interactive = child is BaseButton or child is Slider or child is ScrollBar or child is LineEdit or child is TextEdit
			if is_interactive and child.mouse_filter != Control.MOUSE_FILTER_IGNORE and child.get_global_rect().has_point(screen_pos):
				return true
			if _check_interactive_recursive(child, screen_pos):
				return true
	return false

func _apply_drag_motion(mouse_pos):
	var delta = mouse_pos - _drag_start_mouse
	var vp_size = _get_viewport_bounds()
	if _drag_mode == "move":
		position = _drag_start_pos + delta
		clamp_to_viewport()
		return
	if _drag_start_size.x <= 0.0 or _drag_start_size.y <= 0.0:
		return
	var raw_scale = 1.0
	if _drag_mode == "resize_x":
		raw_scale = (_drag_start_size.x + delta.x) / _drag_start_size.x
	elif _drag_mode == "resize_y":
		raw_scale = (_drag_start_size.y + delta.y) / _drag_start_size.y
	elif _drag_mode == "resize_both":
		var sx = (_drag_start_size.x + delta.x) / _drag_start_size.x
		var sy = (_drag_start_size.y + delta.y) / _drag_start_size.y
		raw_scale = sx if abs(sx - 1.0) >= abs(sy - 1.0) else sy
	var min_scale = max(min_window_size.x / _drag_start_size.x, min_window_size.y / _drag_start_size.y)
	var max_w = min(max_window_size.x, vp_size.x - position.x - 8.0)
	var max_h = min(max_window_size.y, vp_size.y - position.y - 8.0)
	var max_scale = min(max_w / _drag_start_size.x, max_h / _drag_start_size.y)
	var final_scale = clamp(raw_scale, min_scale, max(min_scale, max_scale))
	size = _drag_start_size * final_scale
	_sync_content_scale()
	if _grip_overlay != null and is_instance_valid(_grip_overlay):
		_grip_overlay.queue_redraw()

func _draw_grip():
	if _grip_overlay == null:
		return
	var grip_color = Color(0.92, 0.78, 0.44, 0.85)
	for ii in range(3):
		var offset = 4.0 + ii * 4.0
		_grip_overlay.draw_line(Vector2(size.x - offset, size.y - 2.0), Vector2(size.x - 2.0, size.y - offset), grip_color, 1.5)
