extends RefCounted

class_name FloatingCombatText

const BADGE_PATHS = {
	crit = "ui/crit.png",
	dodge = "ui/dodge.png",
	block = "ui/block.png",
	counter = "ui/counter.png",
	resist = "ui/resist.png"
}

const STAGGER_WINDOW_MS = 450
const STAGGER_STEP_Y = 20.0

static var _cell_stamps = {}
static var _tex_cache = {}

static func _next_stagger_offset(grid_pos):
	var now_ms = Time.get_ticks_msec()
	var key = str(grid_pos.x) + "," + str(grid_pos.y)
	var slot = 0
	if _cell_stamps.has(key):
		var entry = _cell_stamps[key]
		if now_ms - int(entry.time_ms) <= STAGGER_WINDOW_MS:
			slot = (int(entry.count) + 1) % 4
	_cell_stamps[key] = { time_ms = now_ms, count = slot }
	var x_jit = 0.0
	if slot == 1:
		x_jit = -10.0
	elif slot == 2:
		x_jit = 10.0
	return Vector2(x_jit, -float(slot) * STAGGER_STEP_Y)

static func _load_tex(path):
	if path == "" or OD.Load == null:
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex = OD.Load.image(path) if OD.Load.exists(path) else null
	_tex_cache[path] = tex
	return tex

static func spawn_text(host_node, layer_node, grid_pos, text, color, scale_mult = 1.0):
	if host_node == null or layer_node == null:
		return
	var label = Label.new()
	label.text = str(text)
	var px = OD.Math.grid_to_pixel(grid_pos.x, grid_pos.y)
	var stagger = _next_stagger_offset(grid_pos)
	label.position = px + Vector2(-80, -34) + stagger
	label.custom_minimum_size = Vector2(160, 24)
	label.pivot_offset = Vector2(80, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	if dialog_assets != null and dialog_assets.font != null:
		label.add_theme_font_override("font", dialog_assets.font)
	label.add_theme_font_size_override("font_size", int(round(18.0 * scale_mult)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	label.scale = Vector2(1.18, 1.18)
	layer_node.add_child(label)

	var tween = host_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14)
	tween.tween_property(label, "position:y", label.position.y - 26.0, 0.85)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.15)
	tween.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

static func spawn_badge(host_node, layer_node, grid_pos, badge_key):
	if host_node == null or layer_node == null:
		return false
	var path = BADGE_PATHS.get(str(badge_key), "")
	var tex = _load_tex(path)
	if tex == null:
		return false
	var tex_size = tex.get_size()
	var rect = TextureRect.new()
	rect.texture = tex
	rect.size = tex_size
	rect.pivot_offset = tex_size * 0.5
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var px = OD.Math.grid_to_pixel(grid_pos.x, grid_pos.y)
	var stagger = _next_stagger_offset(grid_pos)
	rect.position = px + Vector2(-tex_size.x * 0.5, -tex_size.y - 10.0) + stagger
	rect.scale = Vector2(1.22, 1.22)
	layer_node.add_child(rect)

	var tween = host_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(rect, "scale", Vector2.ONE, 0.14)
	tween.tween_property(rect, "position:y", rect.position.y - 22.0, 0.85)
	tween.tween_property(rect, "modulate:a", 0.0, 0.85).set_delay(0.18)
	tween.chain().tween_callback(func():
		if is_instance_valid(rect):
			rect.queue_free()
	)
	return true
