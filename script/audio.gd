extends Node

var _audio_player = null

func play(audio_stream):
	if _audio_player == null:
		_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = audio_stream
	_audio_player.play()
