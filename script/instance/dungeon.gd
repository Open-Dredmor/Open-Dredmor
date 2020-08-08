extends Node2D

class_name Dungeon

var floors = []
# TODO Use ID instead of name
var current_branch = "The Dungeon"
var tilesets = null
var _current_floor_level = 1
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
	var rooms = []
	var first_room_name = "Starting Room"
	var first_room = Room.new()
	first_room.init(first_room_name)
	add_child(first_room)
	var circuit_breaker = 20
	while first_room.has_available_doors():
		circuit_breaker -= 1
		if circuit_breaker <= 0:
			break
		var source_door = first_room.get_up_down_door()
		if source_door == null:
			source_door = first_room.get_left_right_door()
		var room_name = Database.random_room_id(_current_floor_level)
		var room = Room.new()
		room.init(room_name)
		if not room.has_available_doors():
			Log.warn("Could not find a path to room " + room_name)
			continue
		var target_door = null
		if source_door.kind == 'left_right':
			target_door = room.get_left_right_door()
		else:
			target_door = room.get_up_down_door()		
		if target_door != null:
			room.position = Vector2((target_door.x - source_door.x) * Assets.CELL_PIXEL_WIDTH, (target_door.y - source_door.y) * Assets.CELL_PIXEL_HEIGHT)
			room.claim_door(target_door.x, target_door.y, target_door.kind)
			first_room.claim_door(source_door.x, source_door.y, source_door.kind)
			rooms.append(room)
			add_child(room)
