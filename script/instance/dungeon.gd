extends Node2D

class_name Dungeon

var floors = []
# TODO Use ID instead of name
var _branch_name = "The Dungeon"
var _floor_level = 1
var _entity_grid

func init():	
	call_deferred("_build_ui")

func _input(ev):
	if ev is InputEventKey and ev.is_pressed():
		if ev.scancode == KEY_SPACE and not ev.echo:
			Scenes.goto(Scenes.GAME)
			

func _build_ui():
	var strategy = "debug_rooms"
	_entity_grid = load("res://script/instance/room_placement/" + strategy + "_strategy.gd").generate(_branch_name, _floor_level)
	add_child(_entity_grid)
		
