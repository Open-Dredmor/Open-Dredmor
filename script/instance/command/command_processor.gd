extends RefCounted

class_name CommandProcessor

signal command_executed(command, result)

const MAX_HISTORY = 128

var history = []

func submit(command, context):
	if command == null:
		return { executed = false, consumes_turn = false, message = "" }
	if not command.can_execute(context):
		return { executed = false, consumes_turn = false, message = "" }
	var result = command.execute(context)
	if result.get("executed", false):
		history.append(command.to_dict())
		if history.size() > MAX_HISTORY:
			history.remove_at(0)
		command_executed.emit(command, result)
	return result

func clear_history():
	history.clear()
