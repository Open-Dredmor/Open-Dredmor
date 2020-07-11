extends Node

var cache = null

func ingest():
	if cache == null:		
		cache = {}
		var skills = DataIngest.skills("game/skillDB.xml")
		print(skills)
						
