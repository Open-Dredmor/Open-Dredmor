extends Node

var _settings = null;

var settings_path = "user://open-dredmor-settings.ini"

const DEFAULT_KEYBINDS = {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"wait": KEY_SPACE,
	"interact": KEY_E,
	"inventory": KEY_I,
	"character": KEY_C,
	"skills": KEY_K
}

func load():
	var config = ConfigFile.new()
	var err = config.load(settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		if not config.has_section_key("open_dredmor", "dredmor_install_directory"):
			config.set_value("open_dredmor", "dredmor_install_directory", null)
		if not config.has_section_key("game", "audio_enabled"):
			config.set_value("game", "audio_enabled", true)
		if not config.has_section_key("game", "audio_volume_master_percent"):
			config.set_value("game", "audio_volume_master_percent", 100)
		if not config.has_section_key("game", "audio_volume_music_percent"):
			config.set_value("game", "audio_volume_music_percent", 100)
		if not config.has_section_key("game", "audio_volume_sfx_percent"):
			config.set_value("game", "audio_volume_sfx_percent", 100)
		if not config.has_section_key("game", "audio_volume_dialogue_percent"):
			config.set_value("game", "audio_volume_dialogue_percent", 100)
		if not config.has_section_key("game", "game_speed"):
			config.set_value("game", "game_speed", 1.0)
		if not config.has_section_key("display", "fullscreen"):
			config.set_value("display", "fullscreen", false)
		for action_name in DEFAULT_KEYBINDS.keys():
			if not config.has_section_key("controls", action_name):
				config.set_value("controls", action_name, DEFAULT_KEYBINDS[action_name])
		config.save(settings_path)
	_settings = config
	apply_display_settings()
	apply_keybinds()

func change(section, key, value):
	_settings.set_value(section, key, value)
	_settings.save(settings_path)
	cached_install_dir = null
	_cached_content_packs = null

func get_game_speed():
	if _settings == null:
		return 1.0
	return clamp(float(_settings.get_value("game", "game_speed", 1.0)), 0.25, 20.0)

func set_game_speed(speed_multiplier):
	var clamped = clamp(float(speed_multiplier), 0.25, 20.0)
	if _settings != null:
		change("game", "game_speed", clamped)
	return clamped

var cached_install_dir = null
var _cached_content_packs = null

const EXPANSION_INFO = {
	"expansion": "Realm of the Diggle Gods",
	"expansion2": "You Have To Name The Expansion Pack",
	"expansion3": "Conquest of the Wizardlands"
}

const REQUIRED_DREDMOR_FILES = [
	"game/itemDB.xml",
	"game/skillDB.xml",
	"game/monDB.xml",
	"game/rooms.xml",
	"game/branchDB.xml",
	"game/craftDB.xml",
	"game/spellDB.xml",
	"game/text.xml"
]

func normalize_dir_path(dir_path):
	if dir_path == null or dir_path == "":
		return ""
	if dir_path[-1] != '/':
		return dir_path + '/'
	return dir_path

func validate_dredmor_dir(dir_path):
	var normalized = normalize_dir_path(dir_path)
	var missing = []
	if normalized == "" or not DirAccess.dir_exists_absolute(normalized):
		return {
			valid = false,
			missing = REQUIRED_DREDMOR_FILES.duplicate()
		}
	for relative_path in REQUIRED_DREDMOR_FILES:
		if not FileAccess.file_exists(normalized + relative_path):
			missing.append(relative_path)
	return {
		valid = missing.is_empty(),
		missing = missing
	}

func dredmor_install_dir():
	if cached_install_dir == null:
		var dir = _settings.get_value("open_dredmor", "dredmor_install_directory")
		if dir != null and dir != "":
			cached_install_dir = normalize_dir_path(dir)
	return cached_install_dir

func get_available_content_packs():
	if _cached_content_packs != null:
		return _cached_content_packs
	_cached_content_packs = []
	var install_dir = dredmor_install_dir()
	if install_dir == null or install_dir == "":
		return _cached_content_packs
	for expansion_id in EXPANSION_INFO.keys():
		if DirAccess.dir_exists_absolute(install_dir + expansion_id + "/game"):
			_cached_content_packs.append({
				id = expansion_id,
				name = EXPANSION_INFO[expansion_id],
				prefix = expansion_id + "/",
				data_subdir = "game/",
				kind = "expansion"
			})
	var mods_root = install_dir + "mods/"
	if DirAccess.dir_exists_absolute(mods_root):
		var dir_access = DirAccess.open(mods_root)
		if dir_access != null:
			dir_access.list_dir_begin()
			var entry = dir_access.get_next()
			while entry != "":
				if dir_access.current_is_dir() and not entry.begins_with("."):
					var prefix = "mods/" + entry + "/"
					var data_subdir = "mod/" if DirAccess.dir_exists_absolute(install_dir + prefix + "mod") else "game/"
					_cached_content_packs.append({
						id = "mod:" + entry,
						name = entry,
						prefix = prefix,
						data_subdir = data_subdir,
						kind = "mod"
					})
				entry = dir_access.get_next()
			dir_access.list_dir_end()
	return _cached_content_packs
	
func audio_enabled():
	if _settings == null:
		return true
	var result = _settings.get_value("game","audio_enabled")
	if result == null:
		return true
	return result

func master_volume_percent():
	if _settings == null:
		return 100
	var result = _settings.get_value("game", "audio_volume_master_percent")
	if result == null:
		return 100
	return clamp(int(result), 0, 100)

func sfx_volume_percent():
	if _settings == null:
		return 100
	var result = _settings.get_value("game", "audio_volume_sfx_percent")
	if result == null:
		return 100
	return clamp(int(result), 0, 100)

func music_volume_percent():
	if _settings == null:
		return 100
	var result = _settings.get_value("game", "audio_volume_music_percent")
	if result == null:
		return 100
	return clamp(int(result), 0, 100)

func dialogue_volume_percent():
	if _settings == null:
		return 100
	var result = _settings.get_value("game", "audio_volume_dialogue_percent")
	if result == null:
		return 100
	return clamp(int(result), 0, 100)

func fullscreen_enabled():
	if _settings == null:
		return false
	var result = _settings.get_value("display", "fullscreen", false)
	if result == null:
		return false
	return bool(result)

func apply_display_settings():
	if DisplayServer.get_name() == "headless":
		return
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled() else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func get_keybinds():
	var binds = {}
	for action_name in DEFAULT_KEYBINDS.keys():
		var code = DEFAULT_KEYBINDS[action_name]
		if _settings != null:
			code = int(_settings.get_value("controls", action_name, code))
		binds[action_name] = code
	return binds

func apply_keybinds():
	var binds = get_keybinds()
	for action_name in binds.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		InputMap.action_erase_events(action_name)
		var key_event = InputEventKey.new()
		key_event.keycode = binds[action_name]
		InputMap.action_add_event(action_name, key_event)

func last_selected_skill_ids():
	if _settings == null:
		return []
	var result = _settings.get_value("game", "last_selected_skill_ids", [])
	if typeof(result) != TYPE_ARRAY:
		return []
	return result

func set_last_selected_skill_ids(skill_ids):
	change("game", "last_selected_skill_ids", skill_ids.duplicate())
	
func display_size():
	# ProjectOD.Settings.get_setting("display/window/size/viewport_width"))
	return get_viewport().get_visible_rect().size
