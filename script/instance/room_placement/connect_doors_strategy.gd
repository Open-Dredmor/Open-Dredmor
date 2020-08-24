extends Node

static func generate(_branch_name, floor_level):	
	var entity_grid = EntityGrid.new()
	var rooms = []
	var first_room_name = "Starting Room"
	var first_room = Room.new()
	first_room.init(first_room_name)
	first_room.collision_rect.init(0, 0, first_room.grid_width, first_room.grid_height)
	rooms.append(first_room)
	
	var circuit_breaker = 800
	var rooms_count = 15
	while rooms_count > 0:
		circuit_breaker -= 1
		if circuit_breaker <= 0:
			break
		var source_index = 0
		var source_room = rooms[source_index]
		while not source_room.has_available_doors():
			source_index += 1
			source_room = rooms[source_index]
		var source_door = source_room.get_door('up')
		var target_door_kind = 'down'
		if source_door == null:
			source_door = source_room.get_door('down')
			target_door_kind = 'up'
		if source_door == null:
			source_door = source_room.get_door('left')
			target_door_kind = 'right'
		if source_door == null:
			source_door = source_room.get_door('right')
			target_door_kind = 'left'
		var room_name = Database.random_room_id(floor_level)
		var room = Room.new()
		room.init(room_name)
		if not room.has_available_doors():
			Log.warn("Could not find a path to room " + room_name)
			continue
		var target_door = room.get_door(target_door_kind)
		if target_door != null:
			# Need to factor in source_room position after moving out of the starting room
			var position_x = source_door.x
			var position_y = source_door.y
			match target_door.kind:
				'up':
					position_y += 2
					position_x -= target_door.x
				'down':
					position_y -= room.grid_height
					position_x -= target_door.x
				'left':
					position_x += 2
					position_y -= target_door.y
				'right':
					position_x -= room.grid_width
					position_y -= target_door.y
			room.position = Vector2(source_room.position.x + position_x, source_room.position.y + position_y)
			room.collision_rect.init(room.position.x, room.position.y, room.grid_width, room.grid_height)
			
			# This is a naive implementation
			# It would be much faster to only grab rooms that would fit in the first place
			var collision = false
			for existing_room in rooms:
				if room.collision_rect.is_colliding(existing_room.collision_rect):
					Log.warn("Overlapping rooms")
					collision = true
					break
			if not collision:
				room.claim_door(target_door.x, target_door.y, target_door.kind)
	#			print("Link " + str(source_door.kind) +" at "+str(source_door.x)+","+str(source_door.y))
	#			print("To "+str(target_door.kind) + " at "+str(target_door.x)+","+str(target_door.y)+" in room "+room_name)
				source_room.claim_door(source_door.x, source_door.y, source_door.kind)			
				rooms.append(room)
				rooms_count -= 1
			
	entity_grid.init()
	entity_grid.resize(1,1)
	for room in rooms:
		room.seal_available_doors()
		entity_grid.insert(room.entity_grid, room.position)
		var debug_button = room.get_debug_button()
		debug_button.rect_position = entity_grid.get_pixel_position(room.position.x, room.position.y) + entity_grid.position - Vector2(32,32)
		#print("x: "+str(debug_button.rect_position.x) + ", y:" + str(debug_button.rect_position.y))
		entity_grid.add_child(debug_button)
	return entity_grid
