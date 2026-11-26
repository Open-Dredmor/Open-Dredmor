extends RefCounted

const CASE_NORMALIZATION_MAP = {
	"primaryBuff": "primarybuff",
	"secondaryBuff": "secondarybuff",
	"resistBuff": "resistbuff",
	"damageBuff": "damagebuff",
	"targetHitEffectBuff": "targethiteffectbuff",
	"playerHitEffectBuff": "playerhiteffectbuff",
	"targetKillBuff": "targetkillbuff",
	"triggerOnCast": "triggeroncast",
	"savvyBonus": "savvybonus",
	"roomDB": "roomdb",
	"templateDB": "templatedb"
}

static func load_xml_file(absolute_path):
	if not FileAccess.file_exists(absolute_path):
		return {}
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open XML file: " + absolute_path)
		return {}
	return OD.Load.parse_xml_text(file.get_as_text(), absolute_path)

static func normalize_keys(node):
	if typeof(node) == TYPE_ARRAY:
		var out_array = []
		for element in node:
			out_array.append(normalize_keys(element))
		return out_array
	if typeof(node) != TYPE_DICTIONARY:
		return node
	var out_dict = {}
	for raw_key in node.keys():
		var target_key = CASE_NORMALIZATION_MAP.get(raw_key, raw_key)
		var normalized_value = normalize_keys(node[raw_key])
		if out_dict.has(target_key):
			var existing = OD.DataStructure.arrayify(out_dict[target_key])
			existing.append_array(OD.DataStructure.arrayify(normalized_value))
			out_dict[target_key] = existing
		else:
			out_dict[target_key] = normalized_value
	return out_dict

static func tag_entries_with_pack(entries, pack_id):
	var tagged = []
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY:
			var copy_entry = entry.duplicate(false)
			copy_entry["_pack_id"] = pack_id
			tagged.append(copy_entry)
		else:
			tagged.append(entry)
	return tagged

static func load_pack_data(base_path, pack_id):
	var pack_data = empty_pack_data()
	if base_path == "" or not DirAccess.dir_exists_absolute(base_path):
		return pack_data

	var parsed_branches = load_xml_file(base_path + "branchDB.xml")
	if parsed_branches.has("branchDB") and parsed_branches.branchDB.has("branch"):
		pack_data.branches = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_branches.branchDB.branch), pack_id)

	var parsed_crafts = load_xml_file(base_path + "craftDB.xml")
	if parsed_crafts.has("craftDB") and parsed_crafts.craftDB.has("craft"):
		pack_data.crafts = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_crafts.craftDB.craft), pack_id)

	var parsed_items = load_xml_file(base_path + "itemDB.xml")
	if parsed_items.has("itemDB") and parsed_items.itemDB.has("item"):
		pack_data.items = tag_entries_with_pack(normalize_keys(OD.DataStructure.arrayify(parsed_items.itemDB.item)), pack_id)

	var parsed_magic_box = normalize_keys(load_xml_file(base_path + "magicBoxRooms.xml"))
	if not parsed_magic_box.is_empty():
		pack_data.magic_box_rooms_db = parsed_magic_box

	var parsed_monsters = load_xml_file(base_path + "monDB.xml")
	if parsed_monsters.has("monDB") and parsed_monsters.monDB.has("monster"):
		pack_data.monsters = tag_entries_with_pack(normalize_keys(OD.DataStructure.arrayify(parsed_monsters.monDB.monster)), pack_id)

	pack_data.quest_item_db = load_xml_file(base_path + "quests.xml")

	var parsed_rooms = normalize_keys(load_xml_file(base_path + "rooms.xml"))
	if parsed_rooms.has("roomdb") and parsed_rooms.roomdb.has("room"):
		pack_data.rooms = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_rooms.roomdb.room), pack_id)

	pack_data.sound_db = load_xml_file(base_path + "soundfx.xml")
	pack_data.speech_db = load_xml_file(base_path + "speech.xml")

	var parsed_skills = normalize_keys(load_xml_file(base_path + "skillDB.xml"))
	if parsed_skills.has("skillDB"):
		if parsed_skills.skillDB.has("skill"):
			pack_data.skills = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_skills.skillDB.skill), pack_id)
		if parsed_skills.skillDB.has("ability"):
			pack_data.abilities = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_skills.skillDB.ability), pack_id)

	pack_data.spell_db = normalize_keys(load_xml_file(base_path + "spellDB.xml"))
	pack_data.template_db = normalize_keys(load_xml_file(base_path + "manTemplateDB.xml"))

	var parsed_text = load_xml_file(base_path + "text.xml")
	if parsed_text.has("text"):
		pack_data.text = parsed_text.text

	pack_data.tutorial_db = load_xml_file(base_path + "tutorial.xml")
	pack_data.tweak_db = load_xml_file(base_path + "tweakDB.xml")

	var parsed_encrusts = normalize_keys(load_xml_file(base_path + "encrustDB.xml"))
	if parsed_encrusts.has("encrustDB"):
		if parsed_encrusts.encrustDB.has("encrust"):
			pack_data.encrusts = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_encrusts.encrustDB.encrust), pack_id)
		if parsed_encrusts.encrustDB.has("unstableEffect"):
			pack_data.unstable_effects = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_encrusts.encrustDB.unstableEffect), pack_id)

	var parsed_wizard = normalize_keys(load_xml_file(base_path + "wizardRoomDB.xml"))
	for root_key in ["roomdb", "wizardRoomDB"]:
		if parsed_wizard.has(root_key) and parsed_wizard[root_key].has("room"):
			pack_data.wizard_rooms = tag_entries_with_pack(OD.DataStructure.arrayify(parsed_wizard[root_key].room), pack_id)
			break

	return pack_data

static func empty_pack_data():
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
		unstable_effects = [],
		wizard_rooms = []
	}
