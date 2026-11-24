extends "res://script/instance/entity/entity.gd"

class_name Door

var entity_kind = "element"
var orientation = "ew"
var is_open = false
var is_locked = false
var is_broken = false
var lock_difficulty = 1

var _animation = null

func init(door_orientation = "ew", locked = false):
	orientation = door_orientation
	is_locked = locked
	var sprite_path = "dungeon/doorns.spr" if orientation == "ns" else "dungeon/doorew.spr"
	_animation = OD.Load.animation(sprite_path)
	_animation.set_step_only(true)
	add_child(_animation)
	_sync_visual()

func _ready():
	_sync_visual()

func _sync_visual():
	if _animation != null:
		_animation.set_frame(1 if (is_open or is_broken) else 0)

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
