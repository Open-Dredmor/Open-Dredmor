extends "res://script/instance/entity/entity.gd"

class_name ShopPedestal

var entity_kind = "pedestal"
var shop_id = ""
var item_data = null
var is_paid = false
var is_taken = false

var _base_sprite = null
var _item_sprite = null

func init(pedestal_shop_id, rolled_item = null):
	shop_id = pedestal_shop_id
	_base_sprite = OD.Load.animation(OD.Resources.paths.shop_pedestal)
	if _base_sprite != null:
		add_child(_base_sprite)
	set_item(rolled_item)

func set_item(rolled_item):
	item_data = rolled_item
	if _item_sprite != null and is_instance_valid(_item_sprite):
		_item_sprite.queue_free()
		_item_sprite = null
	if item_data == null:
		return
	var icon_path = item_data.get("icon", "")
	if icon_path != "" and OD.Load.exists(icon_path):
		_item_sprite = Sprite2D.new()
		_item_sprite.texture = OD.Load.image(icon_path)
		_item_sprite.position = Vector2(0, -10)
		_item_sprite.scale = Vector2(0.8, 0.8)
		add_child(_item_sprite)

func has_item():
	return item_data != null and not is_taken

func clear_item(paid):
	is_paid = paid
	is_taken = true
	item_data = null
	if _item_sprite != null and is_instance_valid(_item_sprite):
		_item_sprite.queue_free()
		_item_sprite = null
