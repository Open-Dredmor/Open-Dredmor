extends Node

var db_cache = null
var result_cache = null

func ingest():
	if db_cache == null:		
		db_cache = {}
		# This loads vanilla datasets. Additional thought needed on how to manage the expansions
		db_cache.skill_db = DataIngest.skills("game/skillDB.xml")
		db_cache.crafting_recipe_db = DataIngest.crafting_recipes("game/craftDB.xml")
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
						
