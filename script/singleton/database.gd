extends Node

const PackLoader = preload("res://script/singleton/database/pack_loader.gd")
const ItemRepository = preload("res://script/singleton/database/item_repository.gd")
const ItemFactory = preload("res://script/singleton/database/item_factory.gd")
const SkillSpellRepository = preload("res://script/singleton/database/skill_spell_repository.gd")
const WorldRepository = preload("res://script/singleton/database/world_repository.gd")

var _pack_loader = PackLoader.new()
var _item_repo = ItemRepository.new()
var _skill_spell_repo = SkillSpellRepository.new()
var _world_repo = WorldRepository.new()

var cache:
	get:
		return _pack_loader.cache

var packs:
	get:
		return _pack_loader.packs

var result_cache = null

func _rebuild_repositories():
	result_cache = {}
	_item_repo.build(_pack_loader.cache, _world_repo)
	_skill_spell_repo.build(_pack_loader.cache)
	_world_repo.build(_pack_loader.cache)

func set_active_packs(pack_ids = []):
	_pack_loader.apply_active_packs(pack_ids)
	_rebuild_repositories()

func get_available_packs():
	return OD.Settings.get_available_content_packs()

func get_active_packs():
	return _pack_loader.active_pack_ids

func get_active_pack_prefixes():
	return _pack_loader.active_pack_prefixes

func get_active_pack_roots():
	return _pack_loader.active_pack_roots

func ingest():
	if _pack_loader.packs == null:
		_pack_loader.ensure_vanilla_loaded()
		set_active_packs(_pack_loader.default_initial_packs())

func ingest_async(start_percent = 10.0, end_percent = 70.0):
	if _pack_loader.packs != null:
		return
	if OD.Loading != null:
		await OD.Loading.step("Ingesting base game XML data...", start_percent)
	_pack_loader.ensure_vanilla_loaded()
	var initial_packs = _pack_loader.default_initial_packs()
	var available_by_id = {}
	for pack_info in OD.Settings.get_available_content_packs():
		available_by_id[pack_info.id] = pack_info
	var total_steps = max(1, initial_packs.size() + 1)
	var percent_span = end_percent - start_percent
	for step_index in range(initial_packs.size()):
		var pack_id = initial_packs[step_index]
		var pack_info = available_by_id.get(pack_id, {})
		var percent = start_percent + percent_span * (float(step_index + 1) / float(total_steps))
		if OD.Loading != null:
			await OD.Loading.step("Ingesting " + str(pack_info.get("name", pack_id)) + "...", percent)
		_pack_loader.get_or_load_pack(pack_id, available_by_id)
	if OD.Loading != null:
		await OD.Loading.step("Building database indexes...", end_percent)
	set_active_packs(initial_packs)

func character_creation_skill_list():
	if result_cache != null and result_cache.has("character_creation_skill_list"):
		return result_cache["character_creation_skill_list"]
	var result = []
	var skill_index = 0
	for skill in _skill_spell_repo.get_all_skills(false):
		result.append({
			name = skill.name,
			description = skill.description,
			type = skill.type,
			icon = OD.Load.image(skill.icon),
			id = skill.id,
			pack_id = skill.pack_id,
			index = skill_index
		})
		skill_index += 1
	result_cache["character_creation_skill_list"] = result
	return result

func random_room_id(floor_level):
	var eligible = get_room_layouts_for_floor(floor_level)
	if eligible.is_empty():
		return null
	return eligible[randi() % eligible.size()].name

func precompute_room_info():
	for room in _pack_loader.cache.rooms:
		if typeof(room) == TYPE_DICTIONARY and room.has("row"):
			var rows = OD.DataStructure.arrayify(room.row)
			room.width = rows[0].text.length() if not rows.is_empty() and rows[0].has("text") else 0
			room.height = rows.size()

func get_room_within(floor_level, max_width, max_height):
	var eligible = []
	for layout in get_room_layouts_for_floor(floor_level):
		if layout.width <= max_width and layout.height <= max_height:
			eligible.append(layout)
	if eligible.is_empty():
		return null
	return eligible[randi() % eligible.size()].name

func get_room(room_name):
	return _world_repo.get_room(room_name)

func get_all_rooms():
	var raw_rooms = []
	for layout in _world_repo.room_list:
		raw_rooms.append(layout.raw)
	return raw_rooms

func create_room_name():
	var noun_list = _pack_loader.cache.text.get("noun", []) if _pack_loader.cache != null and _pack_loader.cache.has("text") and typeof(_pack_loader.cache.text) == TYPE_DICTIONARY else []
	var chosen = OD.DataStructure.choose(noun_list, 1)
	var noun = chosen[0] if typeof(chosen) == TYPE_ARRAY and not chosen.is_empty() else (chosen if typeof(chosen) == TYPE_DICTIONARY else null)
	if noun == null:
		return {
			name = "The Mysterious Room",
			database_id = "",
			flooring = null,
			painting = null,
			statue = null
		}
	var text_value = str(noun.get("text", "Mysterious"))
	var plural_value = str(noun.get("plural", ""))
	var use_plural = plural_value != "" and plural_value != "0" and (plural_value == text_value or randi() % 2 == 0)
	var room_title = "The Room of " + (plural_value if use_plural else text_value) if use_plural else "The " + text_value + " Room"
	return {
		name = room_title,
		database_id = "",
		flooring = noun.get("floor", noun.get("flooring", null)),
		painting = noun.get("painting", null),
		statue = noun.get("statue", null)
	}

func get_branch(branch_id):
	var info = get_branch_info(branch_id)
	return info.raw if info != null else null

func get_branch_info(branch_id_or_name):
	return _world_repo.get_branch_info(branch_id_or_name)

func get_all_branches():
	return _world_repo.branch_list

func get_monster(monster_name):
	return _world_repo.get_monster(monster_name)

func get_random_monster():
	return _world_repo.get_random_monster()

func get_loot(loot_kind, loot_sub_kind = null, floor_level = -1):
	return ItemFactory.get_loot(_item_repo, loot_kind, loot_sub_kind, floor_level)

func get_craft_skill_key(tool_tag):
	return _item_repo.get_craft_skill_key(tool_tag)

func get_craft_output_for_skill(recipe, skill_level):
	if recipe == null or not recipe.has("outputs"):
		return null
	var best_out = null
	var best_skill = -1
	for out_entry in recipe.outputs:
		if typeof(out_entry) != TYPE_DICTIONARY:
			continue
		var req = int(out_entry.get("skill", 0))
		if req <= skill_level and req >= best_skill:
			best_skill = req
			best_out = out_entry
	return best_out

func get_toolkit_info(tool_tag):
	for item_entry in get_items_by_category("toolkit"):
		var raw_toolkit = item_entry.get("raw", {}).get("toolkit", null)
		if typeof(raw_toolkit) == TYPE_DICTIONARY and str(raw_toolkit.get("tag", "")) == str(tool_tag):
			return {
				tag = str(raw_toolkit.get("tag", "")),
				name = str(item_entry.get("name", tool_tag)),
				icon = str(item_entry.get("icon", "")),
				numslots = int(raw_toolkit.get("numslots", 4)),
				sound = str(raw_toolkit.get("sound", "")),
				bg = str(raw_toolkit.get("bg", "ui/crafting/generic_bg.png")),
				craftbutton = str(raw_toolkit.get("craftbutton", "ui/crafting/generic_but_craft"))
			}
	return null

func get_toolkit_tag_for_item(item_name_or_definition):
	var item_definition = get_item(str(item_name_or_definition.get("name", item_name_or_definition))) if typeof(item_name_or_definition) == TYPE_DICTIONARY else get_item(str(item_name_or_definition))
	if item_definition == null:
		return ""
	var raw_toolkit = item_definition.get("raw", {}).get("toolkit", null)
	if typeof(raw_toolkit) == TYPE_DICTIONARY:
		return str(raw_toolkit.get("tag", ""))
	return ""

func get_all_crafts():
	return _item_repo.craft_recipes

func get_crafts_for_output(item_name):
	return _item_repo.crafts_by_output.get(item_name, [])

func get_crafts_by_tool(tool_tag):
	return _item_repo.crafts_by_tool.get(tool_tag, [])

func get_encrust_slot_icon(slot_type):
	return str(ItemRepository.ENCRUST_SLOT_ICON_MAP.get(str(slot_type), "expansion3/ui/encrusting/encrust_weapon.png"))

func get_all_encrusts():
	return _item_repo.encrust_list

func get_encrust(encrust_name):
	return _item_repo.encrusts_by_name.get(encrust_name, null)

func get_encrusts_by_tool(tool_tag):
	return _item_repo.encrusts_by_tool.get(tool_tag, [])

func get_unstable_effects():
	return _item_repo.unstable_effects

func get_skill(skill_id_or_name):
	return _skill_spell_repo.get_skill(skill_id_or_name)

func get_skill_level(skill_id_or_name, level):
	return _skill_spell_repo.get_skill_level(skill_id_or_name, level)

func get_all_skills(include_deprecated = false):
	return _skill_spell_repo.get_all_skills(include_deprecated)

func get_spell(spell_name):
	return _skill_spell_repo.get_spell(spell_name)

func get_all_spells():
	return _skill_spell_repo.spell_list

func get_template(template_name):
	return _skill_spell_repo.get_template(template_name)

func get_item(item_name):
	return _item_repo.items_by_name.get(item_name, null)

func get_items_by_category(category):
	return _item_repo.items_by_category.get(category, [])

func get_all_items():
	return _item_repo.item_list

func create_item_instance(item_name_or_definition, count = 1):
	return ItemFactory.create_item_instance(_item_repo, _world_repo, item_name_or_definition, count)

func generate_artifact_name(base_name):
	return ItemFactory.generate_artifact_name(_pack_loader.cache, base_name)

func create_artifact_instance(base_item_or_definition = null, floor_level = 1, forced_quality = -1):
	return ItemFactory.create_artifact_instance(_pack_loader.cache, _item_repo, _world_repo, base_item_or_definition, floor_level, forced_quality)

func roll_floor_loot(floor_level = 1, loot_kind = "", artifact_chance = 0.04):
	return ItemFactory.roll_floor_loot(_pack_loader.cache, _item_repo, _world_repo, floor_level, loot_kind, artifact_chance)

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

func get_tweak(tweak_name, default_value = null):
	return _world_repo.get_tweak(tweak_name, default_value)

func get_all_tweaks():
	return _world_repo.tweaks

func get_wizard_room_layouts():
	return _world_repo.wizard_rooms

func get_magic_box_layouts():
	return _world_repo.magic_box_rooms

func get_room_layout(room_name):
	return _world_repo.get_room_layout(room_name)

func get_room_layouts_for_floor(floor_index):
	return _world_repo.get_room_layouts_for_floor(floor_index)

func get_sound_path(cue_name):
	return _world_repo.sounds.get(cue_name, null)

func get_sound_cues():
	var cues = _world_repo.sounds.keys()
	cues.sort()
	return cues
