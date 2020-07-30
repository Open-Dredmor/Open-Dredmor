# Godot might have a built in way to do this, and I would love to replace this with a native solution.
# However, after experimenting and researching the various sprite and animation classes I didn't find what Dredmor uses.
# Separate files per frame of an animation, with a varying time between frames.
# SpriteFrames almost did what I wanted, but the rate per frame was set for the whole animation, not per frame.

extends Node2D

class_name ODAnimation

var _sprite_frames = null
var _texture_frames = null
var _sprite = null
var _next_frame_timer = null
var _frame_index = 0
var _enable_sprite_frames = false

func _ready():
	add_child(_next_frame_timer)
	add_child(_sprite)

func init():
	_sprite_frames = []
	_texture_frames = []
	_sprite = Sprite.new()
	_next_frame_timer = Timer.new()

func add_sprite_frame(sprite, display_milliseconds):
	_enable_sprite_frames = true
	_sprite_frames.append({
		sprite = sprite,
		display_seconds = float(display_milliseconds) / float(1000)
	})

func add_texture_frame(texture, display_milliseconds):
	_texture_frames.append({
		texture = texture,
		display_seconds = float(display_milliseconds) / float(1000)
	})

func play():
	if ! _enable_sprite_frames:
		var current_frame = _texture_frames[_frame_index]
		_sprite.texture = current_frame.texture
		_next_frame_timer.set_wait_time(current_frame.display_seconds)
		_next_frame_timer.connect("timeout", self, "_on_NextFrameTimer_timeout")
		_next_frame_timer.start()
	else:
		var current_frame = _sprite_frames[_frame_index]
		_sprite.region_enabled = true
		_sprite.region_rect = current_frame.sprite.region_rect
		_sprite.texture = current_frame.sprite.texture		
		_next_frame_timer.set_wait_time(current_frame.display_seconds)
		_next_frame_timer.connect("timeout", self, "_on_NextFrameTimer_timeout")
		_next_frame_timer.start()
	
# Disconnect and reconnect seems wasteful	
func _on_NextFrameTimer_timeout():
	if _enable_sprite_frames:
		_frame_index = (_frame_index + 1) % _sprite_frames.size()
	else:
		_frame_index = (_frame_index + 1) % _texture_frames.size()
	_next_frame_timer.disconnect("timeout", self, "_on_NextFrameTimer_timeout")
	play()

