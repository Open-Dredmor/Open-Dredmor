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

func element_tile_handler(_layer, _item, _x, _y):
	pass

func loot_tile_handler(_layer, _item, _x, _y):
	pass

func monster_handler(_layer, _item, _x, _y):
	pass
	
func horde_handler(_layer, _item, x, y):
	pass

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
	var custom_blocker_tiles = Node2D.new()
	custom_blocker_tiles.name = "CustomBlockerTiles"
	var custom_engraving_tiles = Node2D.new()
	custom_engraving_tiles.name = "CustomEngravingTiles"
	var element_tiles = Node2D.new()
	element_tiles.name = "ElementTiles"
	var wall_tiles = Node2D.new()
	wall_tiles.name = "WallTiles"
	var loot_tiles = Node2D.new()
	loot_tiles.name = "LootTiles"
	var horde_tiles = Node2D.new()
	horde_tiles.name = "HordeTiles"
	var monster_tiles = Node2D.new()
	monster_tiles.name = "MonsterTiles"
	vbox.add_child(liquid_tiles)
	vbox.add_child(floor_tiles)
	vbox.add_child(wall_tiles)
	vbox.add_child(custom_blocker_tiles)
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
	
	# Build room rows,cols one tile at a time	
	for ii in range(room.height):
		var row = room.row[ii].text
		for jj in range(room.width):
			var tile_character = row[jj]
			var added_tile = add_tile_if_match(custom_blocker_tiles, jj, ii, tile_character, custom_blockers, floor_tiles, true, "custom_blocker_handler")
			added_tile = added_tile or add_tile_if_match(custom_engraving_tiles, jj, ii, tile_character, custom_engravings,  floor_tiles, true, "custom_engraving_handler")
			added_tile = added_tile or add_tile_if_match(element_tiles, jj, ii, tile_character, elements,  floor_tiles, true, "element_tile_handler")
			added_tile = added_tile or add_tile_if_match(loot_tiles, jj, ii, tile_character, loot,  floor_tiles, true, "loot_tile_handler")			
			added_tile = added_tile or add_tile_if_match(horde_tiles, jj, ii, tile_character, hordes,  floor_tiles, true, "horde_handler")			
			added_tile = added_tile or add_tile_if_match(monster_tiles, jj, ii, tile_character, monsters,  floor_tiles, true, "monster_handler")			
			match tile_character:
				".":			
					var tile = tilesets.basic.get_tile("floor")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					floor_tiles.add_child(tile)
				"#":
					var tile = tilesets.basic.get_tile("wall")
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					wall_tiles.add_child(tile)
				"d":
					pass # Needs to be a L/R door sprite
				"D":
					pass # Needs to be a U/D door sprite
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
				" ": # Empty floor
					pass
				_:
					if not added_tile:
						print("Unhandled tile " + tile_character)
		
	
