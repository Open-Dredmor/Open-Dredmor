extends Node

var _actions = []
var _update_timer = Timer.new()

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	add_child(_update_timer)	
	_update_timer.set_wait_time(OD.DungeonSettings.get_settings().seconds_per_action)
	_update_timer.connect("timeout", self, "_on_UpdateTimer_timeout")
	_update_timer.start()

func _on_UpdateTimer_timeout():
	var ii = 0
	while ii < _actions.size():		
		var action = _actions[ii]
		action.update()
		if action.is_complete():
			_actions.remove(ii)
		else:
			ii += 1

func add(action):
	_actions.append(action)

func clear():
	_actions = []
