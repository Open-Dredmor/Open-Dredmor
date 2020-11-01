# Godot might have a built in way to do this, and I would love to replace this with a native solution.
# However, after experimenting and researching the various sprite and animation classes I didn't find what Dredmor uses.
# Separate files per frame of an animation, with a varying time between frames.
# SpriteFrames almost did what I wanted, but the rate per frame was set for the whole animation, not per frame.

extends Node2D

signal animation_complete(animation_id)

var _frames = null
var _sprite = null
var _next_frame_timer = null
var _frame_index = 0
var _multi_cell_tall = false
var _step_only = false
var _animation_id = null

func _ready():
	play()

func init(step_only = false):
	_sprite = Sprite.new()
	add_child(_sprite)
	_step_only = step_only
	if not _step_only:
		_next_frame_timer = Timer.new()	
		add_child(_next_frame_timer)	
	
func set_animation_id(animation_id):
	_animation_id = animation_id

func add_sprite_frame(sprite, display_milliseconds):
	if _frames != null and _frames.kind != "sprite":
		print("Attempted to add a sprite to an animation that uses texture frames")
		OD.Scenes.quit()
	if _frames == null:
		_frames = ODSpriteFrames.new()
	_frames.add({
		sprite = sprite,
		display_seconds = float(display_milliseconds) / float(1000)
	})

func add_texture_frame(texture, display_milliseconds):
	if _frames != null and _frames.kind != "texture":
		print("Attempted to add a texture to an animation that uses sprite frames")
		OD.Scenes.quit()
	if _frames == null:
		_frames = ODTextureFrames.new()
	if texture.get_height() > OD.Assets.CELL_PIXEL_HEIGHT * 1.7: # TODO Why 1.7?
		_multi_cell_tall = true
	_frames.add({
		texture = texture,
		display_seconds = float(display_milliseconds) / float(1000)
	})

func stop():
	remove_child(_next_frame_timer)
	_next_frame_timer = null
	_frame_index = 0

func play():
	var current_frame = _frames.load_sprite(_sprite, _frame_index)		
	if not _step_only and current_frame.display_seconds > 0:
		# TODO Something is wrong here. Getting the following error on tile click
		# E 0:00:32.266   connect: Signal 'timeout' is already connected to given method '_on_NextFrameTimer_timeout' in that object.
		# E 0:00:32.924   start: Timer was not added to the SceneTree. Either add it or set autostart to true.
		if _next_frame_timer == null:
			_next_frame_timer = Timer.new()	
			add_child(_next_frame_timer)	
		_next_frame_timer.set_wait_time(current_frame.display_seconds)
		_next_frame_timer.connect("timeout", self, "_on_NextFrameTimer_timeout")
		_next_frame_timer.start()

func next_frame():
	_on_NextFrameTimer_timeout()

# TODO Disconnect and reconnect seems wasteful	
func _on_NextFrameTimer_timeout():
	_frame_index = (_frame_index + 1) % _frames.size()
	if _frame_index == 0 and _animation_id != null:
		emit_signal("animation_complete", _animation_id)
	if not _step_only and _next_frame_timer != null:
		_next_frame_timer.disconnect("timeout", self, "_on_NextFrameTimer_timeout")
	play()

func is_tall():
	return _multi_cell_tall

func set_step_only(step_only):
	_step_only = step_only
	if _next_frame_timer != null:
		remove_child(_next_frame_timer)
		_next_frame_timer = null
