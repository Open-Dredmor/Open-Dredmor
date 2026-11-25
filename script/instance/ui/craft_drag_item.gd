extends Button

const DRAG_PREVIEW_SIZE = Vector2(40, 40)

var _item_name = ""
var _drag_tex = null

func setup_drag(item_name, drag_tex):
	_item_name = str(item_name)
	_drag_tex = drag_tex

func _get_drag_data(_at_position):
	if _item_name == "":
		return null
	if _drag_tex != null:
		var preview = TextureRect.new()
		preview.texture = _drag_tex
		preview.custom_minimum_size = DRAG_PREVIEW_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_drag_preview(preview)
	return { craft_item_name = _item_name }
