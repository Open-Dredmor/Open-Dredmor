extends Node

var cache = null
var result_cache = null

func ingest():
	if cache == null:		
		# This loads vanilla datasets. Additional thought needed on how to manage the expansions
		cache = {}
		print("Ingesting vanilla game data")
		# monDB.xml explains that branches are a feature scrapped during development
		# However, the expansions have them...so what could they be?
		# They seem like tilemap definitions.
		cache.branches = Load.xml("game/branchDB.xml").branchDB.branch
		cache.crafting_recipe_db = Load.xml("game/craftDB.xml")
		cache.item_db = Load.xml("game/itemDB.xml")
		cache.magic_box_rooms_db = Load.xml("game/magicBoxRooms.xml")
		## manual.xml was next to empty, consider it a placeholder
		cache.monsters = Load.xml("game/monDB.xml").monDB.monster		
		cache.quest_item_db = Load.xml("game/quests.xml")
#		## rooms.dat might not be used. Not sure.
		cache.rooms = Load.xml("game/rooms.xml").roomdb.room
		#precompute_room_info()
#		# scrolls.xml didn't seem to be used
		cache.sound_db = Load.xml("game/soundfx.xml")
		cache.speech_db = Load.xml("game/speech.xml")
		cache.skills = Load.xml("game/skillDB.xml").skillDB.skill
		cache.spell_db = Load.xml("game/spellDB.xml")
		cache.template_db = Load.xml("game/manTemplateDB.xml")
		cache.text = Load.xml("game/text.xml").text
		cache.tutorial_db = Load.xml("game/tutorial.xml")
		cache.tweak_db = Load.xml("game/tweakDB.xml")
		
		_build_monster_info()

func cache_result(key,result):
	if result_cache == null:
		result_cache = {}
	result_cache[key] = result

func character_creation_skill_list():	
	if result_cache != null and result_cache.has('character_creation_skill_list'):
		return result_cache.character_creation_skill_list
	var result = []
	var skill_index = 0
	for skill in cache.skills:
		if ! skill.has('deprecated') or int(skill.deprecated) != 1:
			result.append({
				name = skill.name,
				description = skill.description,
				icon = Load.image(skill.art.icon),
				id = skill.id,				
				index = skill_index
			})
			skill_index += 1
	cache_result("character_creation_skill_list",result)
	return result

func random_room_id(floor_level):
	var short_circuit = 100
	while true:
		short_circuit -= 1
		var room = DataStructure.choose(cache.rooms, 1)
		if not room.has('flags') or not room.flags.has('minLevel'):
			return room.name
		if int(room.flags.minLevel) <= floor_level and int(room.flags.maxLevel) >= floor_level:
			return room.name
		if short_circuit <= 0:
			return null

func precompute_room_info():
	var min_width = 10000
	var min_height = 10000
	var max_width = 0
	var max_height = 0
	for room in cache.rooms:
		var width = room.row[0].text.length()
		var height = room.row.size()
		room.width = width
		room.height = height
		if width < min_width:
			min_width = width
		if width > max_width:
			max_width = width
		if height < min_height:
			min_height = height
		if height > max_height:
			max_height = height
	print("Min room dimensions: " + str(min_width) + " wide and " + str(min_height) + " tall")
	print("Max room dimensions: " + str(max_width) + " wide and " + str(max_height) + " tall")

func get_room_within(floor_level, max_width, max_height):
	var rooms = []
	for room in cache.rooms:		
		if room.width <= max_width and room.height <= max_height:
			if (not room.has('flags') or not room.flags.has('minLevel')) or (int(room.flags.minLevel) <= floor_level and int(room.flags.maxLevel) >= floor_level):
				rooms.append(room)
	return DataStructure.choose(rooms, 1).name

func get_room(room_name):	
	for room in cache.rooms:
		if room.name == room_name:
			return room

func create_room_name():
	# DEBUG - Cake has a custom blocker
#	for noun in lookup.noun:
#		if noun.text == "Cake":
#			noun = noun
	var noun = DataStructure.choose(cache.text.noun, 1)
	var adjective = DataStructure.choose(cache.text.adjective, 1)
	var architecture = DataStructure.choose(cache.text.architecture, 1)
	
	return {
		name = adjective.text + " " + architecture.text + " of " + noun.text,
		statue = noun.statue if noun.has('statue') else null,
		flooring = noun['floor'] if noun.has('floor') else null,
		painting = noun.painting if noun.has('painting') else null,
	}
	
func get_branch(branch_id):
	for branch in cache.branches:
		if int(branch.id) == branch_id:
			return branch
	return null
	
func get_all_rooms():
	return cache.rooms

func _build_monster_info():
	var monsters = {}
	for monster in cache.monsters:
		monsters[monster.name] = monster
		if monster.has('monster'):
			if typeof(monster.monster) == TYPE_ARRAY:
				for child in monster.monster:
					monsters[child.name] = DataStructure.merge(monster, child)
			if typeof(monster.monster) == TYPE_DICTIONARY:
				monsters[monster.monster.name] = DataStructure.merge(monster, monster.monster)
	cache_result("monster_info", monsters)

func get_monster(name):
	if not result_cache["monster_info"].has(name):
		return null
	return result_cache["monster_info"][name]
