extends Node2D

class_name Dungeon

var floors = []
var current_floor = 0
# TODO Use ID instead of name
var current_branch = "The Dungeon"
var tilesets = null

func _ready():	
	call_deferred("_build_ui")

func _input(ev):
	if ev is InputEventKey and ev.is_pressed() and ev.scancode == KEY_SPACE and not ev.echo:
		Scenes.goto(Scenes.GAME)

func prep_tile_data(room, tiles_key):
	var result = {
		_coordinate = {}
	}
	if room.has(tiles_key):
		if typeof(room[tiles_key]) == TYPE_ARRAY:
			for entry in room[tiles_key]:
				if 'at' in entry:
					result[entry.at] = entry
				if 'x' in entry:
					if not result._coordinate.has(int(entry.x) - 1):
						result._coordinate[int(entry.x) - 1] = {}
					result._coordinate[int(entry.x) - 1][int(entry.y) - 1] = entry
		else:
			var entry = room[tiles_key]
			if 'at' in entry:
					result[entry.at] = entry
			if 'x' in entry:
				if not result._coordinate.has(int(entry.x) - 1):
					result._coordinate[int(entry.x) - 1] = {}
				result._coordinate[int(entry.x) - 1][int(entry.y) - 1] = entry
	return result
	
var cell_height = 32
var cell_width = 32

func custom_blocker_handler(layer, item, x, y):
	var animation = null
	if item.has('pngSprite'):
		animation = Load.png_sprite(item.pngSprite, int(item.pngFirst), int(item.pngNum), int(item.pngRate))
	if item.has('png'):
		animation = Load.animation(item.png)
	animation.position = Vector2(x * cell_width, y * cell_height)
	layer.add_child(animation)
	if item.has('pngSprite'):
		animation.play()

func custom_engraving_handler(layer, item, x, y):
	var animation = null
	if item.has('pngSprite'):
		animation = Load.png_sprite(item.pngSprite, int(item.pngFirst), int(item.pngNum), int(item.pngRate))
	if item.has('png'):
		animation = Load.animation(item.png)
	animation.position = Vector2(x * cell_width, y * cell_height)
	layer.add_child(animation)
	if item.has('pngSprite'):
		animation.play()

func element_tile_handler(_layer, item, _x, _y):
	if not item.has('type'):
		return
	match item.type:
		"bookshelf":
			pass
		_:
			Log.warn("Unhandled element tile type [" + item.name + "]")

func loot_tile_handler(_layer, item, _x, _y):
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

func monster_handler(_layer, item, _x, _y):
	if not item.has('name'):
		return
	match item.name:
		'Diggle':
			pass
		_:
			Log.warn("Unhandled monster tile type [" + item.name + "]")
			
func horde_handler(_layer, item, x, y):
	if not item.has('name'):
		return
	match item.name:
		"Lil Batty":
			pass
		_:
			Log.warn("Unhandled horde tile type [" + item.name + "]")

func add_tile_if_match(tile_layer, x, y, tile_character, tile_lookup, floor_tiles, has_floor, tile_handler):	
	# X and Y inverted by data elements
	var item = null
	if y in tile_lookup._coordinate and x in tile_lookup._coordinate[y]:
		item = tile_lookup._coordinate[y][x]
	if tile_character in tile_lookup:
		item = tile_lookup[tile_character]
	if item != null:
		if has_floor:
			var floor_tile = tilesets.basic.get_tile("floor")
			floor_tile.position = Vector2(x * cell_width, y * cell_height)
			floor_tiles.add_child(floor_tile)
		if item.has('percent') and ! ODMath.chance(item.percent):
			return true
		call(tile_handler, tile_layer, item, x, y)
		return true
	return false


func _build_ui():
	tilesets = Assets.tilesets()
	
	var room_name_info = Database.create_room_name()
	
	# Useful development rooms
	# Starting Room - First place every run begins
	# Batty Cave - Water
	# 20x20 Large Treasury - Lava
	
#	floors.append({
#		entry_room = "Starting_Room",
#		rooms = {
#			Starting_Room = Database.get_room("Starting Room")
#		}
#	})
#
#	floors.append({
#		entry_room = "Batty_Cave",
#		rooms = {
#			Batty_Cave = Database.get_room("Batty Cave")
#		}
#	})	
	
	floors.append({
		entry_room = "20x20_Large_Treasury",
		rooms = {
			"20x20_Large_Treasury": Database.get_room("20x20 Large Treasury")
		}
	})
	print("Generating room " + room_name_info.name)
	var _floor = floors[current_floor]
	var room = _floor.rooms[_floor.entry_room]
	room.width = int(room.width)
	room.height = int(room.height)
	
	# https://docs.godotengine.org/en/3.2/tutorials/2d/using_tilemaps.html
	var container = Panel.new()
	container.set_size(Settings.display_size())
	add_child(container)
	var hbox = HBoxContainer.new()
	hbox.anchor_left = .3
	hbox.anchor_top = .2
	hbox.alignment = BoxContainer.ALIGN_CENTER
	container.add_child(hbox)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGN_CENTER
	hbox.add_child(vbox)
	
	
	var liquid_tiles = Node2D.new()
	liquid_tiles.name = "LiquidTiles"
	var floor_tiles = Node2D.new()
	floor_tiles.name = "FloorTiles"
	var floor_decoration_tiles = Node2D.new()
	floor_decoration_tiles.name = "FloorDecorationTiles"
	var custom_blocker_tiles = Node2D.new()
	custom_blocker_tiles.name = "CustomBlockerTiles"
	var statue_tiles = Node2D.new()
	statue_tiles.name = "StatueTiles"
	var custom_engraving_tiles = Node2D.new()
	custom_engraving_tiles.name = "CustomEngravingTiles"
	var element_tiles = Node2D.new()
	element_tiles.name = "ElementTiles"
	var wall_tiles = Node2D.new()
	wall_tiles.name = "WallTiles"
	var wall_decoration_tiles = Node2D.new()
	wall_decoration_tiles.name = "WallDecorationTiles"
	var loot_tiles = Node2D.new()
	loot_tiles.name = "LootTiles"
	var horde_tiles = Node2D.new()
	horde_tiles.name = "HordeTiles"
	var monster_tiles = Node2D.new()
	monster_tiles.name = "MonsterTiles"
	vbox.add_child(liquid_tiles)
	vbox.add_child(floor_tiles)
	vbox.add_child(floor_decoration_tiles)
	vbox.add_child(wall_tiles)
	vbox.add_child(wall_decoration_tiles)
	vbox.add_child(custom_blocker_tiles)
	vbox.add_child(statue_tiles)
	vbox.add_child(custom_engraving_tiles)
	vbox.add_child(element_tiles)	
	vbox.add_child(loot_tiles)
	vbox.add_child(horde_tiles)
	vbox.add_child(monster_tiles)
	
	
	# Prepare room asset lookups
	var custom_blockers = prep_tile_data(room, 'customblocker')
	var custom_engravings = prep_tile_data(room, 'customengraving')
	var elements = prep_tile_data(room, 'element')
	var loot = prep_tile_data(room, 'loot')
	var monsters = prep_tile_data(room, 'monster')
	var hordes = prep_tile_data(room, 'horde')
	
	# Room definition info from mod instructions
	# https://steamcommunity.com/sharedfiles/filedetails/?id=197131896
	# Wall
	#P Wall, plus possible tapestry or painting
	#! Destroyable Wall
	#. Floor Tile
	#X Impassable Tile
	#^ Possible Random Floor Decoration
	#D Horizontal Door
	#d Vertical Door
	#@ Possible Random Floor Blocker
	#S Shopkeeper (Brax)
	#s Shop Entrance
	#i Sales Pedestal
	# Build room rows,cols one tile at a time	
	
	var layer_handlers = [
		[custom_blocker_tiles, custom_blockers, "custom_blocker_handler"],
		[custom_engraving_tiles, custom_engravings, "custom_engraving_handler"],
		[element_tiles, elements, "element_tile_handler"],
		[loot_tiles, loot, "loot_tile_handler"],
		[monster_tiles, monsters, "monster_handler"],
		[horde_tiles, hordes, "horde_handler"]
	]
	
	for ii in range(room.height):
		var row = room.row[ii].text
		for jj in range(room.width):
			var tile_character = row[jj]
			var added_tile = false
			for layer in layer_handlers:
				added_tile = added_tile || add_tile_if_match(layer[0], jj, ii, tile_character, layer[1], floor_tiles, true, layer[2])
			match tile_character:
				".":			
					var tile = tilesets.basic.get_tile("floor")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					floor_tiles.add_child(tile)
				"#":
					var tile = tilesets.basic.get_tile("wall")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					wall_tiles.add_child(tile)
				"!": # Destrucible wall
					var tile = tilesets.basic.get_tile("wall")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					wall_tiles.add_child(tile)
				"d":
					pass # L/R door
				"D":
					pass # U/D door
				"W":						
					var tile = tilesets.liquids.get_animation('water')
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					liquid_tiles.add_child(tile)
					tile.play()
				"L":
					var tile = tilesets.liquids.get_animation('lava')
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					liquid_tiles.add_child(tile)
					tile.play()
				"I":
					var tile = tilesets.liquids.get_animation('ice')
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					liquid_tiles.add_child(tile)
					tile.play()
				"G":
					var tile = tilesets.liquids.get_animation('goo')
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					liquid_tiles.add_child(tile)				
					tile.play()
				"^":
					var tile = tilesets.basic.get_tile("floor")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					floor_tiles.add_child(tile)
					if room_name_info.flooring != null:
						var decoration_tile = Load.animation(room_name_info.flooring)
						decoration_tile.position = Vector2(jj * cell_width, ii * cell_height)
						floor_decoration_tiles.add_child(decoration_tile)
						decoration_tile.play()
				"P":
					var tile = tilesets.basic.get_tile("wall")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					wall_tiles.add_child(tile)
					if room_name_info.painting != null:
						var decoration_tile = Load.animation(room_name_info.painting)
						decoration_tile.position = Vector2(jj * cell_width, ii * cell_height)
						wall_decoration_tiles.add_child(decoration_tile)
						decoration_tile.play()
				"@":
					var tile = tilesets.basic.get_tile("floor")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					floor_tiles.add_child(tile)
					if room_name_info.statue != null:
						var decoration_tile = Load.animation(room_name_info.statue)
						decoration_tile.position = Vector2(jj * cell_width, ii * cell_height)
						statue_tiles.add_child(decoration_tile)
						decoration_tile.play()
				" ": # Empty space
					pass
				_:
					if not added_tile:						
						Log.warn("Unhandled tile " + tile_character)
		
	
