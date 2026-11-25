extends RefCounted

class_name RetailSaveImporter

const SaveManagerScript = preload("res://script/instance/save_manager.gd")

static func _normalize_dir(dir_path):
	var cleaned = str(dir_path).strip_edges()
	if cleaned == "":
		return ""
	if not cleaned.ends_with("/"):
		cleaned += "/"
	return cleaned

static func get_common_save_dirs():
	var candidates = []
	var docs_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs_dir != "":
		candidates.append(docs_dir + "/Gaslamp Games/Dungeons of Dredmor")
	var home_dir = OS.get_environment("HOME")
	if home_dir != "":
		candidates.append(home_dir + "/Documents/Gaslamp Games/Dungeons of Dredmor")
		candidates.append(home_dir + "/.local/share/Gaslamp Games/Dungeons of Dredmor")
		candidates.append(home_dir + "/Library/Application Support/Dungeons of Dredmor")
	var dev_dir = ProjectSettings.globalize_path("res://airef/retail-save-dir/Dungeons of Dredmor")
	if dev_dir != "":
		candidates.append(dev_dir)
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
	var len_res = _read_u32(bytes, offset)
	if not len_res.ok:
		return { ok = false, value = "", next = offset }
	var str_len = len_res.value
	var start = len_res.next
	if str_len < min_len or str_len > max_len or start + str_len > bytes.size():
		return { ok = false, value = "", next = offset }
	for ii in range(start, start + str_len):
		var byte_val = bytes[ii]
		if byte_val < 32 or byte_val > 126:
			return { ok = false, value = "", next = offset }
	return { ok = true, value = bytes.slice(start, start + str_len).get_string_from_ascii(), next = start + str_len }

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
	var name_res = _read_ascii_str(bytes, off, 1, 256)
	if name_res.ok and name_res.value != "":
		result.name = name_res.value
		off = name_res.next
	else:
		result.warnings.append("Truncated character name in metadata.dat.")
		return result
	var rank_res = _read_ascii_str(bytes, off, 0, 256)
	if rank_res.ok:
		result.rank = rank_res.value
		off = rank_res.next
	var branch_res = _read_ascii_str(bytes, off, 0, 256)
	if branch_res.ok:
		result.branch = branch_res.value
		off = branch_res.next
	var floor_res = _read_u32(bytes, off)
	if floor_res.ok:
		result.floor_idx = clamp(floor_res.value, 0, 99)
		result.floor = result.floor_idx + 1
		off = floor_res.next
	for _idx in range(7):
		var skill_res = _read_u32(bytes, off)
		if not skill_res.ok:
			break
		result.skill_ids.append(skill_res.value)
		off = skill_res.next
	result.ok = true
	return result

static func inspect_retail_save(save_dir_path):
	var norm_dir = _normalize_dir(save_dir_path)
	var dir_name = norm_dir.trim_suffix("/").get_file()
	var fallback_name = dir_name.get_basename()
	var meta = parse_metadata(norm_dir + "metadata.dat", fallback_name)
	var has_savegame = FileAccess.file_exists(norm_dir + "savegame.dat")
	var level_files = []
	var dir = DirAccess.open(norm_dir)
	if dir != null:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if not dir.current_is_dir() and fn.begins_with("level") and fn.ends_with(".dat"):
				level_files.append(fn)
			fn = dir.get_next()
		dir.list_dir_end()
	level_files.sort()
	var warnings = meta.warnings.duplicate()
	if not has_savegame:
		warnings.append("Missing savegame.dat")
	if level_files.is_empty():
		warnings.append("No level*.dat files found")
	var health_text = "Healthy" if warnings.is_empty() else "Recoverable (" + str(warnings.size()) + " warning(s))"
	var thumb_path = norm_dir + "thumbnail.bmp"
	return {
		path = norm_dir,
		dir_name = dir_name,
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
			norm_dir
		]
	}

static func scan_directory(dir_path):
	var norm_dir = _normalize_dir(dir_path)
	var found = []
	if norm_dir == "" or not DirAccess.dir_exists_absolute(norm_dir):
		return found
	if norm_dir.trim_suffix("/").ends_with(".dredmorsave"):
		found.append(inspect_retail_save(norm_dir))
		return found
	var dir = DirAccess.open(norm_dir)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry.ends_with(".dredmorsave"):
			found.append(inspect_retail_save(norm_dir + entry))
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort_custom(func(item_a, item_b): return str(item_a.name).naturalnocasecmp_to(str(item_b.name)) < 0)
	return found

static func scan_common_directories():
	var all_saves = []
	var seen_paths = {}
	var matched_dirs = []
	for dir_path in get_common_save_dirs():
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		var entries = scan_directory(dir_path)
		if not entries.is_empty():
			matched_dirs.append(dir_path)
			for entry in entries:
				if not seen_paths.has(entry.path):
					seen_paths[entry.path] = true
					all_saves.append(entry)
	return {
		saves = all_saves,
		matched_dirs = matched_dirs
	}

static func _find_player_offset(bytes, char_name):
	if char_name == "":
		return -1
	var name_bytes = char_name.to_utf8_buffer()
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
	for idx in range(max_start + 1):
		var matched = true
		for jj in range(pattern.size()):
			if bytes[idx + jj] != pattern[jj]:
				matched = false
				break
		if matched:
			return idx
	return -1

static func _extract_player_data_from_level(level_path, char_name, fallback_skills):
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
	var player_off = _find_player_offset(bytes, char_name)
	if player_off == -1:
		extracted.warnings.append("Player record not found in " + level_path.get_file() + "; recovered metadata only.")
		return extracted

	extracted.found = true
	var name_len_res = _read_u32(bytes, player_off)
	var after_name = player_off + 4 + name_len_res.value
	if after_name + 22 * 4 <= bytes.size():
		var zork_res = _read_u32(bytes, after_name + 3 * 4)
		var xp_res = _read_u32(bytes, after_name + 4 * 4)
		if zork_res.ok:
			extracted.zorkmids = clamp(zork_res.value, 0, 9999999)
		if xp_res.ok:
			extracted.xp = max(0, xp_res.value)
		var tiers = []
		for ii in range(7):
			var t_res = _read_u32(bytes, after_name + (8 + ii) * 4)
			tiers.append(clamp(t_res.value, 1, 8) if t_res.ok else 1)
		var sids = []
		for ii in range(7):
			var s_res = _read_u32(bytes, after_name + (15 + ii) * 4)
			if s_res.ok:
				sids.append(s_res.value)
		if sids.size() == 7:
			extracted.skill_ids = sids
		var total_tiers = 0
		for ii in range(min(extracted.skill_ids.size(), tiers.size())):
			extracted.skill_tiers[str(extracted.skill_ids[ii])] = tiers[ii]
			total_tiers += tiers[ii]
		extracted.level = max(1, total_tiers - 6)

	var scan_start = after_name + 22 * 4
	var scan_end = min(bytes.size(), scan_start + 8192)
	var pos = scan_start
	var seen_items = {}
	while pos + 4 < scan_end:
		var str_res = _read_ascii_str(bytes, pos, 3, 64)
		if str_res.ok:
			var candidate = str_res.value
			if OD.Database != null and OD.Database.has_method("get_item"):
				var item_def = OD.Database.get_item(candidate)
				if item_def != null and not seen_items.has(candidate):
					seen_items[candidate] = true
					extracted.items.append(OD.Database.create_item_instance(item_def))
					pos = str_res.next
					continue
		pos += 1
	return extracted

static func import_save(save_dir_path, target_save_path = ""):
	var info = inspect_retail_save(save_dir_path)
	var warnings = info.warnings.duplicate()

	var target_level_file = info.path + "level" + str(info.floor_idx) + ".dat"
	if not FileAccess.file_exists(target_level_file) and not info.level_files.is_empty():
		target_level_file = info.path + info.level_files[info.level_files.size() - 1]
	var pdata = _extract_player_data_from_level(target_level_file, info.name, info.skill_ids)
	if not pdata.found:
		for idx in range(info.level_files.size() - 1, -1, -1):
			var cand_file = info.path + info.level_files[idx]
			if cand_file == target_level_file:
				continue
			var alt_pdata = _extract_player_data_from_level(cand_file, info.name, info.skill_ids)
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

	var temp_player = PlayerCharacter.new()
	temp_player._init_stat_tables()
	temp_player.character_name = info.name
	temp_player.hero_kind = "hero"
	temp_player.chosen_skills = valid_skills.duplicate()
	temp_player.skill_tiers_unlocked.clear()
	for sid in valid_skills:
		temp_player.skill_tiers_unlocked[sid] = 0
		var tier_count = max(1, int(valid_tiers.get(str(sid), 1)))
		for _step in range(tier_count):
			temp_player.unlock_next_skill_tier(sid, true)
	temp_player.level = pdata.level
	temp_player.xp = pdata.xp
	temp_player.xp_to_next_level = temp_player._compute_xp_threshold(temp_player.level)
	temp_player.zorkmids_ref = { value = pdata.zorkmids }
	for ii in range(min(pdata.items.size(), temp_player.INVENTORY_SIZE)):
		temp_player.inventory[ii] = pdata.items[ii]
	temp_player.recalculate_stats()
	temp_player.hp = temp_player.max_hp
	temp_player.mp = temp_player.max_mp

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
		level = int(temp_player.level),
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
		player = SaveManagerScript.serialize_player(temp_player),
		floors = {},
		pocket_dimensions = {}
	}
	temp_player.free()

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
