# Godot might have a built in way to do this, and I would love to replace this with a native solution.
# However, after experimenting and researching the various sprite and animation classes I didn't find what Dredmor uses.
# Separate files per frame of an animation, with a varying time between frames.
# SpriteFrames almost did what I wanted, but the rate per frame was set for the whole animation, not per frame.

extends Node2D

class_name ODAnimation

var _frames = null
var _sprite = null
var _next_frame_timer = null
var _frame_index = 0

func _ready():
	_frames = []
	_sprite = Sprite.new()
	_next_frame_timer = Timer.new()
	add_child(_next_frame_timer)
	add_child(_sprite)
	

func add_frame(texture, display_milliseconds):
	_frames.append({
		texture = texture,
		display_seconds = float(display_milliseconds) / float(1000)
	})

func play():
	if _frames.size() == 0:
		return
	var current_frame = _frames[_frame_index]
	_sprite.set_texture(current_frame.texture)
	_next_frame_timer.set_wait_time(current_frame.display_seconds)
	_next_frame_timer.connect("timeout", self, "_on_NextFrameTimer_timeout")
	_next_frame_timer.start()
	
# Disconnect and reconnect seems wasteful	
func _on_NextFrameTimer_timeout():
	_frame_index = (_frame_index + 1) % _frames.size()
	_next_frame_timer.disconnect("timeout", self, "_on_NextFrameTimer_timeout")
	play()

