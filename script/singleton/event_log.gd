extends Node

signal message_logged(message)

const MAX_HISTORY = 50
var _history = []

func notify(message):
	var text = str(message)
	if text == "":
		return
	_history.append(text)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	message_logged.emit(text)

func get_history():
	return _history.duplicate()

func clear_history():
	_history.clear()
