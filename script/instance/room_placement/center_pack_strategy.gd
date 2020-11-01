extends Node

# What if you divide grid into max/max pieces (30,30) plus a buffer.
# Then place 1 room per subdivision. Then join doors.

static func generate(_branch_name, floor_level):	
	var entity_grid = EntityGrid.new()
	var rooms = []
	var first_room_name = "Starting Room"
	var first_room = Room.new()
	first_room.init(first_room_name)
	first_room.collision_rect.init(0, 0, first_room.grid_width, first_room.grid_height)
	rooms.append(first_room)
	var rooms_per_floor = 16
	var rows = floor(rooms_per_floor/2)
	var cols = floor(rooms_per_floor/2)
	var start_coord = Vector2(floor(rows/2),floor(cols/2))
	
	var room_grid = []
	
	for ii in rows:
		room_grid.append([])
		for jj in cols:
			var room_name = null
			if ii == start_coord.x and jj == start_coord.y:
				room_name = "Starting Room"
			else:
				room_name = OD.Database.random_room_id(floor_level)
			var room = Room.new()
			room.init(room_name)
			room_grid[ii].append(room)
	for ii in rows:		
		for jj in cols:
			var possible_doors = room_grid[ii][jj].possible_doors()
			if possible_doors.size() == 0:
				room_grid[ii][jj] = null
				continue
			var available_doors = []
			for possible in possible_doors:
				match possible:
					'up':
						if ii > 0:
							var adjacent_room = room_grid[ii-1][jj]
							
					'down':
						if ii < rows:
							pass
					'left':
						if jj > 0:
							pass
					'right':
						if jj < cols:
							pass
			if available_doors.size() == 0:
				room_grid[ii][jj] = null
				continue
			
		
	var circuit_breaker = 20
	while true:
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
		
		
#		var position_x = source_door.x
#		var position_y = source_door.y
#		match target_door_kind:
#			'up':
#				position_y += 2
#				position_x -= target_door.x
#			'down':
#				position_y -= room.grid_height
#				position_x -= target_door.x
#			'left':
#				position_x += 2
#				position_y -= target_door.y
#			'right':
#				position_x -= room.grid_width
#				position_y -= target_door.y
#
#		var room_name = OD.Database.get_room_within(floor_level, 15, 15)
#		var room = Room.new()
#		room.init(room_name)
#		room.position = Vector2(source_room.position.x + position_x, source_room.position.y + position_y)
#		room.collision_rect.init(room.position.x, room.position.y, room.grid_width, room.grid_height)
#
#		var collision = false
##			for existing_room in rooms:
##				if room.collision_rect.is_colliding(existing_room.collision_rect):
##					OD.Log.warn("Overlapping rooms")
##					collision = true
##					break
#		if not collision:
#			room.claim_door(target_door.x, target_door.y, target_door.kind)
##			print("Link " + str(source_door.kind) +" at "+str(source_door.x)+","+str(source_door.y))
##			print("To "+str(target_door.kind) + " at "+str(target_door.x)+","+str(target_door.y)+" in room "+room_name)
#			source_room.claim_door(source_door.x, source_door.y, source_door.kind)			
#			rooms.append(room)
#
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
