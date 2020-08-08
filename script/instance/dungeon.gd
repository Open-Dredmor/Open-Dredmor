extends Node2D

class_name Dungeon

var floors = []
var current_floor = 0
# TODO Use ID instead of name
var current_branch = "The Dungeon"
var tilesets = null

var _entity_grid

func init(entity_grid):	
	_entity_grid = entity_grid
	call_deferred("_build_ui")

func _input(ev):
	if ev is InputEventKey and ev.is_pressed() and ev.scancode == KEY_SPACE and not ev.echo:
		Scenes.goto(Scenes.GAME)

func _build_ui():	
	# Useful development rooms
	# Starting Room - First place every run begins
	# Batty Cave - Water
	# 20x20 Large Treasury - Lava
	var room = Room.new()
	room.init("20x20 Large Treasury", _entity_grid)	
	add_child(room)
