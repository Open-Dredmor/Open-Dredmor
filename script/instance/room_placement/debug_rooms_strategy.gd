extends Node

static func generate(_branch_name, _floor_level):
	ODMath.fixed_chances(true)
	var entity_grid = EntityGrid.new()
	entity_grid.init()
	entity_grid.resize(1,1)	
	
	# Useful development rooms
	var debug_room_names = [			
		# First place every run begins
		"Starting Room",
		# Water
		"Batty Cave", 
		# Lava
		"20x20 Large Treasury", 
		# Custom blockers have a vertical gap (like the starting room iron bars)
		"Indulgent Tomb 1" ,
		# Horizontal custom blockers
		"Stone Coffins 2"
	]
	
	var column_count = int(ceil(sqrt(debug_room_names.size())))
	var row_count = column_count
	var definition_index = 0
	var buffer_width = 30
	var buffer_height = 30
	#print("Placing " + str(room_definitions.size()) + " rooms with col/row "+str(column_count))
	for room_name in debug_room_names:
		var room_x = definition_index % column_count
		var room_y = floor(definition_index / row_count)
		#print("Adding room " + room_definition.name + ", " + str(room_x) + " x, " + str(room_y) + " y")
		var room = Room.new()
		room.init(room_name)
		room.position = Vector2(room_x * buffer_width, room_y * buffer_height)
		entity_grid.insert(room.entity_grid, room.position)
		var debug_button = room.get_debug_button()
		debug_button.rect_position = entity_grid.get_pixel_position(room.position.x, room.position.y) + entity_grid.position - Vector2(32,32)
		#print("x: "+str(debug_button.rect_position.x) + ", y:" + str(debug_button.rect_position.y))
		entity_grid.add_child(debug_button)
		definition_index += 1
	return entity_grid
