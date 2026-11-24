extends RefCounted

class_name GameCommand

var command_type = "base"
var actor = null

func can_execute(_context):
	return true

func execute(_context):
	return {
		executed = false,
		consumes_turn = false,
		message = ""
	}

func to_dict():
	return {
		command_type = command_type
	}
