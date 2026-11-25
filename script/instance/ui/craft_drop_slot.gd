extends Button

var _on_drop_callback = null

func setup_slot(on_drop_callback):
	_on_drop_callback = on_drop_callback

func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("craft_item_name")

func _drop_data(_at_position, data):
	if _on_drop_callback != null and _on_drop_callback.is_valid():
		_on_drop_callback.call(str(data.craft_item_name))
