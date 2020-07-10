extends Node

var _audio_player = null
var _current_stream = null

func setup(root):
	_audio_player = AudioStreamPlayer.new()
	root.add_child(_audio_player)
	
func play(audio_stream):
	if audio_stream != _current_stream:
		_current_stream = audio_stream
		_audio_player.stream = audio_stream
		_audio_player.play()
