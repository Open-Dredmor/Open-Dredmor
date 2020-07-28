extends Node

var db_cache = null
var result_cache = null

func ingest():
	if db_cache == null:		
		# This loads vanilla datasets. Additional thought needed on how to manage the expansions
		db_cache = {}
		print("Ingesting vanilla game data")
		# monDB.xml explains that branches are a feature scrapped during development
		# However, the expansions have them...so what could they be?
		db_cache.branch_db = Load.xml("game/branchDB.xml")
		db_cache.crafting_recipe_db = Load.xml("game/craftDB.xml")
		db_cache.item_db = Load.xml("game/itemDB.xml")
		db_cache.magic_box_rooms_db = Load.xml("game/magicBoxRooms.xml")
		## manual.xml was next to empty, consider it a placeholder
		db_cache.monster_db = Load.xml("game/monDB.xml")
		db_cache.quest_item_db = Load.xml("game/quests.xml")
#		## rooms.dat might not be used. Not sure.
		db_cache.room_db = Load.xml("game/rooms.xml").roomdb
#		# scrolls.xml didn't seem to be used
		db_cache.sound_db = Load.xml("game/soundfx.xml")
		db_cache.speech_db = Load.xml("game/speech.xml")
		db_cache.skill_db = Load.xml("game/skillDB.xml").skillDB
		db_cache.spell_db = Load.xml("game/spellDB.xml")
		db_cache.template_db = Load.xml("game/manTemplateDB.xml")
		db_cache.text_db = Load.xml("game/text.xml")
		db_cache.tutorial_db = Load.xml("game/tutorial.xml")
		db_cache.tweak_db = Load.xml("game/tweakDB.xml")

func cache(key,result):
	if result_cache == null:
		result_cache = {}
	result_cache[key] = result

func character_creation_skill_list():	
	if result_cache != null and result_cache.has('character_creation_skill_list'):
		return result_cache.character_creation_skill_list
	var result = []
	var skill_index = 0
	for skill in db_cache.skill_db.skill:
		if ! skill.has('deprecated') or int(skill.deprecated) != 1:
			result.append({
				name = skill.name,
				description = skill.description,
				icon = Load.image(skill.art.icon),
				id = skill.id,				
				index = skill_index
			})
			skill_index += 1
	cache("character_creation_skill_list",result)
	return result
	
func get_room(room_name):	
	for room in db_cache.room_db.room:
		if room.name == room_name:
			return room
