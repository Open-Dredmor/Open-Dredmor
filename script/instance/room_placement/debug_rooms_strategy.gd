extends Node

static func generate(_branch_name, _floor_level):
	OD.Math.fixed_chances(true)
	var entity_grid = EntityGrid.new()
	entity_grid.init()
	entity_grid.resize(1,1)	
	
	# Useful development rooms
	var debug_room_names = [					
		"Starting Room", # First place every run begins		
		"Batty Cave", # Water		
		"20x20 Large Treasury", # Lava, zorkmids, artifact, hordes		
		"Indulgent Tomb 1", # Custom blockers have a vertical gap (like the starting room iron bars)		
		"Stone Coffins 2", # Horizontal custom blockers		
		"Rogue Tricks 1", # misc loot and traps		
		"Ignition Hall 1", # brazier script		
		"Smithery", # loot types		
		"Small Alchemy Lab", # reagent without subtype		
		"Small Workshop", # component without subtype
		"Magic Buffing Chamber", # custom breakable, pedestal
		"Traps for Treasure", # lots of traps and random monsters
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
		room.collision_rect.init(room_x, room_y, room.grid_width, room.grid_height)
		entity_grid.insert(room.entity_grid, room.position)
		var debug_button = room.get_debug_button()
		debug_button.rect_position = OD.Math.grid_to_pixel(room.position.x, room.position.y) + entity_grid.position - Vector2(32,32)
		#print("x: "+str(debug_button.rect_position.x) + ", y:" + str(debug_button.rect_position.y))
		entity_grid.add_child(debug_button)
		definition_index += 1
	return entity_grid
