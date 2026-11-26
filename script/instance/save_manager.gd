extends RefCounted

class_name SaveManager

const GridSerializerScript = preload("res://script/instance/grid_serializer.gd")

const SAVES_DIR = "user://saves/"
const SAVE_FORMAT = "open_dredmor_save"
const SAVE_VERSION = 1

static func ensure_saves_dir(saves_directory = SAVES_DIR):
	if not DirAccess.dir_exists_absolute(saves_directory):
		DirAccess.make_dir_recursive_absolute(saves_directory)

static func _sanitize_filename(raw_name):
	var cleaned = ""
	var source = str(raw_name).strip_edges()
	for ii in range(source.length()):
		var ch = source[ii]
		var code = ch.unicode_at(0)
		var is_alnum = (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		if is_alnum or ch == "_" or ch == "-":
			cleaned += ch
		elif ch == " ":
			cleaned += "_"
	if cleaned == "":
		cleaned = "hero"
	return cleaned.to_lower()

static func build_save_path(character_name, saves_directory = SAVES_DIR):
	ensure_saves_dir(saves_directory)
	var base = _sanitize_filename(character_name)
	var candidate = saves_directory + base + ".json"
	if not FileAccess.file_exists(candidate):
		return candidate
	var suffix = 2
	while FileAccess.file_exists(saves_directory + base + "_" + str(suffix) + ".json"):
		suffix += 1
	return saves_directory + base + "_" + str(suffix) + ".json"

static func _difficulty_label(diff_value):
	match int(diff_value):
		0:
			return "Easy"
		2:
			return "Hard"
		_:
			return "Medium"

static func serialize_player(player):
	if player == null:
		return null
	var p_position = player.get_grid_position()
	var tiers_out = {}
	for sid in player.skill_tiers_unlocked.keys():
		tiers_out[str(sid)] = int(player.skill_tiers_unlocked[sid])
	var chosen_out = []
	var skill_entries_out = []
	for sid in player.chosen_skills:
		var skill_id = int(sid)
		chosen_out.append(skill_id)
		var skill_def = OD.Database.get_skill(skill_id) if OD.Database != null else null
		skill_entries_out.append({
			id = skill_id,
			name = str(skill_def.get("name", "")) if skill_def != null else "",
			pack_id = str(skill_def.get("pack_id", "vanilla")) if skill_def != null else "",
			tier = int(player.skill_tiers_unlocked.get(sid, 1))
		})
	return {
		grid_pos = [int(p_position.x), int(p_position.y)] if p_position != null else [0, 0],
		character_name = str(player.character_name),
		hero_kind = str(player.hero_kind),
		hp = int(player.hp),
		max_hp = int(player.max_hp),
		mp = int(player.mp),
		max_mp = int(player.max_mp),
		is_dead = bool(player.is_dead),
		last_damage_source = str(player.last_damage_source),
		xp = int(player.xp),
		xp_to_next_level = int(player.xp_to_next_level),
		level = int(player.level),
		zorkmids = int(player.get_zorkmids()),
		skill_points = int(player.skill_points),
		chosen_skills = chosen_out,
		skill_entries = skill_entries_out,
		skill_tiers_unlocked = tiers_out,
		spell_cooldowns = GridSerializerScript._sanitize_value(player.spell_cooldowns),
		hotbar_spells = player.get_hotbar_spells(),
		belt_items = player.get_belt_items(),
		active_buffs = GridSerializerScript._sanitize_value(player.active_buffs),
		active_dots = GridSerializerScript._sanitize_value(player.active_dots),
		status_flags = GridSerializerScript._sanitize_value(player.status_flags),
		base_primary_stats = GridSerializerScript._sanitize_value(player.base_primary_stats),
		equipment = GridSerializerScript._sanitize_value(player.equipment),
		inventory = GridSerializerScript._sanitize_value(player.inventory),
		known_recipes = GridSerializerScript._sanitize_value(player.known_recipes),
		active_quests = GridSerializerScript._sanitize_value(player.active_quests),
		completed_quests = GridSerializerScript._sanitize_value(player.completed_quests)
	}

static func deserialize_player(player, data):
	if player == null or typeof(data) != TYPE_DICTIONARY:
		return
	player._init_stat_tables()
	player.character_name = str(data.get("character_name", ""))
	player.hero_kind = "heroine" if str(data.get("hero_kind", "hero")) == "heroine" else "hero"

	player.chosen_skills.clear()
	player.skill_tiers_unlocked.clear()
	player.unlocked_abilities.clear()
	player.unlocked_spells.clear()
	player.warrior_level = 0
	player.rogue_level = 0
	player.wizard_level = 0

	var saved_entries = data.get("skill_entries", [])
	if typeof(saved_entries) == TYPE_ARRAY and not saved_entries.is_empty():
		for entry in saved_entries:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var raw_id = int(entry.get("id", -1))
			var saved_name = str(entry.get("name", ""))
			var resolved_skill = OD.Database.get_skill(raw_id) if OD.Database != null else null
			if (resolved_skill == null or (saved_name != "" and str(resolved_skill.get("name", "")) != saved_name)) and saved_name != "" and OD.Database != null:
				resolved_skill = OD.Database.get_skill(saved_name)
			if resolved_skill == null:
				push_warning("Saved skill missing from active packs: " + saved_name + " (id=" + str(raw_id) + ")")
				continue
			var effective_id = int(resolved_skill.id)
			if player.chosen_skills.has(effective_id):
				continue
			player.chosen_skills.append(effective_id)
			player.skill_tiers_unlocked[effective_id] = 0
			var target_tier = max(1, int(entry.get("tier", 1)))
			for _step in range(target_tier):
				player.unlock_next_skill_tier(effective_id, true)
	else:
		var saved_tiers = data.get("skill_tiers_unlocked", {})
		for raw_id in data.get("chosen_skills", []):
			var sid = int(raw_id)
			if OD.Database != null and OD.Database.get_skill(sid) == null:
				push_warning("Saved skill id missing from active packs: " + str(sid))
				continue
			if player.chosen_skills.has(sid):
				continue
			player.chosen_skills.append(sid)
			player.skill_tiers_unlocked[sid] = 0
			var target_tier = max(1, int(saved_tiers.get(str(sid), 1)))
			for _step in range(target_tier):
				player.unlock_next_skill_tier(sid, true)

	var base_stats = data.get("base_primary_stats", {})
	if typeof(base_stats) == TYPE_DICTIONARY:
		for stat_key in player.PRIMARY_STAT_KEYS:
			if base_stats.has(stat_key):
				player.base_primary_stats[stat_key] = int(base_stats[stat_key])

	player.hotbar_spells = []
	for sp_name in data.get("hotbar_spells", []):
		player.hotbar_spells.append(str(sp_name))
	player._ensure_hotbar_initialized()

	player.belt_items = []
	for b_item in data.get("belt_items", []):
		player.belt_items.append(str(b_item))
	player._ensure_belt_initialized()

	player.spell_cooldowns = data.get("spell_cooldowns", {}).duplicate(true)
	player.active_buffs = data.get("active_buffs", []).duplicate(true)
	player.active_dots = data.get("active_dots", []).duplicate(true)
	player.status_flags = data.get("status_flags", {}).duplicate(true)
	player.known_recipes = data.get("known_recipes", {}).duplicate(true)
	player.active_quests = data.get("active_quests", []).duplicate(true)
	player.completed_quests = data.get("completed_quests", []).duplicate(true)

	var saved_equip = data.get("equipment", {})
	if typeof(saved_equip) == TYPE_DICTIONARY:
		for slot_name in player.EQUIPMENT_SLOTS:
			player.equipment[slot_name] = saved_equip.get(slot_name, null)

	var saved_inventory = data.get("inventory", [])
	if typeof(saved_inventory) == TYPE_ARRAY:
		for ii in range(min(saved_inventory.size(), player.INVENTORY_SIZE)):
			player.inventory[ii] = saved_inventory[ii]

	player.level = max(1, int(data.get("level", 1)))
	player.xp = max(0, int(data.get("xp", 0)))
	player.xp_to_next_level = max(1, int(data.get("xp_to_next_level", player._compute_xp_threshold(player.level))))
	player.skill_points = max(0, int(data.get("skill_points", 0)))
	player.zorkmids_ref = { value = max(0, int(data.get("zorkmids", 0))) }
	player.is_dead = bool(data.get("is_dead", false))
	player.last_damage_source = str(data.get("last_damage_source", "Unknown"))

	player.recalculate_stats()
	player.hp = clamp(int(data.get("hp", player.max_hp)), 0, player.max_hp)
	player.mp = clamp(int(data.get("mp", player.max_mp)), 0, player.max_mp)
	if player.animations.is_empty():
		player._load_sprite_animations()

	player.hp_changed.emit(player.hp, player.max_hp)
	player.mp_changed.emit(player.mp, player.max_mp)
	player.xp_changed.emit(player.xp, player.xp_to_next_level, player.level)
	player.zorkmids_changed.emit(player.get_zorkmids())
	player.buffs_changed.emit()
	player.inventory_changed.emit()
	player.equipment_changed.emit()
	player.belt_changed.emit()
	player.quests_changed.emit()
	player.skills_changed.emit()

static func save_run(dungeon, target_path = ""):
	if dungeon == null:
		return { ok = false, error = "No active dungeon" }
	var player = dungeon.get_player()
	if player == null:
		return { ok = false, error = "No active player" }
	var settings = OD.DungeonSettings.get_settings() if OD.DungeonSettings != null and OD.DungeonSettings.get_settings() != null else {}
	var save_path = str(target_path)
	if save_path == "":
		save_path = OD.DungeonSettings.get_save_file_path() if OD.DungeonSettings != null else ""
	if save_path == "":
		var char_name = str(player.character_name) if str(player.character_name) != "" else str(settings.get("name", "hero"))
		save_path = build_save_path(char_name)
	ensure_saves_dir(save_path.get_base_dir() + "/")
	if OD.DungeonSettings != null:
		OD.DungeonSettings.set_save_file_path(save_path)

	var floors_out = {}
	for ii in range(dungeon.floors.size()):
		var floor_grid = dungeon.floors[ii]
		if floor_grid != null:
			floors_out[str(ii + 1)] = GridSerializerScript.serialize_grid(floor_grid)

	var pocket_out = {}
	for key in dungeon._pocket_dimensions.keys():
		var p_grid = dungeon._pocket_dimensions[key]
		if p_grid != null:
			pocket_out[str(key)] = GridSerializerScript.serialize_grid(p_grid)

	var diff_value = int(settings.get("difficulty", 1))
	var turn_number = dungeon.get_turn_scheduler().turn_count if dungeon.get_turn_scheduler() != null else 0
	var rng_seed = randi()

	var payload = {
		format = SAVE_FORMAT,
		version = SAVE_VERSION,
		saved_at = Time.get_datetime_string_from_system(),
		name = str(player.character_name) if str(player.character_name) != "" else "Unnamed Hero",
		hero = str(player.hero_kind),
		level = int(player.level),
		floor = int(dungeon.get_floor_level()),
		branch_name = str(dungeon.get_branch_name()),
		difficulty = _difficulty_label(diff_value),
		difficulty_id = diff_value,
		permadeath = bool(settings.get("permadeath", false)),
		no_time_to_grind = bool(settings.get("no_time_to_grind", false)),
		active_packs = settings.get("active_packs", []).duplicate(),
		pack_manifest = _build_pack_manifest(settings.get("active_packs", [])),
		rng_seed = rng_seed,
		turn_count = int(turn_number),
		monsters_killed = int(dungeon._monsters_killed),
		lutefisk = int(dungeon._lutefisk_ref.value),
		discovered_rooms = dungeon._discovered_rooms.duplicate(true),
		in_pocket_dimension = bool(dungeon._in_pocket_dimension),
		saved_main_return_cell = GridSerializerScript._vec2i_to_arr(dungeon._saved_main_return_cell),
		active_strategy = str(dungeon._active_strategy),
		dungeon_settings = {
			difficulty = diff_value,
			no_time_to_grind = bool(settings.get("no_time_to_grind", false)),
			permadeath = bool(settings.get("permadeath", false)),
			hero = str(player.hero_kind),
			name = str(player.character_name),
			starting_skill_ids = settings.get("starting_skill_ids", []).duplicate(),
			active_packs = settings.get("active_packs", []).duplicate(),
			debug_teleport = bool(settings.get("debug_teleport", false)),
			base_turn_seconds = float(settings.get("base_turn_seconds", 0.5)),
			turn_pacing_seconds = float(settings.get("turn_pacing_seconds", 0.12))
		},
		player = serialize_player(player),
		floors = floors_out,
		pocket_dimensions = pocket_out
	}

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return { ok = false, error = "Failed to open save file for writing: " + save_path }
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return { ok = true, path = save_path, payload = payload }

static func _build_pack_manifest(active_pack_ids):
	var manifest = []
	if OD.Settings == null:
		return manifest
	var by_id = {}
	for pack_info in OD.Settings.get_available_content_packs():
		by_id[pack_info.id] = pack_info
	for pack_id in active_pack_ids:
		if by_id.has(pack_id):
			var info = by_id[pack_id]
			var meta = info.get("metadata", {})
			manifest.append({
				id = pack_id,
				name = str(info.get("name", pack_id)),
				revision = str(meta.get("revision", ""))
			})
	return manifest

static func load_save_file(save_path):
	if not FileAccess.file_exists(save_path):
		return { ok = false, error = "Save file not found: " + str(save_path) }
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return { ok = false, error = "Failed to open save file: " + str(save_path) }
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return { ok = false, error = "Invalid save file JSON" }
	if str(parsed.get("format", "")) != SAVE_FORMAT:
		return { ok = false, error = "Unsupported save format" }
	return { ok = true, data = parsed }

static func restore_run_settings(save_data, save_path = ""):
	if OD.DungeonSettings == null or typeof(save_data) != TYPE_DICTIONARY:
		return
	OD.DungeonSettings.reset()
	var ds = save_data.get("dungeon_settings", {})
	if typeof(ds) == TYPE_DICTIONARY:
		OD.DungeonSettings.set_difficulty(int(ds.get("difficulty", save_data.get("difficulty_id", 1))))
		OD.DungeonSettings.set_permadeath(bool(ds.get("permadeath", save_data.get("permadeath", false))))
		OD.DungeonSettings.set_no_time_to_grind(bool(ds.get("no_time_to_grind", save_data.get("no_time_to_grind", false))))
		OD.DungeonSettings.set_hero(str(ds.get("hero", save_data.get("hero", "hero"))))
		OD.DungeonSettings.set_character_name(str(ds.get("name", save_data.get("name", ""))))
		OD.DungeonSettings.set_starting_skill_ids(ds.get("starting_skill_ids", []))
		if ds.has("active_packs"):
			OD.DungeonSettings.set_active_packs(ds.get("active_packs", []))
		OD.DungeonSettings.set_debug_teleport(bool(ds.get("debug_teleport", false)))
	if save_path != "":
		OD.DungeonSettings.set_save_file_path(save_path)
	OD.DungeonSettings.set_pending_load_data(save_data)
	if save_data.has("rng_seed"):
		seed(int(save_data.get("rng_seed", 0)))

static func list_saves(saves_directory = SAVES_DIR):
	var saves = []
	if not DirAccess.dir_exists_absolute(saves_directory):
		return saves
	var directory = DirAccess.open(saves_directory)
	if directory == null:
		return saves
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			var full_path = saves_directory + file_name
			var loaded = load_save_file(full_path)
			if loaded.ok:
				var parsed = loaded.data
				var character_name = str(parsed.get("name", file_name.get_basename()))
				var floor_number = int(parsed.get("floor", 1))
				var character_level = int(parsed.get("level", 1))
				var diff_text = str(parsed.get("difficulty", "Medium"))
				var saved_at = str(parsed.get("saved_at", ""))
				var branch_name = str(parsed.get("branch_name", "The Dungeon"))
				var permadeath = bool(parsed.get("permadeath", false))
				var perma_text = " | Permadeath" if permadeath else ""
				var player_data = parsed.get("player", {})
				var skill_entries = player_data.get("skill_entries", []) if typeof(player_data) == TYPE_DICTIONARY else []
				var dungeon_settings = parsed.get("dungeon_settings", {})
				var starting_skill_ids = dungeon_settings.get("starting_skill_ids", []) if typeof(dungeon_settings) == TYPE_DICTIONARY else []
				var base_path = full_path.get_basename()
				var thumbnail_path = ""
				for ext in [".png", ".bmp", ".jpg"]:
					if FileAccess.file_exists(base_path + ext):
						thumbnail_path = base_path + ext
						break
				saves.append({
					path = full_path,
					file_name = file_name,
					name = character_name,
					hero = str(parsed.get("hero", "hero")),
					level = character_level,
					floor = floor_number,
					branch_name = branch_name,
					difficulty = diff_text,
					permadeath = permadeath,
					saved_at = saved_at,
					skill_entries = skill_entries,
					starting_skill_ids = starting_skill_ids,
					thumbnail_path = thumbnail_path,
					label = "%s (Lv %d, Floor %d)" % [character_name, character_level, floor_number],
					details = "Character: %s\nLevel: %d\nFloor: %d (%s)\nDifficulty: %s%s\nSaved: %s\nFile: %s" % [
						character_name,
						character_level,
						floor_number,
						branch_name,
						diff_text,
						perma_text,
						saved_at,
						file_name
					]
				})
		file_name = directory.get_next()
	directory.list_dir_end()
	saves.sort_custom(func(entry_a, entry_b): return str(entry_a.get("saved_at", "")) > str(entry_b.get("saved_at", "")))
	return saves
