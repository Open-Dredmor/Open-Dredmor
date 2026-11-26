extends RefCounted

var monsters_by_name = {}
var monster_list = []
var tweaks = {}
var branches_by_id = {}
var branches_by_name = {}
var branch_list = []
var rooms_by_name = {}
var room_list = []
var wizard_rooms = []
var magic_box_rooms = []
var sounds = {}

func build(cache):
	_build_monsters(cache)
	_build_tweaks(cache)
	_build_branches(cache)
	_build_rooms(cache)
	_build_sounds(cache)

func _merge_monster_variant(parent_monster, variant_monster):
	var merged = parent_monster.duplicate(true)
	merged.erase("monster")
	for key in variant_monster.keys():
		if key == "stats" and merged.has("stats") and typeof(merged.stats) == TYPE_DICTIONARY and typeof(variant_monster.stats) == TYPE_DICTIONARY:
			var merged_stats = merged.stats.duplicate(true)
			for stat_key in variant_monster.stats.keys():
				merged_stats[stat_key] = variant_monster.stats[stat_key]
			merged.stats = merged_stats
		else:
			merged[key] = variant_monster[key]
	return merged

func _build_monsters(cache):
	monsters_by_name = {}
	for monster in cache.monsters:
		if typeof(monster) != TYPE_DICTIONARY or not monster.has("name"):
			continue
		monsters_by_name[monster.name] = monster
		if monster.has("monster"):
			var children = OD.DataStructure.arrayify(monster.monster)
			for child in children:
				if typeof(child) == TYPE_DICTIONARY and child.has("name"):
					monsters_by_name[child.name] = _merge_monster_variant(monster, child)
	monster_list = monsters_by_name.values()

func get_monster(monster_name):
	return monsters_by_name[monster_name] if monsters_by_name.has(monster_name) else null

func get_random_monster():
	if monster_list.is_empty():
		return null
	return monster_list[randi() % monster_list.size()]

func _build_tweaks(cache):
	tweaks = {}
	if cache.tweak_db.has("tweakDB"):
		var blocks = OD.DataStructure.arrayify(cache.tweak_db.tweakDB)
		for block in blocks:
			if typeof(block) == TYPE_DICTIONARY and block.has("tweak"):
				for tweak in OD.DataStructure.arrayify(block.tweak):
					if typeof(tweak) != TYPE_DICTIONARY or not tweak.has("name"):
						continue
					if tweak.has("ival"):
						tweaks[tweak.name] = int(tweak.ival)
					elif tweak.has("fval"):
						tweaks[tweak.name] = float(tweak.fval)
					elif tweak.has("sval"):
						tweaks[tweak.name] = tweak.sval

func get_tweak(tweak_name, default_value = null):
	return tweaks[tweak_name] if tweaks.has(tweak_name) else default_value

func _build_branches(cache):
	branches_by_id = {}
	branches_by_name = {}
	branch_list = []
	for branch in cache.branches:
		if typeof(branch) != TYPE_DICTIONARY or not branch.has("id"):
			continue
		var branch_id = int(branch.id)
		var entry = {
			id = branch_id,
			name = branch.name if branch.has("name") else "",
			length = int(branch.length) if branch.has("length") else 1,
			generator = int(branch.generator) if branch.has("generator") else 1,
			tileset = branch.tileset.name if branch.has("tileset") and typeof(branch.tileset) == TYPE_DICTIONARY and branch.tileset.has("name") else "",
			music = branch.music.name if branch.has("music") and typeof(branch.music) == TYPE_DICTIONARY and branch.music.has("name") else "",
			leveldata = branch.leveldata if branch.has("leveldata") else {},
			tiles = OD.DataStructure.arrayify(branch.tile) if branch.has("tile") else [],
			raw = branch
		}
		branches_by_id[branch_id] = entry
		if entry.name != "":
			branches_by_name[entry.name] = entry
	branch_list = branches_by_id.values()

func get_branch_info(branch_id_or_name):
	if typeof(branch_id_or_name) == TYPE_INT or (typeof(branch_id_or_name) == TYPE_STRING and branch_id_or_name.is_valid_int()):
		var branch_id = int(branch_id_or_name)
		return branches_by_id[branch_id] if branches_by_id.has(branch_id) else null
	return branches_by_name[branch_id_or_name] if branches_by_name.has(branch_id_or_name) else null

func _parse_room_layout(room):
	if typeof(room) != TYPE_DICTIONARY or not room.has("name") or not room.has("row"):
		return null
	var rows = OD.DataStructure.arrayify(room.row)
	if rows.is_empty():
		return null
	var grid_width = rows[0].text.length()
	var grid_height = rows.size()
	var doors = { up = [], down = [], left = [], right = [] }
	var floor_cells = []
	for row_index in range(grid_height):
		var row_text = rows[row_index].text
		for col_index in range(min(grid_width, row_text.length())):
			var tile_character = row_text[col_index]
			if tile_character == ".":
				floor_cells.append(Vector2i(col_index, row_index))
			elif tile_character == "d":
				if col_index < grid_width / 2:
					doors.left.append({ x = col_index, y = row_index, kind = "left" })
				else:
					doors.right.append({ x = col_index, y = row_index, kind = "right" })
			elif tile_character == "D":
				if row_index < grid_height / 2:
					doors.up.append({ x = col_index, y = row_index, kind = "up" })
				else:
					doors.down.append({ x = col_index, y = row_index, kind = "down" })
	var flags = room.flags if room.has("flags") and typeof(room.flags) == TYPE_DICTIONARY else {}
	return {
		id = -1,
		name = room.name,
		width = grid_width,
		height = grid_height,
		raw = room,
		min_level = int(flags.minLevel) if flags.has("minLevel") else 0,
		max_level = int(flags.maxLevel) if flags.has("maxLevel") else 99,
		special = flags.has("special") and int(flags.special) == 1,
		shop = flags.has("shop") and int(flags.shop) == 1,
		zoo = flags.has("zoo") and int(flags.zoo) == 1,
		noblockers = flags.has("noblockers") and int(flags.noblockers) == 1,
		notraps = flags.has("notraps") and int(flags.notraps) == 1,
		notreasure = flags.has("notreasure") and int(flags.notreasure) == 1,
		nomonsters = flags.has("nomonsters") and int(flags.nomonsters) == 1,
		genhint = flags.get("genhint", ""),
		doors = doors,
		floor_cells = floor_cells
	}

func _build_rooms(cache):
	rooms_by_name = {}
	room_list = []
	for room in cache.rooms:
		var layout = _parse_room_layout(room)
		if layout == null:
			continue
		rooms_by_name[layout.name] = layout
	for layout in rooms_by_name.values():
		layout.id = room_list.size()
		room_list.append(layout)
	wizard_rooms = []
	for wizard_room in cache.wizard_rooms:
		var wizard_layout = _parse_room_layout(wizard_room)
		if wizard_layout != null:
			wizard_rooms.append(wizard_layout)
	magic_box_rooms = []
	if cache.magic_box_rooms_db.has("roomdb") and cache.magic_box_rooms_db.roomdb.has("room"):
		for box_room in OD.DataStructure.arrayify(cache.magic_box_rooms_db.roomdb.room):
			var box_layout = _parse_room_layout(box_room)
			if box_layout != null:
				magic_box_rooms.append(box_layout)

func get_room_layout(room_name):
	return rooms_by_name[room_name] if rooms_by_name.has(room_name) else null

func get_room_layouts_for_floor(floor_index):
	var eligible = []
	for layout in room_list:
		if layout.min_level <= floor_index and layout.max_level >= floor_index:
			eligible.append(layout)
	return eligible

func get_room(room_name):
	if rooms_by_name.has(room_name):
		return rooms_by_name[room_name].raw
	for wizard_layout in wizard_rooms:
		if wizard_layout.name == room_name:
			return wizard_layout.raw
	for box_layout in magic_box_rooms:
		if box_layout.name == room_name:
			return box_layout.raw
	return null

func _build_sounds(cache):
	sounds = {}
	if cache.sound_db.has("sounds"):
		var sound_blocks = OD.DataStructure.arrayify(cache.sound_db.sounds)
		for block in sound_blocks:
			if typeof(block) == TYPE_DICTIONARY and block.has("sound"):
				var entries = OD.DataStructure.arrayify(block.sound)
				for entry in entries:
					if typeof(entry) == TYPE_DICTIONARY and entry.has("name") and entry.has("wave"):
						sounds[entry.name] = entry.wave
