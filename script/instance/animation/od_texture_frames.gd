extends Node2D

class_name ODTextureFrames

var kind = "texture"

var _frames = []

func add(frame):
	_frames.append(frame)

func load_sprite(sprite, frame_index):
	sprite.texture = _frames[frame_index].texture
	return _frames[frame_index]

func size():
	return _frames.size()
