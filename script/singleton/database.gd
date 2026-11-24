extends Node

var cache = null
var result_cache = null
var packs = null
var _active_pack_ids = []
var _active_pack_prefixes = []

func _empty_pack_data():
	return {
		branches = [],
		crafts = [],
		items = [],
		magic_box_rooms_db = {},
		monsters = [],
		quest_item_db = {},
		rooms = [],
		sound_db = {},
		speech_db = {},
		skills = [],
		spell_db = {},
		template_db = {},
		text = {},
		tutorial_db = {},
		tweak_db = {},
		encrusts = [],
		wizard_rooms = []
	}

func _load_pack_data(base_path):
	var pack_data = _empty_pack_data()
	if OD.Load.exists(base_path + "branchDB.xml"):
		var parsed = OD.Load.xml(base_path + "branchDB.xml")
		if parsed.has("branchDB") and parsed.branchDB.has("branch"):
			pack_data.branches = OD.DataStructure.arrayify(parsed.branchDB.branch)
	if OD.Load.exists(base_path + "craftDB.xml"):
		var parsed = OD.Load.xml(base_path + "craftDB.xml")
		if parsed.has("craftDB") and parsed.craftDB.has("craft"):
			pack_data.crafts = OD.DataStructure.arrayify(parsed.craftDB.craft)
	if OD.Load.exists(base_path + "itemDB.xml"):
		var parsed = OD.Load.xml(base_path + "itemDB.xml")
		if parsed.has("itemDB") and parsed.itemDB.has("item"):
			pack_data.items = OD.DataStructure.arrayify(parsed.itemDB.item)
	if OD.Load.exists(base_path + "magicBoxRooms.xml"):
		pack_data.magic_box_rooms_db = OD.Load.xml(base_path + "magicBoxRooms.xml")
	if OD.Load.exists(base_path + "monDB.xml"):
		var parsed = OD.Load.xml(base_path + "monDB.xml")
		if parsed.has("monDB") and parsed.monDB.has("monster"):
			pack_data.monsters = OD.DataStructure.arrayify(parsed.monDB.monster)
	if OD.Load.exists(base_path + "quests.xml"):
		pack_data.quest_item_db = OD.Load.xml(base_path + "quests.xml")
	if OD.Load.exists(base_path + "rooms.xml"):
		var parsed = OD.Load.xml(base_path + "rooms.xml")
		if parsed.has("roomdb") and parsed.roomdb.has("room"):
			pack_data.rooms = OD.DataStructure.arrayify(parsed.roomdb.room)
	if OD.Load.exists(base_path + "soundfx.xml"):
		pack_data.sound_db = OD.Load.xml(base_path + "soundfx.xml")
	if OD.Load.exists(base_path + "speech.xml"):
		pack_data.speech_db = OD.Load.xml(base_path + "speech.xml")
	if OD.Load.exists(base_path + "skillDB.xml"):
		var parsed = OD.Load.xml(base_path + "skillDB.xml")
		if parsed.has("skillDB") and parsed.skillDB.has("skill"):
			pack_data.skills = OD.DataStructure.arrayify(parsed.skillDB.skill)
	if OD.Load.exists(base_path + "spellDB.xml"):
		pack_data.spell_db = OD.Load.xml(base_path + "spellDB.xml")
	if OD.Load.exists(base_path + "manTemplateDB.xml"):
		pack_data.template_db = OD.Load.xml(base_path + "manTemplateDB.xml")
	if OD.Load.exists(base_path + "text.xml"):
		var parsed = OD.Load.xml(base_path + "text.xml")
		if parsed.has("text"):
			pack_data.text = parsed.text
	if OD.Load.exists(base_path + "tutorial.xml"):
		pack_data.tutorial_db = OD.Load.xml(base_path + "tutorial.xml")
	if OD.Load.exists(base_path + "tweakDB.xml"):
		pack_data.tweak_db = OD.Load.xml(base_path + "tweakDB.xml")
	if OD.Load.exists(base_path + "encrustDB.xml"):
		var parsed = OD.Load.xml(base_path + "encrustDB.xml")
		if parsed.has("encrustDB") and parsed.encrustDB.has("encrust"):
			pack_data.encrusts = OD.DataStructure.arrayify(parsed.encrustDB.encrust)
	if OD.Load.exists(base_path + "wizardRoomDB.xml"):
		var parsed = OD.Load.xml(base_path + "wizardRoomDB.xml")
		if parsed.has("wizardRoomDB") and parsed.wizardRoomDB.has("room"):
			pack_data.wizard_rooms = OD.DataStructure.arrayify(parsed.wizardRoomDB.room)
	return pack_data

func _append_pack_into_cache(pack_data):
	cache.branches += pack_data.branches
	cache.crafts += pack_data.crafts
	cache.items += pack_data.items
	cache.monsters += pack_data.monsters
	cache.rooms += pack_data.rooms
	cache.skills += pack_data.skills
	cache.encrusts += pack_data.encrusts
	cache.wizard_rooms += pack_data.wizard_rooms
	cache.magic_box_rooms_db = OD.DataStructure.merge(cache.magic_box_rooms_db, pack_data.magic_box_rooms_db)
	cache.quest_item_db = OD.DataStructure.merge(cache.quest_item_db, pack_data.quest_item_db)
	cache.sound_db = OD.DataStructure.merge(cache.sound_db, pack_data.sound_db)
	cache.speech_db = OD.DataStructure.merge(cache.speech_db, pack_data.speech_db)
	cache.spell_db = OD.DataStructure.merge(cache.spell_db, pack_data.spell_db)
	cache.template_db = OD.DataStructure.merge(cache.template_db, pack_data.template_db)
	cache.text = OD.DataStructure.merge(cache.text, pack_data.text)
	cache.tutorial_db = OD.DataStructure.merge(cache.tutorial_db, pack_data.tutorial_db)
	cache.tweak_db = OD.DataStructure.merge(cache.tweak_db, pack_data.tweak_db)

func set_active_packs(pack_ids = []):
	if packs == null:
		ingest()
	_active_pack_ids = pack_ids.duplicate()
	_active_pack_prefixes = []
	OD.DungeonSettings.set_active_packs(_active_pack_ids)
	cache = _empty_pack_data()
	_append_pack_into_cache(packs["vanilla"])
	var available_by_id = {}
	for pack_info in OD.Settings.get_available_content_packs():
		available_by_id[pack_info.id] = pack_info
	for pack_id in _active_pack_ids:
		if packs.has(pack_id):
			_append_pack_into_cache(packs[pack_id])
		if available_by_id.has(pack_id):
			_active_pack_prefixes.append(available_by_id[pack_id].prefix)
	result_cache = null
	_build_loot_info()
	_build_craft_info()
	_build_monster_info()
	_build_sound_info()

func get_available_packs():
	return OD.Settings.get_available_content_packs()

func get_active_packs():
	return _active_pack_ids

func get_active_pack_prefixes():
	return _active_pack_prefixes

func ingest():
	if packs == null:
		packs = {}
		print("Ingesting vanilla game data")
		# monDB.xml explains that branches are a feature scrapped during development
		# However, the expansions have them...so what could they be?
		# They seem like tilemap definitions.
		## manual.xml was next to empty, consider it a placeholder
		## rooms.dat might not be used. Not sure.
		# scrolls.xml didn't seem to be used
		packs["vanilla"] = _load_pack_data("game/")

		for pack_info in OD.Settings.get_available_content_packs():
			print("Ingesting content pack [" + pack_info.id + "] from " + pack_info.prefix)
			packs[pack_info.id] = _load_pack_data(pack_info.prefix + pack_info.data_subdir)

		set_active_packs(OD.DungeonSettings.get_active_packs())

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
				icon = OD.Load.image(skill.art.icon),
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
		var room = OD.DataStructure.choose(cache.rooms, 1)
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
	return OD.DataStructure.choose(rooms, 1).name

func get_room(room_name):	
	for room in cache.rooms:
		if room.name == room_name:
			return room

func create_room_name():
	# DEBUG - Cake has a custom blocker
#	for noun in lookup.noun:
#		if noun.text == "Cake":
#			noun = noun
	var noun = OD.DataStructure.choose(cache.text.noun, 1)
	var adjective = OD.DataStructure.choose(cache.text.adjective, 1)
	var architecture = OD.DataStructure.choose(cache.text.architecture, 1)
	
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
			var children = OD.DataStructure.arrayify(monster.monster)
			for child in children:
				monsters[child.name] = OD.DataStructure.merge(monster, child)			
	cache_result("monster_info", monsters)

func get_random_monster():
	return OD.DataStructure.choose(result_cache["monster_info"])

func get_monster(name):		
	if not result_cache["monster_info"].has(name):
		return null
	return result_cache["monster_info"][name]
	
func _build_loot_info():
	var loot = {
		armour = [],
		artifact = [],
		bolts = [],
		component = [],
		food = [],
		misc = [],
		potion = [],
		reagent = [],
		toolkit = [],
		wand = [],
		weapon = [],
		_find_by_name = {}
	}
	var prop_driven_loot = [
		'armour',		
		'artifact',
		'food',
		'potion',		
		'wand',
		'weapon'
	]
	for item in cache.items:
		loot._find_by_name[item.name] = item
		for prop in prop_driven_loot:
			if item.has(prop):
				if prop == 'weapon' and item.has('type') and int(item.type) == OD.GameDataKind.WEAPON.BOLT:
					loot.bolts.append(item)
				else:
					loot[prop].append(item)
	# TODO
	# component and reagent are different categories of crafting ingredients.
	# research how to tell the difference between kinds of crafting input
	# It only matters when no subtype is provided (like in Small Alchemy Lab room)
	cache_result("loot_info", loot)

func get_loot(loot_kind, loot_sub_kind = null):
	var lookup = result_cache['loot_info']
	if loot_sub_kind != null:
		if lookup.has('_find_by_name') and lookup._find_by_name.has(loot_sub_kind):
			return lookup._find_by_name[loot_sub_kind]
		return null
	if loot_kind == 'component':
		return lookup._find_by_name[OD.DataStructure.choose(result_cache.component_list)]
	if loot_kind == 'reagent':
		return lookup._find_by_name[OD.DataStructure.choose(result_cache.reagent_list)]
	if not lookup.has(loot_kind):
		return null
	return OD.DataStructure.choose(lookup[loot_kind], 1)
	
func _build_craft_info():
	var reagents = {
		lookup = {},
		list = []
	}
	var components = {
		lookup = {},
		list = []
	}
	for craft in cache.crafts:
		if not craft.has('tool') or not craft.has('input'):
			continue
		# TODO I don't know if this is correct or not, but it will do for a best guess at the moment
		var kind = 'reagent' if craft.tool.tag == 'still' or craft.tool.tag == 'alchemy' else 'component'		
		var inputs = OD.DataStructure.arrayify(craft.input)
		for input in inputs:
			var ledger = components if kind == 'component' else reagents
			if not ledger.lookup.has(input.name):
				ledger.lookup[input.name] = true
				ledger.list.append(input.name)
	cache_result('component_list', components.list)
	cache_result('reagent_list', reagents.list)

func _build_sound_info():
	var sounds = {}
	if cache.sound_db.has("sounds"):
		var sound_blocks = OD.DataStructure.arrayify(cache.sound_db.sounds)
		for block in sound_blocks:
			if typeof(block) == TYPE_DICTIONARY and block.has("sound"):
				var entries = OD.DataStructure.arrayify(block.sound)
				for entry in entries:
					if typeof(entry) == TYPE_DICTIONARY and entry.has("name") and entry.has("wave"):
						sounds[entry.name] = entry.wave
	cache_result("sound_info", sounds)

func get_sound_path(cue_name):
	if result_cache == null or not result_cache.has("sound_info"):
		return null
	if result_cache["sound_info"].has(cue_name):
		return result_cache["sound_info"][cue_name]
	return null

func get_sound_cues():
	if result_cache == null or not result_cache.has("sound_info"):
		return []
	var cues = result_cache["sound_info"].keys()
	cues.sort()
	return cues
