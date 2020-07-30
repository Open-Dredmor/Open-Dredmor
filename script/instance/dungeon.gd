extends Node2D

class_name Dungeon

var floors = []
var current_floor = 0
# TODO Use ID instead of name
var current_branch = "The Dungeon"

func _ready():	
	call_deferred("_build_ui")

func _build_ui():
	var tilesets = Assets.tilesets()
	
	floors.append({
		entry_room = "Batty_Cave",
		rooms = {
			Batty_Cave = Database.get_room("Batty Cave")
		}
	})
	var _floor = floors[current_floor]
	var room = _floor.rooms[_floor.entry_room]
	room.width = int(room.width)
	room.height = int(room.height)
	
	# https://docs.godotengine.org/en/3.2/tutorials/2d/using_tilemaps.html
	var container = Panel.new()
	container.margin_top = 100
	container.margin_left = 100
	add_child(container)
	
	var liquid_tiles = Node2D.new()
	var floor_tiles = Node2D.new()
	var wall_tiles = Node2D.new()
	container.add_child(liquid_tiles)
	container.add_child(floor_tiles)
	container.add_child(wall_tiles)
	
	var cell_height = 32
	var cell_width = 32
	for ii in range(room.height):
		var row = room.row[ii].text
		for jj in range(room.width):
			var tile_character = row[jj]
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
				"I":
					var tile = tilesets.liquids.get_animation('ice')
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					liquid_tiles.add_child(tile)
				"G":
					var tile = tilesets.liquids.get_animation('goo')
					tile.position = Vector2(jj * cell_width, ii * cell_height)
					liquid_tiles.add_child(tile)
				#_tilesets.liquids.set_animation('stars', 0,4,4)
				" ":
					pass
				_:
					print("Unhandled tile "+tile_character)
		
	
