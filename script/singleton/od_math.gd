extends Node

var _succeed = null

func fixed_chances(succeed):
	_succeed = succeed

func chance(text_value):
	if _succeed != null:
		return _succeed
	if text_value == null:
		return true
	var float_value = float(text_value) / float(100)
	var percent = randf()
	return percent <= float_value
	
