extends Node

const FEATURED_NORTH_ROOM = "Traps for Treasure"

static func generate(_branch_name, _floor_level):
	OD.Math.fixed_chances(true)
	var branch_id = max(0, _floor_level - 1)
	if OD.Database.get_branch_info(branch_id) == null:
		branch_id = 0
	var entity_grid = EntityGrid.new()
	entity_grid.init(branch_id)
	entity_grid.floor_level = _floor_level
	entity_grid.branch_id = branch_id
	entity_grid.resize(1,1)	
	
	# Useful development rooms
	var debug_room_names = [					
		"Starting Room", # First place every run begins		
		"9x10 shop (S)", # Brax shop with pedestals and s teleport
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
		debug_button.position = OD.Math.grid_to_pixel(room.position.x, room.position.y) + entity_grid.position - Vector2(32,32)
		#print("x: "+str(debug_button.rect_position.x) + ", y:" + str(debug_button.rect_position.y))
		entity_grid.add_child(debug_button)
		room.free()
		definition_index += 1
	if FEATURED_NORTH_ROOM != "":
		var north_room = Room.new()
		north_room.init(FEATURED_NORTH_ROOM)
		north_room.position = Vector2(0, -north_room.grid_height)
		north_room.collision_rect.init(0, -north_room.grid_height, north_room.grid_width, north_room.grid_height)
		entity_grid.insert(north_room.entity_grid, north_room.position)
		var north_debug_button = north_room.get_debug_button()
		north_debug_button.position = OD.Math.grid_to_pixel(north_room.position.x, north_room.position.y) + entity_grid.position - Vector2(32, 32)
		entity_grid.add_child(north_debug_button)
		north_room.free()
	if _floor_level > 1:
		entity_grid.add_stairs(4, 6, "up")
	entity_grid.add_stairs(4, 8, "down")
	entity_grid.auto_tile_walls()
	return entity_grid
