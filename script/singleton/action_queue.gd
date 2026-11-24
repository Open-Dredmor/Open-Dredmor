extends Node

var _actions = []

func add(action):
	_actions.append(action)

func clear():
	_actions = []

func has_pending():
	return not _actions.is_empty()

func step_once():
	if _actions.is_empty():
		return false
	var stepped = false
	var ii = 0
	while ii < _actions.size():
		var action = _actions[ii]
		action.update()
		stepped = true
		if ii >= _actions.size() or _actions[ii] != action:
			continue
		if action.is_complete():
			_actions.remove_at(ii)
		else:
			ii += 1
	return stepped
