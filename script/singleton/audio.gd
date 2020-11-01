extends Node

var _audio_player = null
var _current_stream = null
var _root = null
var _state = null

enum States {
	Playing,
	Stopped
}

func setup(root):	
	_root = root
	if OD.Settings.audio_enabled():
		if _audio_player != null:
			_audio_player.stop()
		if _audio_player != null:
			root.remove_child(_audio_player)
		_current_stream = null
		_audio_player = AudioStreamPlayer.new()
		root.add_child(_audio_player)
		_state = States.Stopped
	
func stop():
	_state = States.Stopped
	_audio_player.stop()	

func play(audio_stream):
	if _audio_player == null:
		setup(_root)
	if OD.Settings.audio_enabled():
		if audio_stream != _current_stream:
			_current_stream = audio_stream
			_audio_player.stream = audio_stream
			_audio_player.play()
		if _state != States.Playing:
			_audio_player.play()
			_state = States.Playing
