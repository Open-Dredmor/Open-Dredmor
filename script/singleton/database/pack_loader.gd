extends RefCounted

const XmlNormalizer = preload("res://script/singleton/database/xml_normalizer.gd")

var packs = null
var cache = null
var active_pack_ids = []
var active_pack_prefixes = []
var active_pack_roots = []

func ensure_vanilla_loaded():
	if packs == null:
		packs = {}
	if not packs.has("vanilla"):
		var install_directory = OD.Settings.dredmor_install_dir()
		if install_directory == null:
			install_directory = ""
		packs["vanilla"] = XmlNormalizer.load_pack_data(install_directory + "game/", "vanilla")

func get_or_load_pack(pack_id, available_by_id):
	if packs == null:
		packs = {}
	if packs.has(pack_id):
		return packs[pack_id]
	if not available_by_id.has(pack_id):
		return null
	var pack_info = available_by_id[pack_id]
	if OD.Settings != null and OD.Settings.has_method("ensure_pack_extracted"):
		if not OD.Settings.ensure_pack_extracted(pack_info):
			return null
	var install_directory = OD.Settings.dredmor_install_dir()
	if install_directory == null:
		install_directory = ""
	var root_dir = pack_info.get("root_dir", install_directory + pack_info.prefix)
	var data_subdir = pack_info.get("data_subdir", "game/")
	var pack_data = XmlNormalizer.load_pack_data(root_dir + data_subdir, pack_id)
	packs[pack_id] = pack_data
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
	cache.unstable_effects += pack_data.unstable_effects
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

func apply_active_packs(pack_ids):
	ensure_vanilla_loaded()
	active_pack_ids = pack_ids.duplicate()
	active_pack_prefixes = []
	active_pack_roots = []
	OD.DungeonSettings.set_active_packs(active_pack_ids)
	cache = XmlNormalizer.empty_pack_data()
	_append_pack_into_cache(packs["vanilla"])
	var available_by_id = {}
	for pack_info in OD.Settings.get_available_content_packs():
		available_by_id[pack_info.id] = pack_info
	var install_directory = OD.Settings.dredmor_install_dir()
	if install_directory == null:
		install_directory = ""
	for pack_id in active_pack_ids:
		var pack_data = get_or_load_pack(pack_id, available_by_id)
		if pack_data != null:
			_append_pack_into_cache(pack_data)
		if available_by_id.has(pack_id):
			var info = available_by_id[pack_id]
			active_pack_prefixes.append(info.prefix)
			active_pack_roots.append(info.get("root_dir", install_directory + info.prefix))
	if OD.Load != null and OD.Load.has_method("clear_cache"):
		OD.Load.clear_cache()

func default_initial_packs():
	var initial_packs = OD.DungeonSettings.get_active_packs()
	if not OD.DungeonSettings.has_initialized_packs():
		initial_packs = []
		var available_packs = OD.Settings.get_available_content_packs()
		if OD.Settings != null and OD.Settings.has_saved_active_packs():
			var available_by_id = {}
			for pack_info in available_packs:
				available_by_id[pack_info.id] = true
			for saved_pack_id in OD.Settings.last_active_packs():
				if available_by_id.has(saved_pack_id) and not initial_packs.has(saved_pack_id):
					initial_packs.append(saved_pack_id)
		else:
			for pack_info in available_packs:
				if pack_info.kind == "expansion":
					initial_packs.append(pack_info.id)
	return initial_packs
