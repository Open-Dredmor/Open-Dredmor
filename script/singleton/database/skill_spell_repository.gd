extends RefCounted

var skills_by_id = {}
var skills_by_name = {}
var skill_list = []
var spells_by_name = {}
var spell_list = []
var templates_by_name = {}
var template_list = []

func build(cache):
	_build_skills(cache)
	_build_spells(cache)
	_build_templates(cache)

func _build_skills(cache):
	skills_by_id = {}
	skills_by_name = {}
	skill_list = []
	var pack_skill_id_map = {}
	var next_remapped_id = 10000
	for skill in cache.skills:
		if typeof(skill) != TYPE_DICTIONARY:
			continue
		var raw_id = int(skill.id) if skill.has("id") else -1
		var pack_id = str(skill.get("_pack_id", "vanilla"))
		var effective_id = raw_id
		if skills_by_id.has(effective_id):
			while skills_by_id.has(next_remapped_id):
				next_remapped_id += 1
			effective_id = next_remapped_id
			next_remapped_id += 1
			push_warning("Skill ID collision for id=" + str(raw_id) + " in pack [" + pack_id + "]; remapped to " + str(effective_id))
		if not pack_skill_id_map.has(pack_id):
			pack_skill_id_map[pack_id] = {}
		pack_skill_id_map[pack_id][raw_id] = effective_id
		var icon_path = ""
		if skill.has("art") and typeof(skill.art) == TYPE_DICTIONARY and skill.art.has("icon"):
			icon_path = skill.art.icon
		var entry = {
			id = effective_id,
			raw_id = raw_id,
			pack_id = pack_id,
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
		skills_by_id[effective_id] = entry
		if entry.name != "":
			skills_by_name[entry.name] = entry
		skill_list.append(entry)

	for ability in cache.abilities:
		if typeof(ability) != TYPE_DICTIONARY or not ability.has("skill"):
			continue
		var pack_id = str(ability.get("_pack_id", "vanilla"))
		var raw_skill_id = int(ability.skill)
		var target_id = raw_skill_id
		if pack_skill_id_map.has(pack_id) and pack_skill_id_map[pack_id].has(raw_skill_id):
			target_id = pack_skill_id_map[pack_id][raw_skill_id]
		if not skills_by_id.has(target_id):
			continue
		var skill_entry = skills_by_id[target_id]
		if ability.has("startSkill") and int(ability.startSkill) == 1:
			skill_entry.start_ability = ability
		elif ability.has("level"):
			var level_number = int(ability.level)
			var desc = ""
			if ability.has("description") and typeof(ability.description) == TYPE_DICTIONARY and ability.description.has("text"):
				desc = ability.description.text
			var level_entry = {
				level = level_number,
				name = ability.name if ability.has("name") else "",
				icon = ability.icon if ability.has("icon") else "",
				description = desc,
				spells = OD.DataStructure.arrayify(ability.spell) if ability.has("spell") else [],
				primary_buffs = OD.DataStructure.arrayify(ability.primarybuff) if ability.has("primarybuff") else [],
				secondary_buffs = OD.DataStructure.arrayify(ability.secondarybuff) if ability.has("secondarybuff") else [],
				resist_buffs = OD.DataStructure.arrayify(ability.resistbuff) if ability.has("resistbuff") else [],
				damage_buffs = OD.DataStructure.arrayify(ability.damagebuff) if ability.has("damagebuff") else [],
				target_hit_buffs = OD.DataStructure.arrayify(ability.targethiteffectbuff) if ability.has("targethiteffectbuff") else [],
				target_kill_buffs = OD.DataStructure.arrayify(ability.targetkillbuff) if ability.has("targetkillbuff") else [],
				trigger_on_cast = OD.DataStructure.arrayify(ability.triggeroncast) if ability.has("triggeroncast") else [],
				raw = ability
			}
			skill_entry.levels[level_number] = level_entry

	for skill_entry in skill_list:
		var level_keys = skill_entry.levels.keys()
		level_keys.sort()
		for level_number in level_keys:
			skill_entry.level_progression.append(skill_entry.levels[level_number])

func get_skill(skill_id_or_name):
	if typeof(skill_id_or_name) == TYPE_INT or (typeof(skill_id_or_name) == TYPE_STRING and skill_id_or_name.is_valid_int()):
		var skill_id = int(skill_id_or_name)
		return skills_by_id[skill_id] if skills_by_id.has(skill_id) else null
	return skills_by_name[skill_id_or_name] if skills_by_name.has(skill_id_or_name) else null

func get_skill_level(skill_id_or_name, level):
	var skill_entry = get_skill(skill_id_or_name)
	if skill_entry == null:
		return null
	var level_number = int(level)
	return skill_entry.levels[level_number] if skill_entry.levels.has(level_number) else null

func get_all_skills(include_deprecated = false):
	if include_deprecated:
		return skill_list
	var filtered = []
	for skill_entry in skill_list:
		if not skill_entry.deprecated:
			filtered.append(skill_entry)
	return filtered

func _build_spells(cache):
	spells_by_name = {}
	spell_list = []
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
					spells_by_name[entry.name] = entry
	spell_list = spells_by_name.values()

func get_spell(spell_name):
	return spells_by_name[spell_name] if spells_by_name.has(spell_name) else null

func _build_templates(cache):
	templates_by_name = {}
	template_list = []
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
					var grid_width = 0
					for row_index in range(rows_raw.size()):
						var row_text = str(rows_raw[row_index].get("text", "")) if typeof(rows_raw[row_index]) == TYPE_DICTIONARY else str(rows_raw[row_index])
						rows.append(row_text)
						if row_text.length() > grid_width:
							grid_width = row_text.length()
						var at_col = row_text.find("@")
						if at_col != -1 and not found_anchor:
							anchor = Vector2i(at_col, row_index)
							found_anchor = true
					var offsets = []
					for row_index in range(rows.size()):
						var row_text = rows[row_index]
						for col_index in range(row_text.length()):
							var tile_char = row_text[col_index]
							if tile_char == "#" or tile_char == "@":
								offsets.append(Vector2i(col_index - anchor.x, row_index - anchor.y))
					var entry = {
						name = tmpl.name,
						width = grid_width,
						height = rows.size(),
						anchor = anchor,
						offsets = offsets,
						affectscaster = tmpl.has("affectscaster") and int(tmpl.affectscaster) == 1,
						raw = tmpl
					}
					templates_by_name[entry.name] = entry
	template_list = templates_by_name.values()

func get_template(template_name):
	return templates_by_name[template_name] if templates_by_name.has(template_name) else null
