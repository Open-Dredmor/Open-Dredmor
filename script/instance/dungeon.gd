extends Node2D

class_name Dungeon

var floors = []
var current_floor = 0

func _ready():	
	call_deferred("_build_ui")

func _build_ui():
	var assets = Assets.game()
	
	floors.append({
		entry_room = "Starting_Room",
		rooms = {
			Starting_Room = Database.get_room("Starting Room")
		}
	})
	var _floor = floors[current_floor]
	var room = _floor.rooms[_floor.entry_room]
	room.width = int(room.width)
	room.height = int(room.height)
	
	# https://docs.godotengine.org/en/3.2/tutorials/2d/using_tilemaps.html
	var floor_tiles = GridContainer.new()
	var wall_tiles = GridContainer.new()
	var cell_height = 32
	var cell_width = 32
	var first = false
	for ii in range(room.height):
		var row = room.row[ii].text
		for jj in range(room.width):
			var tile = row[jj]
			match tile:
				".":
					var floor_tile = Sprite.new()
					floor_tile.region_enabled = true
					# 0,5 from branchDB
					floor_tile.region_rect = Rect2(0 * cell_width, 5 * cell_height, cell_width, cell_height)
					floor_tile.position = Vector2(cell_width * jj, cell_height * ii)
					floor_tile.texture = assets.tileset.basic
					floor_tiles.add_child(floor_tile)
				_:
					print("Unhandled tile "+tile)
	
	add_child(floor_tiles)
	add_child(wall_tiles)
	
