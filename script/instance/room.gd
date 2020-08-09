extends Node2D

class_name Room

var grid_width
var grid_height
var layer_lookup = {}
var layer_names = [
	"customblocker",
	"customengraving",
	"element",
	"loot",
	"monster",
	"horde"
]

var _entity_grid
var _definition
var _doors = {
	left = [],
	right = [],
	up = [],
	down = []
}

var tilesets

func init(room_database_name):	
	_entity_grid = EntityGrid.new()
	_entity_grid.init()
	add_child(_entity_grid)
	_definition = Database.get_room(room_database_name)
	# Rough passage 3 in game/rooms.xml has a width/height that doesn't match the data
	# Count the strings lengths instead of trusting the reported values
	grid_width = _definition.row[0].text.length()
	grid_height = _definition.row.size()
	var name_details = Database.create_room_name()
	print("Generating room id " + room_database_name + " with name " + name_details.name)
	for layer_name in layer_names:
		layer_lookup[layer_name] = prep_tile_data(layer_name)
	# Build room rows,cols one tile at a time
	for ii in range(grid_height):
		var row = _definition.row[ii].text
		for jj in range(grid_width):
			var tile_character = row[jj]
			var added_tile = false
			for layer_name in layer_names:
				added_tile = added_tile || add_tile_if_match(jj, ii, tile_character, layer_name)
			var has_floor = false
			var has_wall = false
			var sprite_path = null
			var	entity_name = null
			match tile_character:
				".":			
					has_floor = true
				"#":
					has_wall = true
				"!": # Destrucible wall
					has_wall = true
				# Doors between rooms are usually joined by either 3x2 or 2x3 floor tiles
				"d": # TODO L/R door sprite
					if jj < grid_width / 2:
						_doors.left.append({
							x = jj,
							y = ii,
							kind = 'left'
						})
					else:
						_doors.right.append({
							x = jj,
							y = ii,
							kind = 'right'
						})					
				"D": # TODO U/D door sprite
					if ii < grid_height / 2:
						_doors.up.append({
							x = jj,
							y = ii,
							kind = 'up'
						})
					else:
						_doors.down.append({
							x = jj,
							y = ii,
							kind = 'down'
						})	
				"W":						
					entity_name = "water"
				"L":
					entity_name = "lava"
				"I":
					entity_name = "ice"
				"G":
					entity_name = "goo"
				"^":
					has_floor = true
					if name_details.flooring != null:
						entity_name = "floor_decoration"
						sprite_path = name_details.flooring
				"P":
					has_wall = true
					if name_details.painting != null:
						entity_name = "wall_decoration"
						sprite_path = name_details.painting
				"@":
					has_floor = true
					if name_details.statue != null:
						entity_name = "floor_decoration"
						sprite_path = name_details.statue
				" ": # Empty space
					pass
				_:
					if not added_tile:						
						Log.warn("Unhandled tile " + tile_character)
			if has_floor:
				_entity_grid.add_tile(jj, ii, "floor")
			if has_wall:
				_entity_grid.add_tile(jj, ii, "wall")
			if entity_name != null:
				_entity_grid.add_tile(jj, ii, entity_name, sprite_path)

func has_available_doors():
	for key in _doors.keys():
		if _doors[key].size() > 0:
			return true
	return false
	
func get_door(kind):
	if _doors[kind].size() == 0:
		return null	
	_doors[kind].shuffle()
	return _doors[kind][0]
	
func claim_door(x, y, kind):
	var kill_index = null
	var index = 0
	for door in _doors[kind]:		
		if door.x == x and door.y == y:
			kill_index = index
			break
		index += 1
	_doors[kind].remove(kill_index)

func prep_tile_data(layer_name):
	var result = {
		_coordinate = {}
	}
	if _definition.has(layer_name):
		if typeof(_definition[layer_name]) == TYPE_ARRAY:
			for entry in _definition[layer_name]:
				if 'at' in entry:
					result[entry.at] = entry
				if 'x' in entry:
					if not result._coordinate.has(int(entry.x) - 1):
						result._coordinate[int(entry.x) - 1] = {}
					result._coordinate[int(entry.x) - 1][int(entry.y) - 1] = entry
		else:
			var entry = _definition[layer_name]
			if 'at' in entry:
					result[entry.at] = entry
			if 'x' in entry:
				if not result._coordinate.has(int(entry.x) - 1):
					result._coordinate[int(entry.x) - 1] = {}
				result._coordinate[int(entry.x) - 1][int(entry.y) - 1] = entry
	return result
	
func add_tile_if_match(x, y, tile_character, layer_name):	
	# X and Y inverted in room xml vs everywhere else
	var layer = layer_lookup[layer_name]
	var item = null
	if y in layer._coordinate and x in layer._coordinate[y]:
		item = layer._coordinate[y][x]
	if tile_character in layer:
		item = layer[tile_character]
	if item != null:
		_entity_grid.add_tile(x, y, "floor")
		if item.has('percent') and ! ODMath.chance(item.percent):
			return true
		call(layer_name + "_tile_handler", item, x, y)
		return true
	return false

func customblocker_tile_handler(item, x, y):
	var animation = null
	if item.has('pngSprite'):
		animation = Load.png_sprite(item.pngSprite, int(item.pngFirst), int(item.pngNum), int(item.pngRate))
	if item.has('png'):
		animation = Load.animation(item.png)
	if animation != null:
		_entity_grid.add_animation(x, y, "customblocker", animation)

func customengraving_tile_handler(item, x, y):
	var animation = null
	if item.has('pngSprite'):
		animation = Load.png_sprite(item.pngSprite, int(item.pngFirst), int(item.pngNum), int(item.pngRate))
	if item.has('png'):
		animation = Load.animation(item.png)
	if animation != null:
		_entity_grid.add_animation(x, y, "customengraving", animation)

func element_tile_handler(item, _x, _y):
	if not item.has('type'):
		return
	match item.type:
		"bookshelf":
			pass
		_:
			Log.warn("Unhandled element tile type [" + item.type + "]")

func loot_tile_handler(item, _x, _y):
	if not item.has('type'):
		return
	match item.type:
		'armor':
			pass
		'zorkmids':
			pass
		_:
			Log.warn("Unhandled loot tile type [" + item.type + "]")
	pass

func monster_tile_handler(item, _x, _y):
	if not item.has('name'):
		return
	match item.name:
		'Diggle':
			pass
		_:
			Log.warn("Unhandled monster tile type [" + item.name + "]")
			
func horde_tile_handler(item, _x, _y):
	if not item.has('name'):
		return
	match item.name:
		"Lil Batty":
			pass
		_:
			Log.warn("Unhandled horde tile type [" + item.name + "]")
