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
	# 384 W x 640 H = Stairs tiles in basic tileset
	# <tile name="stairsup" startx="10" starty="15" endy="17" /> from branchDB
	# 384 W x 320 H is the cell size?
	var floor_tiles = GridContainer.new()
	var wall_tiles = GridContainer.new()
	for ii in range(room.height):
		var row = room.row[ii].text
		for jj in range(room.width):
			var tile = row[jj]
			match tile:
				".":
					var floor_tile = Sprite.new()
					floor_tiles.add_child(floor_tile)
				_:
					print("Unhandled tile "+tile)
			print("y: " + str(ii) + ", x: " + str(jj) + ", t: "+tile)
			
	add_child(floor_tiles)
	
