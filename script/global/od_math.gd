extends Node

func chance(text_value):
	if text_value == null:
		return true
	var float_value = float(text_value) / float(100)
	var percent = randf()
	return percent <= float_value
	
