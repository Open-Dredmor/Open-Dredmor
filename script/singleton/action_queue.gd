extends Node

var _actions = []

func add(action):
	_actions.append(action)

func clear():
	_actions = []

func update():
	for ii in _actions.size():
		var action = _actions[ii]
		action.update()
		if action.is_complete():
			_actions.remove(ii)
