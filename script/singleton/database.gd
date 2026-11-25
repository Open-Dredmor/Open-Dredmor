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
		abilities = [],
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
		if parsed.has("skillDB"):
			if parsed.skillDB.has("skill"):
				pack_data.skills = OD.DataStructure.arrayify(parsed.skillDB.skill)
			if parsed.skillDB.has("ability"):
				pack_data.abilities = OD.DataStructure.arrayify(parsed.skillDB.ability)
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
		for root_key in ["roomDB", "roomdb", "wizardRoomDB"]:
			if parsed.has(root_key) and parsed[root_key].has("room"):
				pack_data.wizard_rooms = OD.DataStructure.arrayify(parsed[root_key].room)
				break
	return pack_data

func _append_pack_into_cache(pack_data):
	cache.branches += pack_data.branches
	cache.crafts += pack_data.crafts
	cache.items += pack_data.items
	cache.monsters += pack_data.monsters
	cache.rooms += pack_data.rooms
	cache.skills += pack_data.skills
	cache.abilities += pack_data.abilities
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
	_build_item_info()
	_build_skill_info()
	_build_spell_info()
	_build_template_info()
	_build_tweak_info()
	_build_branch_info()
	_build_room_layouts()
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

		var initial_packs = OD.DungeonSettings.get_active_packs()
		if not OD.DungeonSettings.has_initialized_packs():
			initial_packs = []
			for pack_info in OD.Settings.get_available_content_packs():
				if pack_info.kind == "expansion":
					initial_packs.append(pack_info.id)
		set_active_packs(initial_packs)

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
				type = skill.type if skill.has("type") else "",
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

func _find_room_in_list(room_list, room_name):
	for room in room_list:
		if typeof(room) == TYPE_DICTIONARY and room.get("name", "") == room_name:
			return room
	return null

func get_room(room_name):
	var found = _find_room_in_list(cache.rooms, room_name)
	if found != null:
		return found
	found = _find_room_in_list(cache.wizard_rooms, room_name)
	if found != null:
		return found
	if cache.magic_box_rooms_db.has("roomdb") and cache.magic_box_rooms_db.roomdb.has("room"):
		var box_rooms = OD.DataStructure.arrayify(cache.magic_box_rooms_db.roomdb.room)
		found = _find_room_in_list(box_rooms, room_name)
		if found != null:
			return found
	return null

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
	var monster_map = result_cache["monster_info"]
	var keys = monster_map.keys()
	if keys.is_empty():
		return null
	return monster_map[keys[randi() % keys.size()]]

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
	var recipes = []
	var recipes_by_output = {}
	var recipes_by_tool = {}
	for craft in cache.crafts:
		if not craft.has('tool') or not craft.has('input'):
			continue
		# TODO I don't know if this is correct or not, but it will do for a best guess at the moment
		var kind = 'reagent' if craft.tool.tag == 'still' or craft.tool.tag == 'alchemy' else 'component'		
		var inputs = OD.DataStructure.arrayify(craft.input)
		var outputs = OD.DataStructure.arrayify(craft.output) if craft.has('output') else []
		var recipe = {
			tool = craft.tool.tag if craft.tool.has('tag') else "",
			outputs = outputs,
			inputs = inputs,
			hidden = craft.has('hidden') and int(craft.hidden) == 1,
			raw = craft
		}
		recipes.append(recipe)
		if not recipes_by_tool.has(recipe.tool):
			recipes_by_tool[recipe.tool] = []
		recipes_by_tool[recipe.tool].append(recipe)
		for output in outputs:
			if output.has('name'):
				if not recipes_by_output.has(output.name):
					recipes_by_output[output.name] = []
				recipes_by_output[output.name].append(recipe)
		for input in inputs:
			var ledger = components if kind == 'component' else reagents
			if not ledger.lookup.has(input.name):
				ledger.lookup[input.name] = true
				ledger.list.append(input.name)
	cache_result('component_list', components.list)
	cache_result('reagent_list', reagents.list)
	cache_result('craft_info', {
		recipes = recipes,
		by_output = recipes_by_output,
		by_tool = recipes_by_tool
	})

func get_all_crafts():
	if result_cache == null or not result_cache.has("craft_info"):
		return []
	return result_cache["craft_info"].recipes

func get_crafts_for_output(item_name):
	if result_cache == null or not result_cache.has("craft_info"):
		return []
	var by_output = result_cache["craft_info"].by_output
	return by_output[item_name] if by_output.has(item_name) else []

func get_crafts_by_tool(tool_tag):
	if result_cache == null or not result_cache.has("craft_info"):
		return []
	var by_tool = result_cache["craft_info"].by_tool
	return by_tool[tool_tag] if by_tool.has(tool_tag) else []

func _build_skill_info():
	var by_id = {}
	var by_name = {}
	var all_skills = []
	for skill in cache.skills:
		var skill_id = int(skill.id) if skill.has("id") else -1
		var icon_path = ""
		if skill.has("art") and typeof(skill.art) == TYPE_DICTIONARY and skill.art.has("icon"):
			icon_path = skill.art.icon
		var entry = {
			id = skill_id,
			name = skill.name if skill.has("name") else "",
			type = skill.type if skill.has("type") else "",
			description = skill.description if skill.has("description") else "",
			icon = icon_path,
			deprecated = skill.has("deprecated") and int(skill.deprecated) == 1,
			loadouts = OD.DataStructure.arrayify(skill.loadout) if skill.has("loadout") else [],
			tags = OD.DataStructure.arrayify(skill.tag) if skill.has("tag") else [],
			start_ability = null,
			levels = {},
			level_progression = [],
			raw = skill
		}
		by_id[skill_id] = entry
		if entry.name != "":
			by_name[entry.name] = entry
		all_skills.append(entry)
	for ability in cache.abilities:
		if typeof(ability) != TYPE_DICTIONARY or not ability.has("skill"):
			continue
		var skill_id = int(ability.skill)
		if not by_id.has(skill_id):
			continue
		var skill_entry = by_id[skill_id]
		if ability.has("startSkill") and int(ability.startSkill) == 1:
			skill_entry.start_ability = ability
		elif ability.has("level"):
			var level_num = int(ability.level)
			var desc = ""
			if ability.has("description") and typeof(ability.description) == TYPE_DICTIONARY and ability.description.has("text"):
				desc = ability.description.text
			var level_entry = {
				level = level_num,
				name = ability.name if ability.has("name") else "",
				icon = ability.icon if ability.has("icon") else "",
				description = desc,
				spells = OD.DataStructure.arrayify(ability.spell) if ability.has("spell") else [],
				primary_buffs = (OD.DataStructure.arrayify(ability.primarybuff) if ability.has("primarybuff") else []) + (OD.DataStructure.arrayify(ability.primaryBuff) if ability.has("primaryBuff") else []),
				secondary_buffs = (OD.DataStructure.arrayify(ability.secondarybuff) if ability.has("secondarybuff") else []) + (OD.DataStructure.arrayify(ability.secondaryBuff) if ability.has("secondaryBuff") else []),
				resist_buffs = (OD.DataStructure.arrayify(ability.resistbuff) if ability.has("resistbuff") else []) + (OD.DataStructure.arrayify(ability.resistBuff) if ability.has("resistBuff") else []),
				damage_buffs = OD.DataStructure.arrayify(ability.damagebuff) if ability.has("damagebuff") else [],
				target_hit_buffs = OD.DataStructure.arrayify(ability.targetHitEffectBuff) if ability.has("targetHitEffectBuff") else [],
				target_kill_buffs = OD.DataStructure.arrayify(ability.targetKillBuff) if ability.has("targetKillBuff") else [],
				trigger_on_cast = OD.DataStructure.arrayify(ability.triggeroncast) if ability.has("triggeroncast") else [],
				raw = ability
			}
			skill_entry.levels[level_num] = level_entry
	for skill_entry in all_skills:
		var level_keys = skill_entry.levels.keys()
		level_keys.sort()
		for level_num in level_keys:
			skill_entry.level_progression.append(skill_entry.levels[level_num])
	cache_result("skill_info", {
		by_id = by_id,
		by_name = by_name,
		list = all_skills
	})

func get_skill(skill_id_or_name):
	if result_cache == null or not result_cache.has("skill_info"):
		return null
	var info = result_cache["skill_info"]
	if typeof(skill_id_or_name) == TYPE_INT or (typeof(skill_id_or_name) == TYPE_STRING and skill_id_or_name.is_valid_int()):
		var skill_id = int(skill_id_or_name)
		return info.by_id[skill_id] if info.by_id.has(skill_id) else null
	return info.by_name[skill_id_or_name] if info.by_name.has(skill_id_or_name) else null

func get_skill_level(skill_id_or_name, level):
	var skill_entry = get_skill(skill_id_or_name)
	if skill_entry == null:
		return null
	var level_num = int(level)
	return skill_entry.levels[level_num] if skill_entry.levels.has(level_num) else null

func get_all_skills(include_deprecated = false):
	if result_cache == null or not result_cache.has("skill_info"):
		return []
	if include_deprecated:
		return result_cache["skill_info"].list
	var filtered = []
	for skill_entry in result_cache["skill_info"].list:
		if not skill_entry.deprecated:
			filtered.append(skill_entry)
	return filtered

func _build_spell_info():
	var by_name = {}
	var spell_list = []
	if cache.spell_db.has("spellDB"):
		var blocks = OD.DataStructure.arrayify(cache.spell_db.spellDB)
		for block in blocks:
			if typeof(block) == TYPE_DICTIONARY and block.has("spell"):
				var spells = OD.DataStructure.arrayify(block.spell)
				for spell in spells:
					if typeof(spell) != TYPE_DICTIONARY or not spell.has("name"):
						continue
					var desc = ""
					if spell.has("description") and typeof(spell.description) == TYPE_DICTIONARY and spell.description.has("text"):
						desc = spell.description.text
					var entry = {
						name = spell.name,
						type = spell.type if spell.has("type") else "",
						icon = spell.icon if spell.has("icon") else "",
						description = desc,
						requirements = spell.requirements if spell.has("requirements") else null,
						effects = OD.DataStructure.arrayify(spell.effect) if spell.has("effect") else [],
						buff = spell.buff if spell.has("buff") else null,
						anim = spell.anim if spell.has("anim") else null,
						wand = spell.has("wand") and int(spell.wand) == 1,
						raw = spell
					}
					by_name[entry.name] = entry
					spell_list.append(entry)
	cache_result("spell_info", {
		by_name = by_name,
		list = spell_list
	})

func get_spell(spell_name):
	if result_cache == null or not result_cache.has("spell_info"):
		return null
	var by_name = result_cache["spell_info"].by_name
	return by_name[spell_name] if by_name.has(spell_name) else null

func get_all_spells():
	if result_cache == null or not result_cache.has("spell_info"):
		return []
	return result_cache["spell_info"].list

func _build_template_info():
	var by_name = {}
	var template_list = []
	if cache.template_db.has("templatedb"):
		var blocks = OD.DataStructure.arrayify(cache.template_db.templatedb)
		for block in blocks:
			if typeof(block) == TYPE_DICTIONARY and block.has("template"):
				var templates = OD.DataStructure.arrayify(block.template)
				for tmpl in templates:
					if typeof(tmpl) != TYPE_DICTIONARY or not tmpl.has("name"):
						continue
					var rows_raw = OD.DataStructure.arrayify(tmpl.row) if tmpl.has("row") else []
					var rows = []
					var anchor = Vector2i.ZERO
					var found_anchor = false
					var raw_cells = []
					for row_idx in range(rows_raw.size()):
						var row_entry = rows_raw[row_idx]
						var row_text = str(row_entry.get("text", "")) if typeof(row_entry) == TYPE_DICTIONARY else ""
						rows.append(row_text)
						for col_idx in range(row_text.length()):
							var ch = row_text.substr(col_idx, 1)
							if ch == "#":
								anchor = Vector2i(col_idx, row_idx)
								found_anchor = true
							elif ch == "@":
								raw_cells.append(Vector2i(col_idx, row_idx))
					if not found_anchor:
						anchor = Vector2i(int(tmpl.get("width", 1)) / 2, int(tmpl.get("height", 1)) / 2)
					var affected_offsets = []
					for cell_pos in raw_cells:
						affected_offsets.append(cell_pos - anchor)
					var entry = {
						name = str(tmpl.name),
						width = int(tmpl.get("width", 1)),
						height = int(tmpl.get("height", 1)),
						affects_player = int(tmpl.get("affectsPlayer", 0)) == 1,
						rows = rows,
						anchor = anchor,
						affected_offsets = affected_offsets
					}
					by_name[entry.name] = entry
					template_list.append(entry)
	cache_result("template_info", {
		by_name = by_name,
		list = template_list
	})

func get_template(template_id):
	if result_cache == null or not result_cache.has("template_info"):
		return null
	var key = str(template_id)
	var by_name = result_cache["template_info"].by_name
	return by_name[key] if by_name.has(key) else null

func _classify_item(item, reagent_set, component_set):
	if item.has("armour"):
		var raw_slot = str(item.armour.type) if typeof(item.armour) == TYPE_DICTIONARY and item.armour.has("type") else ""
		var mapped_slot = raw_slot
		if raw_slot == "waist":
			mapped_slot = "belt"
		elif raw_slot == "shield":
			mapped_slot = "off_hand"
		elif raw_slot == "sleeve":
			mapped_slot = ""
		return { category = "armour", slot = mapped_slot }
	if item.has("weapon"):
		var weapon_type = int(item.type) if item.has("type") else -1
		var is_thrown = weapon_type == OD.GameDataKind.WEAPON.THROWN or (typeof(item.weapon) == TYPE_DICTIONARY and item.weapon.has("thrown"))
		if weapon_type == OD.GameDataKind.WEAPON.BOLT:
			return { category = "bolts", slot = "bolts" }
		if is_thrown:
			return { category = "thrown", slot = "thrown" }
		if weapon_type == OD.GameDataKind.WEAPON.BOW:
			return { category = "weapon", slot = "missile_weapon" }
		return { category = "weapon", slot = "weapon" }
	if item.has("food"):
		return { category = "food", slot = "" }
	if item.has("potion"):
		return { category = "potion", slot = "" }
	if item.has("wand"):
		return { category = "wand", slot = "" }
	if item.has("toolkit"):
		return { category = "toolkit", slot = "" }
	if item.has("artifact"):
		return { category = "artifact", slot = "" }
	if item.has("trap"):
		return { category = "trap", slot = "" }
	if item.has("name"):
		if reagent_set.has(item.name):
			return { category = "reagent", slot = "" }
		if component_set.has(item.name):
			return { category = "component", slot = "" }
	return { category = "misc", slot = "" }

func _build_item_info():
	var by_name = {}
	var by_category = {}
	var item_list = []
	var reagent_set = {}
	var component_set = {}
	if result_cache != null and result_cache.has("reagent_list"):
		for reagent_name in result_cache["reagent_list"]:
			reagent_set[reagent_name] = true
	if result_cache != null and result_cache.has("component_list"):
		for component_name in result_cache["component_list"]:
			component_set[component_name] = true
	for item in cache.items:
		if typeof(item) != TYPE_DICTIONARY or not item.has("name"):
			continue
		var classification = _classify_item(item, reagent_set, component_set)
		var desc = ""
		if item.has("description") and typeof(item.description) == TYPE_DICTIONARY and item.description.has("text"):
			desc = item.description.text
		var effects = []
		for effect_key in ["effect", "primarybuff", "secondarybuff", "resistbuff", "damagebuff", "targetHitEffectBuff", "castSpell"]:
			if item.has(effect_key):
				for effect_entry in OD.DataStructure.arrayify(item[effect_key]):
					effects.append({ kind = effect_key, data = effect_entry })
		var entry = {
			name = item.name,
			category = classification.category,
			slot = classification.slot,
			type = int(item.type) if item.has("type") else -1,
			level = int(item.level) if item.has("level") else 1,
			icon = item.iconFile if item.has("iconFile") else "",
			price = int(item.price.amount) if item.has("price") and typeof(item.price) == TYPE_DICTIONARY and item.price.has("amount") else 0,
			description = desc,
			effects = effects,
			raw = item
		}
		by_name[entry.name] = entry
		if not by_category.has(entry.category):
			by_category[entry.category] = []
		by_category[entry.category].append(entry)
		item_list.append(entry)
	cache_result("item_info", {
		by_name = by_name,
		by_category = by_category,
		list = item_list
	})

func get_item(item_name):
	if result_cache == null or not result_cache.has("item_info"):
		return null
	var by_name = result_cache["item_info"].by_name
	return by_name[item_name] if by_name.has(item_name) else null

func get_items_by_category(category):
	if result_cache == null or not result_cache.has("item_info"):
		return []
	var by_category = result_cache["item_info"].by_category
	return by_category[category] if by_category.has(category) else []

func get_all_items():
	if result_cache == null or not result_cache.has("item_info"):
		return []
	return result_cache["item_info"].list

const ITEM_DAMAGE_TYPES = [
	"acidic", "aethereal", "asphyxiative", "blasting",
	"conflagratory", "crushing", "existential", "hyperborean",
	"necromantic", "piercing", "putrefying", "righteous",
	"slashing", "toxic", "transmutative", "voltaic"
]

const STACKABLE_ITEM_CATEGORIES = [
	"food", "potion", "mushroom", "gem", "reagent",
	"component", "trap", "bolts", "thrown", "misc"
]

func _extract_item_tag_array(raw_item, lower_key, camel_key):
	var collected = []
	if raw_item.has(lower_key):
		collected.append_array(OD.DataStructure.arrayify(raw_item.get(lower_key)))
	if raw_item.has(camel_key):
		collected.append_array(OD.DataStructure.arrayify(raw_item.get(camel_key)))
	return collected

func create_item_instance(item_name_or_def, count = 1):
	var item_def = null
	if typeof(item_name_or_def) == TYPE_STRING:
		item_def = get_item(item_name_or_def)
	elif typeof(item_name_or_def) == TYPE_DICTIONARY:
		if item_name_or_def.has("raw"):
			item_def = item_name_or_def
		elif item_name_or_def.has("name"):
			item_def = get_item(str(item_name_or_def.name))
	if item_def == null:
		return null
	var raw_item = item_def.get("raw", {})
	var category = str(item_def.get("category", "misc"))
	var max_stack = 1
	if category in STACKABLE_ITEM_CATEGORIES:
		max_stack = max(2, int(raw_item.get("maxstack", 99)))
	var clamped_count = clamp(int(count), 1, max_stack)

	var weapon_damage = {}
	var raw_weapon = raw_item.get("weapon", null)
	if typeof(raw_weapon) == TYPE_DICTIONARY:
		for dmg_type in ITEM_DAMAGE_TYPES:
			if raw_weapon.has(dmg_type):
				var dmg_val = int(raw_weapon[dmg_type])
				if dmg_val != 0:
					weapon_damage[dmg_type] = dmg_val

	var primary_buffs = []
	for entry in _extract_item_tag_array(raw_item, "primarybuff", "primaryBuff"):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			primary_buffs.append({ id = int(entry.id), amount = int(entry.get("amount", 0)) })

	var secondary_buffs = []
	for entry in _extract_item_tag_array(raw_item, "secondarybuff", "secondaryBuff"):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			secondary_buffs.append({ id = int(entry.id), amount = int(entry.get("amount", 0)) })

	var resist_buffs = {}
	for entry in _extract_item_tag_array(raw_item, "resistbuff", "resistBuff"):
		if typeof(entry) == TYPE_DICTIONARY:
			for dmg_type in ITEM_DAMAGE_TYPES:
				if entry.has(dmg_type):
					resist_buffs[dmg_type] = int(resist_buffs.get(dmg_type, 0)) + int(entry[dmg_type])

	var damage_buffs = {}
	for entry in _extract_item_tag_array(raw_item, "damagebuff", "damageBuff"):
		if typeof(entry) == TYPE_DICTIONARY:
			for dmg_type in ITEM_DAMAGE_TYPES:
				if entry.has(dmg_type):
					damage_buffs[dmg_type] = int(damage_buffs.get(dmg_type, 0)) + int(entry[dmg_type])

	var target_hit_effects = []
	for entry in _extract_item_tag_array(raw_item, "targethiteffectbuff", "targetHitEffectBuff"):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("name"):
			target_hit_effects.append({
				name = str(entry.name),
				percentage = int(entry.get("percentage", 100))
			})

	var player_hit_effects = []
	for entry in _extract_item_tag_array(raw_item, "playerhiteffectbuff", "playerHitEffectBuff"):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("name"):
			player_hit_effects.append({
				name = str(entry.name),
				percentage = int(entry.get("percentage", 100))
			})

	var base_price = int(item_def.get("price", 0))
	var sell_scaler = float(get_tweak("store sell price scaler", 0.63))
	var sell_price = max(1, int(round(float(base_price) * sell_scaler))) if base_price > 0 else 0

	var instance = {
		name = str(item_def.get("name", "Unknown Item")),
		category = category,
		slot = str(item_def.get("slot", "")),
		type = int(item_def.get("type", -1)),
		level = int(item_def.get("level", 1)),
		icon = str(item_def.get("icon", "")),
		price = base_price,
		sell_price = sell_price,
		description = str(item_def.get("description", "")),
		count = clamped_count,
		max_stack = max_stack,
		weapon_damage = weapon_damage,
		primary_buffs = primary_buffs,
		secondary_buffs = secondary_buffs,
		resist_buffs = resist_buffs,
		damage_buffs = damage_buffs,
		target_hit_effects = target_hit_effects,
		player_hit_effects = player_hit_effects
	}
	for dmg_type in weapon_damage:
		instance[dmg_type] = weapon_damage[dmg_type]
	return instance

func get_trap(trap_name = null, max_level = 99):
	if trap_name != null and trap_name != "":
		var named = get_item(trap_name)
		if named != null and named.category == "trap":
			return named
	var traps = get_items_by_category("trap")
	if traps.is_empty():
		return null
	var eligible = []
	for trap_entry in traps:
		if trap_entry.level <= max_level:
			eligible.append(trap_entry)
	if eligible.is_empty():
		return traps[randi() % traps.size()]
	return eligible[randi() % eligible.size()]

func _build_tweak_info():
	var tweaks = {}
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
	cache_result("tweak_info", tweaks)

func get_tweak(tweak_name, default_value = null):
	if result_cache == null or not result_cache.has("tweak_info"):
		return default_value
	var tweaks = result_cache["tweak_info"]
	return tweaks[tweak_name] if tweaks.has(tweak_name) else default_value

func get_all_tweaks():
	if result_cache == null or not result_cache.has("tweak_info"):
		return {}
	return result_cache["tweak_info"]

func _build_branch_info():
	var by_id = {}
	var by_name = {}
	var branch_list = []
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
		by_id[branch_id] = entry
		if entry.name != "":
			by_name[entry.name] = entry
		branch_list.append(entry)
	cache_result("branch_info", {
		by_id = by_id,
		by_name = by_name,
		list = branch_list
	})

func get_branch_info(branch_id_or_name):
	if result_cache == null or not result_cache.has("branch_info"):
		return null
	var info = result_cache["branch_info"]
	if typeof(branch_id_or_name) == TYPE_INT or (typeof(branch_id_or_name) == TYPE_STRING and branch_id_or_name.is_valid_int()):
		var branch_id = int(branch_id_or_name)
		return info.by_id[branch_id] if info.by_id.has(branch_id) else null
	return info.by_name[branch_id_or_name] if info.by_name.has(branch_id_or_name) else null

func get_all_branches():
	if result_cache == null or not result_cache.has("branch_info"):
		return []
	return result_cache["branch_info"].list

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
	for row_idx in range(grid_height):
		var row_text = rows[row_idx].text
		for col_idx in range(min(grid_width, row_text.length())):
			var tile_char = row_text[col_idx]
			if tile_char == ".":
				floor_cells.append(Vector2i(col_idx, row_idx))
			elif tile_char == "d":
				if col_idx < grid_width / 2:
					doors.left.append({ x = col_idx, y = row_idx, kind = "left" })
				else:
					doors.right.append({ x = col_idx, y = row_idx, kind = "right" })
			elif tile_char == "D":
				if row_idx < grid_height / 2:
					doors.up.append({ x = col_idx, y = row_idx, kind = "up" })
				else:
					doors.down.append({ x = col_idx, y = row_idx, kind = "down" })
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

func _build_room_layouts():
	var by_name = {}
	var layouts = []
	for room in cache.rooms:
		var layout = _parse_room_layout(room)
		if layout == null:
			continue
		layout.id = layouts.size()
		by_name[layout.name] = layout
		layouts.append(layout)
	var wizard_layouts = []
	for wizard_room in cache.wizard_rooms:
		var wizard_layout = _parse_room_layout(wizard_room)
		if wizard_layout != null:
			wizard_layouts.append(wizard_layout)
	var magic_box_layouts = []
	if cache.magic_box_rooms_db.has("roomdb") and cache.magic_box_rooms_db.roomdb.has("room"):
		for box_room in OD.DataStructure.arrayify(cache.magic_box_rooms_db.roomdb.room):
			var box_layout = _parse_room_layout(box_room)
			if box_layout != null:
				magic_box_layouts.append(box_layout)
	cache_result("room_layouts", {
		by_name = by_name,
		list = layouts,
		wizard_list = wizard_layouts,
		magic_box_list = magic_box_layouts
	})

func get_wizard_room_layouts():
	if result_cache == null or not result_cache.has("room_layouts"):
		return []
	return result_cache["room_layouts"].wizard_list

func get_magic_box_layouts():
	if result_cache == null or not result_cache.has("room_layouts"):
		return []
	return result_cache["room_layouts"].magic_box_list

func get_room_layout(room_name):
	if result_cache == null or not result_cache.has("room_layouts"):
		return null
	var by_name = result_cache["room_layouts"].by_name
	return by_name[room_name] if by_name.has(room_name) else null

func get_room_layouts_for_floor(floor_index):
	if result_cache == null or not result_cache.has("room_layouts"):
		return []
	var eligible = []
	for layout in result_cache["room_layouts"].list:
		if layout.min_level <= floor_index and layout.max_level >= floor_index:
			eligible.append(layout)
	return eligible

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
