extends Node2D

class_name ODSpriteFrames

var kind = "sprite"

var _frames = []

func add(frame):
	_frames.append(frame)

func load_sprite(sprite, frame_index):	
	sprite.region_enabled = true
	sprite.region_rect = _frames[frame_index].sprite.region_rect
	sprite.texture = _frames[frame_index].sprite.texture
	return _frames[frame_index]

func size():
	return _frames.size()
