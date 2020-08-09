extends Node

var warnings = {}

func warn(message):
	if not warnings.has(message):
		warnings[message] = true
		print(message)
