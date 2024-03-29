extends Node2D

class_name Room

var collision_rect = OD.Rect.new()
var grid_width
var grid_height
var layer_lookup = {}

# Still need pedestal, script, trap, custombreakable

var layer_names = [
	"customblocker",
	"custombreakable",
	"trap",
	"pedestal",
	"customengraving",
	"element",
	"loot",
	"monster",
	"horde"
]

var entity_grid
var _definition
var _doors = {
	left = [],
	right = [],
	up = [],
	down = []
}

var tilesets
var name_details
var debug_button

func get_debug_button():
	return debug_button

func debug_info():
	print("Clicked room id " + name_details.database_id + " with name " + name_details.name)
	print("Bounded by (" + str(collision_rect.x1) + ', ' + str(collision_rect.y1) + ") -> (" + str(collision_rect.x2)+", " + str(collision_rect.y2) + ")")
	z_index += 100

func init(room_database_name):	
	entity_grid = EntityGrid.new()	
	entity_grid.init()
	add_child(entity_grid)
	
	_definition = OD.Database.get_room(room_database_name)
	# Rough passage 3 in game/rooms.xml has a width/height that doesn't match the data
	# Count the strings lengths instead of trusting the reported values
	grid_width = _definition.row[0].text.length()
	grid_height = _definition.row.size()
	debug_button = OD.Chrome.invisible_button()
	var hover_button_style = StyleBoxFlat.new()
	hover_button_style.bg_color = Color(.5,.5,0,.3)
	debug_button.add_stylebox_override("hover",hover_button_style)
	debug_button.rect_size = Vector2((grid_width + 1) * OD.Assets.CELL_PIXEL_WIDTH, (grid_height + 1) * OD.Assets.CELL_PIXEL_HEIGHT)
	debug_button.connect("pressed", self, "debug_info")

	name_details = OD.Database.create_room_name()
	name_details.database_id = room_database_name
	#print("Generating room id " + room_database_name + " with name " + name_details.name)
	for layer_name in layer_names:
		layer_lookup[layer_name] = prep_tile_data(layer_name)
	var script_location = {
		_coordinate = {}
	}
	if _definition.has('script'):
		var scripts = OD.DataStructure.arrayify(_definition.script)
		for script in scripts:
			if script.has('condition'):
				var conditions = OD.DataStructure.arrayify(script.condition)
				for condition in conditions:
					if 'at' in condition:
						script_location[condition.at] = condition
					if 'x' in condition:
						if not script_location._coordinate.has(int(condition.x)):
							script_location._coordinate[int(condition.x)] = {}
						script_location._coordinate[int(condition.x)][int(condition.y)] = condition
			if script.has('action'):
				var actions = OD.DataStructure.arrayify(script.action)
				for action in actions:
					if 'at' in action:
						script_location[action.at] = action
					if 'x' in action:
						if not script_location._coordinate.has(int(action.x)):
							script_location._coordinate[int(action.x)] = {}
						script_location._coordinate[int(action.x)][int(action.y)] = action				
			
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
			if script_location.has(ii) and script_location[ii].has(jj):				
				added_tile = true
				has_floor = true
			if script_location.has(tile_character):
				added_tile = true
				has_floor = true
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
				"S":
					has_floor = true
					entity_name = "monster"
					# TODO Use the Brax monster instead of a sprite
					sprite_path = "sprites/monster/brax/brax_run_d.spr"
				"s": # Brax teleport location while shopping
					has_floor = true
				"i": # sales pedestal
					has_floor = true
					entity_name = "customblocker"
					sprite_path = "dungeon/store_pedestal.png"
				"X": # Invisible blocker
					has_floor = true
				" ": # Empty space
					pass
				_:
					if not added_tile:
						if OD.Log.warn("Unhandled tile [" + tile_character + "]"):
							print(room_database_name)
			if has_floor:
				entity_grid.add_tile(jj, ii, "floor")
			if has_wall:
				entity_grid.add_tile(jj, ii, "wall")
			if entity_name != null:
				entity_grid.add_tile(jj, ii, entity_name, sprite_path)

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
					if not result._coordinate.has(int(entry.x)):
						result._coordinate[int(entry.x)] = {}
					result._coordinate[int(entry.x)][int(entry.y)] = entry
		else:
			var entry = _definition[layer_name]
			if 'at' in entry:
					result[entry.at] = entry
			if 'x' in entry:
				if not result._coordinate.has(int(entry.x)):
					result._coordinate[int(entry.x)] = {}
				result._coordinate[int(entry.x)][int(entry.y)] = entry
	return result
	
func add_tile_if_match(x, y, tile_character, layer_name):		
	var layer = layer_lookup[layer_name]
	var item = null
	if x in layer._coordinate and y in layer._coordinate[x]:
		item = layer._coordinate[x][y]
	if tile_character in layer:
		item = layer[tile_character]
	if item != null:
		entity_grid.add_tile(x, y, "floor")
		if item.has('percent') and ! OD.Math.chance(item.percent):
			return true
		call(layer_name + "_tile_handler", item, x, y)
		return true
	return false

func customblocker_tile_handler(item, x, y):
	var animation = null
	if item.has('pngSprite'):
		animation = OD.Load.png_sprite(item.pngSprite, int(item.pngFirst), int(item.pngNum), int(item.pngRate))
	if item.has('png'):
		animation = OD.Load.animation(item.png)
	if animation != null:
		entity_grid.add_animation(x, y, "customblocker", animation)

func customengraving_tile_handler(item, x, y):
	var animation = null
	if item.has('pngSprite'):
		animation = OD.Load.png_sprite(item.pngSprite, int(item.pngFirst), int(item.pngNum), int(item.pngRate))
	if item.has('png'):
		animation = OD.Load.animation(item.png)
	if animation != null:
		entity_grid.add_animation(x, y, "customengraving", animation)

func element_tile_handler(item, x, y):
	var assets = OD.Assets.elements()
	var asset = null
	match item.type:
		"anvil":
			asset = assets.anvil
		"boltvending":
			asset = assets.vendor.bolt
		"bookshelf":
			asset = assets.bookshelf
		"craftvending":
			asset = assets.vendor.craft
		"dredmorstatue":
			asset = assets.dredmor_statue
		"drinkvending":
			asset = assets.vendor.drink
		"foodvending":
			asset = assets.vendor.food
		"lever":
			asset = assets.lever
		"lutefiskstatue":
			asset = assets.lutefisk_statue
		"statue":
			asset = OD.DataStructure.choose(assets.statues)
		"thrownvending":
			asset = assets.vendor.thrown
		_:
			OD.Log.warn("Unhandled element tile type [" + item.type + "]")
	if asset != null:
		entity_grid.add_animation(x, y, "element", asset)

func loot_tile_handler(item, x, y):
	# TODO Loot should have a sparkling effect
	var sprite = null
	if item.type == 'zorkmids':
		# TODO Base the amount and size on the current floor
		sprite = OD.Load.animation(OD.DataStructure.choose(OD.Resource.paths.loot.zorkmids))
	elif item.type == 'misc': # misc is always lockpicks
		sprite = OD.Load.animation(OD.Resource.paths.loot.lockpick)
	else:
		var loot = OD.Database.get_loot(item.type, item.subtype if item.has('subtype') else null)		
		if loot == null:
			OD.Log.warn("Unhandled loot tile type [" + item.type + "]")
		else:
			sprite = OD.Load.animation(loot.iconFile)
	if sprite != null:
		entity_grid.add_animation(x, y, 'loot', sprite)

func monster_tile_handler(item, x, y):
	if not item.has('name'):
		return
	var monster = null
	if item.has('name'):
		monster = OD.Database.get_monster(item.name)
	else:
		monster = OD.Database.get_random_monster()
	if monster == null:
		OD.Log.warn("Unhandled monster tile type [" + item.name + "]")
		return
	var animation = OD.Load.animation(monster.idleSprite.down)
	entity_grid.add_animation(x, y, 'monster', animation)
			
func horde_tile_handler(item, x, y):
	if not item.has('name'):
		return
	var monster = OD.Database.get_monster(item.name)
	if monster == null:
		OD.Log.warn("Unhandled horde tile type [" + item.name + "]")
		return
	var animation = OD.Load.animation(monster.idleSprite.down)
	entity_grid.add_animation(x, y, 'horde', animation)

func pedestal_tile_handler(_item, x, y):
	var animation = OD.Load.animation(OD.Resource.paths.pedestal)
	entity_grid.add_animation(x, y, 'pedestal', animation)

func custombreakable_tile_handler(item, x, y):
	var animation = OD.Load.animation(item.png)
	entity_grid.add_animation(x, y, 'custom_breakable', animation)
	
func trap_tile_handler(item, x, y):
	# TODO All of these graphics are placeholders
	var animation = null
	if not item.has('name'):
		animation = OD.Load.animation(OD.DataStructure.choose(OD.Resource.paths.traps))
	else:
		match item.name:
			"Gargoyle Arrow Trap":
				animation = OD.Load.animation(OD.Resource.paths.traps[0])
			"Gargoyle Acid Bolt Trap":
				animation = OD.Load.animation(OD.Resource.paths.traps[1])
			"Robo Bolt Trigger":
				animation = OD.Load.animation(OD.Resource.paths.traps[2])
			"Scalding Steam Mine":
				animation = OD.Load.animation(OD.Resource.paths.traps[3])
			"Shoddy Dwarven IED":
				animation = OD.Load.animation(OD.Resource.paths.traps[4])
			_:
				OD.Log.warn("Unhandled trap [" + item.name + "]")
	entity_grid.add_animation(x, y, 'trap', animation)
	
func possible_doors():
	var result = []
	for key in _doors.keys():
		if _doors[key].size() > 0:
			result.append(key)
	return result

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
			entity_grid.add_tile(door.x, door.y, "floor")
			kill_index = index
			break
		index += 1
	_doors[kind].remove(kill_index)
	# TODO Add the door and remove surrounding walls

func seal_available_doors():
	for kind in _doors.keys():
		for door in _doors[kind]:
			entity_grid.add_tile(door.x, door.y, "wall")
