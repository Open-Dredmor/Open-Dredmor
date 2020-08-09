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
	# TODO Prevent overlapping room placement
	while first_room.has_available_doors():
		circuit_breaker -= 1
		if circuit_breaker <= 0:
			break
		var source_door = first_room.get_door('up')
		var target_door_kind = 'down'
		if source_door == null:
			source_door = first_room.get_door('down')
			target_door_kind = 'up'
		if source_door == null:
			source_door = first_room.get_door('left')
			target_door_kind = 'right'
		if source_door == null:
			source_door = first_room.get_door('right')
			target_door_kind = 'left'
		var room_name = Database.random_room_id(_current_floor_level)
		var room = Room.new()
		room.init(room_name)
		if not room.has_available_doors():
			Log.warn("Could not find a path to room " + room_name)
			continue
		var target_door = room.get_door(target_door_kind)
		if target_door != null:
			var position_x = (source_door.x * Assets.CELL_PIXEL_WIDTH)
			var position_y = (source_door.y * Assets.CELL_PIXEL_HEIGHT)
			match target_door.kind:
				'up':
					position_y += Assets.CELL_PIXEL_HEIGHT * 2
					position_x -= target_door.x * Assets.CELL_PIXEL_WIDTH										
				'down':
					position_y -= Assets.CELL_PIXEL_HEIGHT
					position_y -= Assets.CELL_PIXEL_HEIGHT * room.grid_height
					position_x -= target_door.x * Assets.CELL_PIXEL_WIDTH
				'left':
					position_x += Assets.CELL_PIXEL_WIDTH * 2
					position_y -= target_door.y * Assets.CELL_PIXEL_HEIGHT
				'right':
					position_x -= Assets.CELL_PIXEL_WIDTH
					position_x -= Assets.CELL_PIXEL_WIDTH * room.grid_width
					position_y -= target_door.y * Assets.CELL_PIXEL_HEIGHT				
			room.position = Vector2(position_x, position_y)
			room.claim_door(target_door.x, target_door.y, target_door.kind)
			print("Link " + str(source_door.kind) +" at "+str(source_door.x)+","+str(source_door.y))
			print("To "+str(target_door.kind) + " at "+str(target_door.x)+","+str(target_door.y)+" in room "+room_name)
			first_room.claim_door(source_door.x, source_door.y, source_door.kind)
			
			rooms.append(room)
			add_child(room)
