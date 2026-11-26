extends Node

const SFX_POOL_SIZE = 12

var _audio_player = null
var _current_stream = null
var _next_loop_stream = null
var _root = null
var _state = null
var _sfx_players = []
var _sfx_next_index = 0

enum States {
	Playing,
	Stopped
}

func _resolve_bus(bus_name):
	if AudioServer.get_bus_index(bus_name) != -1:
		return bus_name
	return &"Master"

func _apply_bus_volume(bus_name, percent):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped = clamp(int(percent), 0, 100)
	AudioServer.set_bus_mute(bus_index, clamped <= 0)
	if clamped > 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(float(clamped) / 100.0))

func apply_volume_settings():
	_apply_bus_volume(&"Master", OD.Settings.master_volume_percent())
	_apply_bus_volume(&"Music", OD.Settings.music_volume_percent())
	_apply_bus_volume(&"Sound", OD.Settings.sfx_volume_percent())
	_apply_bus_volume(&"Dialogue", OD.Settings.dialogue_volume_percent())

func apply_preview_volumes(master_percent, music_percent, sfx_percent, dialogue_percent):
	_apply_bus_volume(&"Master", master_percent)
	_apply_bus_volume(&"Music", music_percent)
	_apply_bus_volume(&"Sound", sfx_percent)
	_apply_bus_volume(&"Dialogue", dialogue_percent)

func _clear_sfx_pool():
	for player in _sfx_players:
		if is_instance_valid(player):
			player.stop()
			if player.get_parent() != null:
				player.get_parent().remove_child(player)
			player.queue_free()
	_sfx_players.clear()
	_sfx_next_index = 0

func _setup_sfx_pool(target_parent):
	_clear_sfx_pool()
	var sfx_bus = _resolve_bus(&"Sound")
	for ii in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = sfx_bus
		target_parent.add_child(player)
		_sfx_players.append(player)

func setup(root):	
	_root = root
	var target_parent = root if root != null else self
	if OD.Settings.audio_enabled():
		if _audio_player != null:
			_audio_player.stop()
			if _audio_player.get_parent() != null:
				_audio_player.get_parent().remove_child(_audio_player)
			_audio_player.queue_free()
		_current_stream = null
		_next_loop_stream = null
		_audio_player = AudioStreamPlayer.new()
		_audio_player.bus = _resolve_bus(&"Music")
		_audio_player.finished.connect(_on_music_finished)
		target_parent.add_child(_audio_player)
		_setup_sfx_pool(target_parent)
		apply_volume_settings()
		_state = States.Stopped
	
func stop():
	_state = States.Stopped
	_next_loop_stream = null
	if _audio_player != null:
		_audio_player.stop()
	for player in _sfx_players:
		if is_instance_valid(player):
			player.stop()

func _on_music_finished():
	if _state != States.Playing or _next_loop_stream == null or _audio_player == null:
		return
	var loop_stream = _next_loop_stream
	_next_loop_stream = null
	_current_stream = loop_stream
	_audio_player.stream = loop_stream
	_audio_player.play()

func play(audio_stream, loop_stream = null):
	if _audio_player == null:
		setup(_root)
	if OD.Settings.audio_enabled():
		_next_loop_stream = loop_stream
		if audio_stream != _current_stream:
			_current_stream = audio_stream
			_audio_player.stream = audio_stream
			_audio_player.play()
		if _state != States.Playing:
			_audio_player.play()
			_state = States.Playing

func _acquire_sfx_player():
	for player in _sfx_players:
		if is_instance_valid(player) and not player.playing:
			return player
	if _sfx_players.is_empty():
		return null
	var player = _sfx_players[_sfx_next_index]
	_sfx_next_index = (_sfx_next_index + 1) % _sfx_players.size()
	if is_instance_valid(player):
		player.stop()
		return player
	return null

func play_sfx(cue_name):
	if not OD.Settings.audio_enabled():
		return false
	if _sfx_players.is_empty():
		setup(_root if _root != null else self)
	if _sfx_players.is_empty():
		return false
	var sfx_volume = OD.Settings.sfx_volume_percent()
	if sfx_volume <= 0:
		return false
	var wave_path = OD.Database.get_sound_path(cue_name)
	if wave_path == null:
		push_warning("Unknown SFX cue: " + str(cue_name))
		return false
	var stream = OD.Load.sfx(wave_path)
	if stream == null:
		return false
	var player = _acquire_sfx_player()
	if player == null:
		return false
	apply_volume_settings()
	if AudioServer.get_bus_index(&"Sound") == -1:
		player.volume_db = linear_to_db(float(sfx_volume) / 100.0)
	else:
		player.volume_db = 0.0
	player.stream = stream
	player.play()
	return true
