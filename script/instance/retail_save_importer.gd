extends RefCounted

class_name RetailSaveImporter

const SaveManagerScript = preload("res://script/instance/save_manager.gd")

static func _normalize_dir(directory_path):
	var cleaned = str(directory_path).strip_edges()
	if cleaned == "":
		return ""
	if not cleaned.ends_with("/"):
		cleaned += "/"
	return cleaned

static func get_common_save_dirs():
	var candidates = []
	var docs_directory = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs_directory != "":
		candidates.append(docs_directory + "/Gaslamp Games/Dungeons of Dredmor")
	var home_directory = OS.get_environment("HOME")
	if home_directory != "":
		candidates.append(home_directory + "/Documents/Gaslamp Games/Dungeons of Dredmor")
		candidates.append(home_directory + "/.local/share/Gaslamp Games/Dungeons of Dredmor")
		candidates.append(home_directory + "/Library/Application Support/Dungeons of Dredmor")
	var dev_directory = ProjectSettings.globalize_path("res://airef/retail-save-dir/Dungeons of Dredmor")
	if dev_directory != "":
		candidates.append(dev_directory)
	var unique = []
	var seen = {}
	for raw_path in candidates:
		var norm = _normalize_dir(raw_path)
		if norm != "" and not seen.has(norm):
			seen[norm] = true
			unique.append(norm)
	return unique

static func _read_u32(bytes, offset):
	if offset < 0 or offset + 4 > bytes.size():
		return { ok = false, value = 0, next = offset }
	var val = int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)
	return { ok = true, value = val, next = offset + 4 }

static func _read_ascii_str(bytes, offset, min_len = 3, max_len = 64):
	var len_result = _read_u32(bytes, offset)
	if not len_result.ok:
		return { ok = false, value = "", next = offset }
	var text_len = len_result.value
	var start = len_result.next
	if text_len < min_len or text_len > max_len or start + text_len > bytes.size():
		return { ok = false, value = "", next = offset }
	for ii in range(start, start + text_len):
		var byte_value = bytes[ii]
		if byte_value < 32 or byte_value > 126:
			return { ok = false, value = "", next = offset }
	return { ok = true, value = bytes.slice(start, start + text_len).get_string_from_ascii(), next = start + text_len }

static func parse_metadata(meta_path, fallback_name = "Hero"):
	var result = {
		ok = false,
		name = fallback_name,
		rank = "Adventurer",
		branch = "The Dungeon",
		floor_idx = 0,
		floor = 1,
		skill_ids = [],
		warnings = []
	}
	if not FileAccess.file_exists(meta_path):
		result.warnings.append("Missing metadata.dat; using fallback metadata.")
		return result
	var bytes = FileAccess.get_file_as_bytes(meta_path)
	if bytes.size() < 20 or bytes.slice(0, 4).get_string_from_ascii() != "DMET":
		result.warnings.append("Corrupted metadata.dat header; using fallback metadata.")
		return result
	var off = 8
	var name_result = _read_ascii_str(bytes, off, 1, 256)
	if name_result.ok and name_result.value != "":
		result.name = name_result.value
		off = name_result.next
	else:
		result.warnings.append("Truncated character name in metadata.dat.")
		return result
	var rank_result = _read_ascii_str(bytes, off, 0, 256)
	if rank_result.ok:
		result.rank = rank_result.value
		off = rank_result.next
	var branch_result = _read_ascii_str(bytes, off, 0, 256)
	if branch_result.ok:
		result.branch = branch_result.value
		off = branch_result.next
	var floor_result = _read_u32(bytes, off)
	if floor_result.ok:
		result.floor_idx = clamp(floor_result.value, 0, 99)
		result.floor = result.floor_idx + 1
		off = floor_result.next
	for _index in range(7):
		var skill_result = _read_u32(bytes, off)
		if not skill_result.ok:
			break
		result.skill_ids.append(skill_result.value)
		off = skill_result.next
	result.ok = true
	return result

static func inspect_retail_save(save_directory_path):
	var norm_directory = _normalize_dir(save_directory_path)
	var directory_name = norm_directory.trim_suffix("/").get_file()
	var fallback_name = directory_name.get_basename()
	var meta = parse_metadata(norm_directory + "metadata.dat", fallback_name)
	var has_savegame = FileAccess.file_exists(norm_directory + "savegame.dat")
	var level_files = []
	var directory = DirAccess.open(norm_directory)
	if directory != null:
		directory.list_dir_begin()
		var function = directory.get_next()
		while function != "":
			if not directory.current_is_dir() and function.begins_with("level") and function.ends_with(".dat"):
				level_files.append(function)
			function = directory.get_next()
		directory.list_dir_end()
	level_files.sort()
	var warnings = meta.warnings.duplicate()
	if not has_savegame:
		warnings.append("Missing savegame.dat")
	if level_files.is_empty():
		warnings.append("No level*.dat files found")
	var health_text = "Healthy" if warnings.is_empty() else "Recoverable (" + str(warnings.size()) + " warning(s))"
	var thumb_path = norm_directory + "thumbnail.bmp"
	return {
		path = norm_directory,
		directory_name = directory_name,
		name = meta.name,
		rank = meta.rank,
		branch = meta.branch,
		floor = meta.floor,
		floor_idx = meta.floor_idx,
		skill_ids = meta.skill_ids,
		has_savegame = has_savegame,
		level_files = level_files,
		thumbnail_path = thumb_path if FileAccess.file_exists(thumb_path) else "",
		warnings = warnings,
		label = "%s (Floor %d)" % [meta.name, meta.floor],
		details = "Character: %s\nTitle: %s\nFloor: %d (%s)\nLevels: %d\nStatus: %s\nPath: %s" % [
			meta.name,
			meta.rank,
			meta.floor,
			meta.branch,
			level_files.size(),
			health_text,
			norm_directory
		]
	}

static func scan_directory(directory_path):
	var norm_directory = _normalize_dir(directory_path)
	var found = []
	if norm_directory == "" or not DirAccess.dir_exists_absolute(norm_directory):
		return found
	if norm_directory.trim_suffix("/").ends_with(".dredmorsave"):
		found.append(inspect_retail_save(norm_directory))
		return found
	var directory = DirAccess.open(norm_directory)
	if directory == null:
		return found
	directory.list_dir_begin()
	var entry = directory.get_next()
	while entry != "":
		if directory.current_is_dir() and entry.ends_with(".dredmorsave"):
			found.append(inspect_retail_save(norm_directory + entry))
		entry = directory.get_next()
	directory.list_dir_end()
	found.sort_custom(func(item_a, item_b): return str(item_a.name).naturalnocasecmp_to(str(item_b.name)) < 0)
	return found

static func scan_common_directories():
	var all_saves = []
	var seen_paths = {}
	var matched_dirs = []
	for directory_path in get_common_save_dirs():
		if not DirAccess.dir_exists_absolute(directory_path):
			continue
		var entries = scan_directory(directory_path)
		if not entries.is_empty():
			matched_dirs.append(directory_path)
			for entry in entries:
				if not seen_paths.has(entry.path):
					seen_paths[entry.path] = true
					all_saves.append(entry)
	return {
		saves = all_saves,
		matched_dirs = matched_dirs
	}

static func _find_player_offset(bytes, character_name):
	if character_name == "":
		return -1
	var name_bytes = character_name.to_utf8_buffer()
	var len_bytes = PackedByteArray([
		name_bytes.size() & 0xff,
		(name_bytes.size() >> 8) & 0xff,
		(name_bytes.size() >> 16) & 0xff,
		(name_bytes.size() >> 24) & 0xff
	])
	var pattern = PackedByteArray()
	pattern.append_array(len_bytes)
	pattern.append_array(name_bytes)
	var max_start = bytes.size() - pattern.size()
	for index in range(max_start + 1):
		var matched = true
		for jj in range(pattern.size()):
			if bytes[index + jj] != pattern[jj]:
				matched = false
				break
		if matched:
			return index
	return -1

static func _extract_player_data_from_level(level_path, character_name, fallback_skills):
	var extracted = {
		found = false,
		zorkmids = 150,
		xp = 0,
		level = 1,
		skill_ids = fallback_skills.duplicate(),
		skill_tiers = {},
		items = [],
		warnings = []
	}
	if not FileAccess.file_exists(level_path):
		extracted.warnings.append("Active level file missing: " + level_path.get_file())
		return extracted
	var bytes = FileAccess.get_file_as_bytes(level_path)
	if bytes.size() < 32 or bytes.slice(0, 4).get_string_from_ascii() != "DLEV":
		extracted.warnings.append("Corrupted level header in " + level_path.get_file())
		return extracted
	var player_off = _find_player_offset(bytes, character_name)
	if player_off == -1:
		extracted.warnings.append("Player record not found in " + level_path.get_file() + "; recovered metadata only.")
		return extracted

	extracted.found = true
	var name_len_result = _read_u32(bytes, player_off)
	var after_name = player_off + 4 + name_len_result.value
	if after_name + 22 * 4 <= bytes.size():
		var zork_result = _read_u32(bytes, after_name + 3 * 4)
		var xp_result = _read_u32(bytes, after_name + 4 * 4)
		if zork_result.ok:
			extracted.zorkmids = clamp(zork_result.value, 0, 9999999)
		if xp_result.ok:
			extracted.xp = max(0, xp_result.value)
		var tiers = []
		for ii in range(7):
			var t_result = _read_u32(bytes, after_name + (8 + ii) * 4)
			tiers.append(clamp(t_result.value, 1, 8) if t_result.ok else 1)
		var sids = []
		for ii in range(7):
			var s_result = _read_u32(bytes, after_name + (15 + ii) * 4)
			if s_result.ok:
				sids.append(s_result.value)
		if sids.size() == 7:
			extracted.skill_ids = sids
		var total_tiers = 0
		for ii in range(min(extracted.skill_ids.size(), tiers.size())):
			extracted.skill_tiers[str(extracted.skill_ids[ii])] = tiers[ii]
			total_tiers += tiers[ii]
		extracted.level = max(1, total_tiers - 6)

	var scan_start = after_name + 22 * 4
	var scan_end = min(bytes.size(), scan_start + 8192)
	var position = scan_start
	var seen_items = {}
	while position + 4 < scan_end:
		var text_result = _read_ascii_str(bytes, position, 3, 64)
		if text_result.ok:
			var candidate = text_result.value
			if OD.Database != null and OD.Database.has_method("get_item"):
				var item_definition = OD.Database.get_item(candidate)
				if item_definition != null and not seen_items.has(candidate):
					seen_items[candidate] = true
					extracted.items.append(OD.Database.create_item_instance(item_definition))
					position = text_result.next
					continue
		position += 1
	return extracted

static func import_save(save_directory_path, target_save_path = ""):
	var info = inspect_retail_save(save_directory_path)
	var warnings = info.warnings.duplicate()

	var target_level_file = info.path + "level" + str(info.floor_idx) + ".dat"
	if not FileAccess.file_exists(target_level_file) and not info.level_files.is_empty():
		target_level_file = info.path + info.level_files[info.level_files.size() - 1]
	var pdata = _extract_player_data_from_level(target_level_file, info.name, info.skill_ids)
	if not pdata.found:
		for index in range(info.level_files.size() - 1, -1, -1):
			var candidate_file = info.path + info.level_files[index]
			if candidate_file == target_level_file:
				continue
			var alt_pdata = _extract_player_data_from_level(candidate_file, info.name, info.skill_ids)
			if alt_pdata.found:
				pdata = alt_pdata
				break
	warnings.append_array(pdata.warnings)

	var valid_skills = []
	var valid_tiers = {}
	for raw_id in pdata.skill_ids:
		var sid = int(raw_id)
		if OD.Database != null and OD.Database.get_skill(sid) != null:
			if not valid_skills.has(sid):
				valid_skills.append(sid)
				valid_tiers[str(sid)] = int(pdata.skill_tiers.get(str(sid), 1))
		else:
			warnings.append("Skipped unknown/modded skill ID " + str(sid))

	if valid_skills.is_empty():
		valid_skills = [0, 1, 2, 3, 4, 5, 6]
		for sid in valid_skills:
			valid_tiers[str(sid)] = 1
		warnings.append("No matching vanilla skills found; assigned default skills.")

	var temporary_player = PlayerCharacter.new()
	temporary_player._init_stat_tables()
	temporary_player.character_name = info.name
	temporary_player.hero_kind = "hero"
	temporary_player.chosen_skills = valid_skills.duplicate()
	temporary_player.skill_tiers_unlocked.clear()
	for sid in valid_skills:
		temporary_player.skill_tiers_unlocked[sid] = 0
		var tier_count = max(1, int(valid_tiers.get(str(sid), 1)))
		for _step in range(tier_count):
			temporary_player.unlock_next_skill_tier(sid, true)
	temporary_player.level = pdata.level
	temporary_player.xp = pdata.xp
	temporary_player.xp_to_next_level = temporary_player._compute_xp_threshold(temporary_player.level)
	temporary_player.zorkmids_ref = { value = pdata.zorkmids }
	for ii in range(min(pdata.items.size(), temporary_player.INVENTORY_SIZE)):
		temporary_player.inventory[ii] = pdata.items[ii]
	temporary_player.recalculate_stats()
	temporary_player.hp = temporary_player.max_hp
	temporary_player.mp = temporary_player.max_mp

	var out_path = str(target_save_path)
	if out_path == "":
		out_path = SaveManagerScript.build_save_path(info.name)
	else:
		SaveManagerScript.ensure_saves_dir(out_path.get_base_dir() + "/")

	var active_packs = OD.Settings.get_available_content_packs().map(func(pack_info): return pack_info.id) if OD.Settings != null else []
	var payload = {
		format = SaveManagerScript.SAVE_FORMAT,
		version = SaveManagerScript.SAVE_VERSION,
		saved_at = Time.get_datetime_string_from_system(),
		imported_from_retail = true,
		retail_source_path = info.path,
		name = info.name,
		hero = "hero",
		level = int(temporary_player.level),
		floor = int(info.floor),
		branch_name = "The Dungeon",
		difficulty = "Medium",
		difficulty_id = 1,
		permadeath = false,
		no_time_to_grind = false,
		active_packs = active_packs,
		rng_seed = randi(),
		turn_count = 0,
		monsters_killed = 0,
		lutefisk = 0,
		discovered_rooms = {},
		in_pocket_dimension = false,
		saved_main_return_cell = null,
		active_strategy = "retail",
		dungeon_settings = {
			difficulty = 1,
			no_time_to_grind = false,
			permadeath = false,
			hero = "hero",
			name = info.name,
			starting_skill_ids = valid_skills.duplicate(),
			active_packs = active_packs,
			debug_teleport = false,
			base_turn_seconds = 0.5,
			turn_pacing_seconds = 0.12
		},
		player = SaveManagerScript.serialize_player(temporary_player),
		floors = {},
		pocket_dimensions = {}
	}
	temporary_player.free()

	var file = FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		return { ok = false, error = "Failed to write imported save to " + out_path, warnings = warnings }
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return {
		ok = true,
		path = out_path,
		name = info.name,
		floor = info.floor,
		level = pdata.level,
		items_imported = pdata.items.size(),
		warnings = warnings
	}
