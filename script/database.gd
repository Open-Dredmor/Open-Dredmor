extends Node

var db_cache = null
var result_cache = null

func ingest():
	if db_cache == null:		
		db_cache = {}
		db_cache.skill_db = DataIngest.skills("game/skillDB.xml")

func cache(key,result):
	if result_cache == null:
		result_cache = {}
	result_cache[key] = result

func character_creation_skill_list():	
	if result_cache != null and result_cache.has('character_creation_skill_list'):
		return result_cache.character_creation_skill_list
	var result = []
	var skill = null
	for skill_id in db_cache.skill_db.skills.list:
		skill = db_cache.skill_db.skills.lookup[skill_id]
		result.append({
			name = skill.name,
			description = skill.description,
			icon = Load.image(skill.art.icon)
		})
	cache("character_creation_skill_list",result)
	return result
						
