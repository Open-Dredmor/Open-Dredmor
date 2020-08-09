extends Node

class_name ODRect

var x1
var x2
var y1
var y2

func init(x, y, width, height):
	x1 = x
	y1 = y
	x2 = x + width
	y2 = y + height

func is_colliding(target):
	return x1 < target.x2 and x2 > target.x1 and y1 > target.y2 and y2 < target.y1 
