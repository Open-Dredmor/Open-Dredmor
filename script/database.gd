extends Node

var db_cache = null
var result_cache = null

func ingest():
	if db_cache == null:		
		# This loads vanilla datasets. Additional thought needed on how to manage the expansions
		db_cache = {}
		# monDB.xml explains that branches are a feature scrapped during development
		#db_cache.branch_db = DataIngest.branches("game/branchDB.xml")
		db_cache.crafting_recipe_db = DataIngest.xml("game/craftDB.xml")
		db_cache.item_db = DataIngest.xml("game/itemDB.xml")
		db_cache.magic_box_rooms_db = DataIngest.xml("game/magicBoxRooms.xml")
		## manual.xml was next to empty, consider it a placeholder
		db_cache.monster_db = DataIngest.xml("game/monDB.xml")
		db_cache.quest_item_db = DataIngest.xml("game/quests.xml")
#		## rooms.dat might not be used. Not sure.
		db_cache.room_db = DataIngest.xml("game/rooms.xml")		
#		# scrolls.xml didn't seem to be used
		db_cache.sound_db = DataIngest.xml("game/soundfx.xml")
		db_cache.speech_db = DataIngest.xml("game/speech.xml")
		db_cache.skill_db = DataIngest.xml("game/skillDB.xml")
		db_cache.spell_db = DataIngest.xml("game/spellDB.xml")
		db_cache.template_db = DataIngest.xml("game/manTemplateDB.xml")
		db_cache.text_db = DataIngest.xml("game/text.xml")
		db_cache.tutorial_db = DataIngest.xml("game/tutorial.xml")
		db_cache.tweak_db = DataIngest.xml("game/tweakDB.xml")
		print("Database files ingested")

func cache(key,result):
	if result_cache == null:
		result_cache = {}
	result_cache[key] = result

func character_creation_skill_list():	
	if result_cache != null and result_cache.has('character_creation_skill_list'):
		return result_cache.character_creation_skill_list
	var result = []
	var skill = null
	for skill_id in db_cache.skill_db.skill.list:
		skill = db_cache.skill_db.skill.lookup[skill_id]
		result.append({
			name = skill.name,
			description = skill.description,
			icon = Load.image(skill.art.icon)
		})
	cache("character_creation_skill_list",result)
	return result
