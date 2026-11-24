extends RefCounted

class_name DeathManager

const HIGH_SCORES_PATH = "user://high_scores.json"

static func _difficulty_label(diff_val):
	match int(diff_val):
		0:
			return "Easy"
		2:
			return "Hard"
		_:
			return "Medium"

static func compute_score(player, floor_level = 1, monsters_killed = 0):
	if player == null:
		return 0
	var lvl = int(player.get("level")) if player.get("level") != null else 1
	var xp_val = int(player.get("xp")) if player.get("xp") != null else 0
	var gold = player.get_zorkmids() if player.has_method("get_zorkmids") else 0
	return max(0, xp_val + lvl * 100 + gold + int(monsters_killed) * 25 + max(1, int(floor_level)) * 150)

static func _collect_skill_names(player):
	var names = []
	if player == null or player.get("chosen_skills") == null:
		return names
	for sid in player.chosen_skills:
		var skill_entry = OD.Database.get_skill(int(sid)) if OD.Database != null else null
		if skill_entry != null and skill_entry.has("name"):
			names.append(str(skill_entry.name))
		else:
			names.append(str(sid))
	return names

static func delete_permadeath_save(save_file_path, permadeath_enabled):
	if not permadeath_enabled:
		return false
	var path = str(save_file_path)
	if path == "":
		return false
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		return err == OK
	return false

static func load_high_scores(scores_path = HIGH_SCORES_PATH):
	var scores = []
	if not FileAccess.file_exists(scores_path):
		return scores
	var file = FileAccess.open(scores_path, FileAccess.READ)
	if file == null:
		return scores
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		for entry in parsed:
			if typeof(entry) == TYPE_DICTIONARY:
				scores.append(entry)
	return scores

static func record_high_score(player, floor_level = 1, cause_of_death = "Unknown", monsters_killed = 0, scores_path = HIGH_SCORES_PATH):
	var settings = OD.DungeonSettings.get_settings() if OD.DungeonSettings != null and OD.DungeonSettings.get_settings() != null else {}
	var char_name = str(player.character_name) if player != null and str(player.get("character_name")) != "" else "Unnamed Hero"
	var lvl = int(player.level) if player != null and player.get("level") != null else 1
	var cause = str(cause_of_death) if str(cause_of_death) != "" else "Unknown"
	var diff_str = _difficulty_label(settings.get("difficulty", 1))
	var entry = {
		name = char_name,
		level = lvl,
		score = compute_score(player, floor_level, monsters_killed),
		floor = max(1, int(floor_level)),
		difficulty = diff_str,
		outcome = "Slain by " + cause,
		cause_of_death = cause,
		skills = _collect_skill_names(player),
		permadeath = bool(settings.get("permadeath", false)),
		timestamp = Time.get_datetime_string_from_system()
	}
	var scores = load_high_scores(scores_path)
	scores.append(entry)
	var file = FileAccess.open(scores_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(scores, "\t"))
		file.close()
	return entry
