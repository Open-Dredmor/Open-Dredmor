extends "res://script/instance/entity/entity.gd"

class_name Door

var entity_kind = "element"
var orientation = "ew"
var door_style = "1x1"
var is_open = false
var is_locked = false
var is_broken = false
var lock_difficulty = 1

var _animation = null
var _secondary_animation = null
var _aux_node = null

func init(door_orientation = "ew", locked = false, style = "1x1"):
	orientation = door_orientation
	is_locked = locked
	door_style = style
	if door_style == "3x3":
		_init_3x3()
	else:
		var sprite_path = "dungeon/doorns.spr" if orientation == "ns" else "dungeon/doorew.spr"
		_animation = OD.Load.animation(sprite_path)
		_animation.set_step_only(true)
		if _animation.is_tall():
			_animation.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
		add_child(_animation)
	_sync_visual()

func _init_3x3():
	if orientation == "ew":
		_animation = OD.Load.animation("dungeon/door_wood3x3_ns_left.spr")
		_animation.set_step_only(true)
		_animation.position = Vector2(-24.0, -32.0)
		add_child(_animation)
		_secondary_animation = OD.Load.animation("dungeon/door_wood3x3_ns_right.spr")
		_secondary_animation.set_step_only(true)
		_secondary_animation.position = Vector2(24.0, -32.0)
		add_child(_secondary_animation)
	else:
		_animation = OD.Load.animation("dungeon/door_wood3x3_ew_top.spr")
		_animation.set_step_only(true)
		_animation.position = Vector2(0.0, 32.0)
		add_child(_animation)
		_aux_node = Node2D.new()
		_secondary_animation = OD.Load.animation("dungeon/door_wood3x3_ew_bottom.spr")
		_secondary_animation.set_step_only(true)
		_secondary_animation.position = Vector2(0.0, -32.0)
		_aux_node.add_child(_secondary_animation)

func get_aux_node():
	return _aux_node

func _ready():
	_sync_visual()

func _sync_visual():
	if door_style == "3x3":
		if orientation == "ew":
			var frame_idx = 1 if (is_open or is_broken) else 0
			if _animation != null:
				_animation.set_frame(frame_idx)
			if _secondary_animation != null:
				_secondary_animation.set_frame(frame_idx)
		else:
			var frame_idx = 1 if (is_open or is_broken) else 0
			if _animation != null:
				_animation.position = Vector2(0.0, 0.0 if frame_idx != 0 else 32.0)
				_animation.set_frame(frame_idx)
			if _secondary_animation != null:
				_secondary_animation.set_frame(frame_idx)
		return
	if _animation != null:
		_animation.set_frame(0 if (is_open or is_broken) else 1)

func can_pass():
	return is_open or is_broken

func open():
	if is_open or is_broken:
		return true
	if is_locked:
		OD.Audio.play_sfx("locked")
		return false
	is_open = true
	_sync_visual()
	OD.Audio.play_sfx("door_open")
	return true

func close():
	if not is_open or is_broken:
		return false
	is_open = false
	_sync_visual()
	OD.Audio.play_sfx("door_close")
	return true

func toggle():
	if is_open:
		return close()
	return open()

func unlock_with_lockpick(skill_bonus = 0):
	if not is_locked:
		return true
	if skill_bonus + (randi() % 4) >= lock_difficulty:
		is_locked = false
		OD.Audio.play_sfx("click")
		return open()
	OD.Audio.play_sfx("locked")
	return false

func kick(_strength_bonus = 0):
	if is_open or is_broken:
		return true
	is_locked = false
	is_open = true
	is_broken = true
	_sync_visual()
	OD.Audio.play_sfx("breakable")
	return true

func interact():
	if is_locked:
		return unlock_with_lockpick()
	return toggle()
