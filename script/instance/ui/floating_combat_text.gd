extends RefCounted

class_name FloatingCombatText

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

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
static var _texture_cache = {}

static func _next_stagger_offset(grid_position):
	var now_milliseconds = Time.get_ticks_msec()
	var key = str(grid_position.x) + "," + str(grid_position.y)
	var slot = 0
	if _cell_stamps.has(key):
		var entry = _cell_stamps[key]
		if now_milliseconds - int(entry.time_ms) <= STAGGER_WINDOW_MS:
			slot = (int(entry.count) + 1) % 4
	_cell_stamps[key] = { time_ms = now_milliseconds, count = slot }
	var horizontal_jitter = 0.0
	if slot == 1:
		horizontal_jitter = -10.0
	elif slot == 2:
		horizontal_jitter = 10.0
	return Vector2(horizontal_jitter, -float(slot) * STAGGER_STEP_Y)

static func spawn_text(host_node, layer_node, grid_position, text, color, scale_multiplier = 1.0):
	if host_node == null or layer_node == null:
		return
	var label = Label.new()
	label.text = str(text)
	var pixel_position = OD.Math.grid_to_pixel(grid_position.x, grid_position.y)
	var stagger = _next_stagger_offset(grid_position)
	label.position = pixel_position + Vector2(-80, -34) + stagger
	label.custom_minimum_size = Vector2(160, 24)
	label.pivot_offset = Vector2(80, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiHelpers.style_label(label, int(round(18.0 * scale_multiplier)), color, null, 3)
	label.scale = Vector2(1.18, 1.18)
	layer_node.add_child(label)

	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14)
	tween.tween_property(label, "position:y", label.position.y - 26.0, 0.85)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.15)
	tween.chain().tween_callback(label.queue_free)

static func spawn_badge(host_node, layer_node, grid_position, badge_key):
	if host_node == null or layer_node == null:
		return false
	var path = BADGE_PATHS.get(str(badge_key), "")
	var badge_texture = UiHelpers.load_texture(path, _texture_cache)
	if badge_texture == null:
		return false
	var texture_size = badge_texture.get_size()
	var badge_rect = TextureRect.new()
	badge_rect.texture = badge_texture
	badge_rect.size = texture_size
	badge_rect.pivot_offset = texture_size * 0.5
	badge_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	badge_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pixel_position = OD.Math.grid_to_pixel(grid_position.x, grid_position.y)
	var stagger = _next_stagger_offset(grid_position)
	badge_rect.position = pixel_position + Vector2(-texture_size.x * 0.5, -texture_size.y - 10.0) + stagger
	badge_rect.scale = Vector2(1.22, 1.22)
	layer_node.add_child(badge_rect)

	var tween = badge_rect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge_rect, "scale", Vector2.ONE, 0.14)
	tween.tween_property(badge_rect, "position:y", badge_rect.position.y - 22.0, 0.85)
	tween.tween_property(badge_rect, "modulate:a", 0.0, 0.85).set_delay(0.18)
	tween.chain().tween_callback(badge_rect.queue_free)
	return true
