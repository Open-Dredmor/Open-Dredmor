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
	"skills": KEY_K,
	"crafting": KEY_R
}

const DEFAULT_GAMEPAD_BINDS = {
	"move_up": JOY_BUTTON_DPAD_UP,
	"move_down": JOY_BUTTON_DPAD_DOWN,
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"wait": JOY_BUTTON_X,
	"interact": JOY_BUTTON_A,
	"inventory": JOY_BUTTON_Y,
	"character": JOY_BUTTON_BACK,
	"skills": JOY_BUTTON_LEFT_SHOULDER,
	"crafting": JOY_BUTTON_RIGHT_SHOULDER
}

const GAMEPAD_BUTTON_NAMES = {
	JOY_BUTTON_A: "A / Cross",
	JOY_BUTTON_B: "B / Circle",
	JOY_BUTTON_X: "X / Square",
	JOY_BUTTON_Y: "Y / Triangle",
	JOY_BUTTON_BACK: "Back / Select",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start / Menu",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB / L1",
	JOY_BUTTON_RIGHT_SHOULDER: "RB / R1",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right"
}

func load():
	var config = ConfigFile.new()
	var error = config.load(settings_path)
	if error == OK or error == ERR_FILE_NOT_FOUND:
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
		for action_name in DEFAULT_GAMEPAD_BINDS.keys():
			if not config.has_section_key("gamepad_controls", action_name):
				config.set_value("gamepad_controls", action_name, DEFAULT_GAMEPAD_BINDS[action_name])
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

func normalize_dir_path(directory_path):
	if directory_path == null or directory_path == "":
		return ""
	if directory_path[-1] != '/':
		return directory_path + '/'
	return directory_path

func validate_dredmor_dir(directory_path):
	var normalized = normalize_dir_path(directory_path)
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
		var directory = _settings.get_value("open_dredmor", "dredmor_install_directory")
		if directory != null and directory != "":
			cached_install_dir = normalize_dir_path(directory)
	return cached_install_dir

func _parse_mod_manifest(mod_root, fallback_name):
	var manifest = {
		name = fallback_name,
		author = "",
		description = "",
		revision = "",
		require_expansion = []
	}
	var candidate_paths = [mod_root + "mod/mod.xml", mod_root + "mod.xml"]
	var manifest_path = ""
	for candidate in candidate_paths:
		if FileAccess.file_exists(candidate):
			manifest_path = candidate
			break
	if manifest_path == "":
		return manifest
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return manifest
	var xml_parser = XMLParser.new()
	if xml_parser.open_buffer(file.get_as_text().to_utf8_buffer()) != OK:
		return manifest
	var current_tag = ""
	while xml_parser.read() == OK:
		var node_type = xml_parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT:
			current_tag = xml_parser.get_node_name().to_lower()
			if current_tag == "dredmormod" or current_tag == "mod":
				for attr_index in range(xml_parser.get_attribute_count()):
					var attr_name = xml_parser.get_attribute_name(attr_index).to_lower()
					var attr_value = xml_parser.get_attribute_value(attr_index).strip_edges()
					if attr_name == "name" and attr_value != "":
						manifest.name = attr_value
					elif attr_name == "revision" or attr_name == "version":
						manifest.revision = attr_value
			elif current_tag == "info":
				for attr_index in range(xml_parser.get_attribute_count()):
					var attr_name = xml_parser.get_attribute_name(attr_index).to_lower()
					var attr_value = xml_parser.get_attribute_value(attr_index).strip_edges()
					if attr_name == "totalconversion" or attr_name == "text":
						continue
			elif current_tag == "requireexpansion":
				for attr_index in range(xml_parser.get_attribute_count()):
					var attr_name = xml_parser.get_attribute_name(attr_index).to_lower()
					if attr_name == "name" or attr_name == "id":
						manifest.require_expansion.append(xml_parser.get_attribute_value(attr_index).strip_edges())
		elif node_type == XMLParser.NODE_TEXT or node_type == XMLParser.NODE_CDATA:
			var text_value = xml_parser.get_node_data().strip_edges()
			if text_value == "":
				continue
			if current_tag == "name" or current_tag == "title":
				manifest.name = text_value
			elif current_tag == "author":
				manifest.author = text_value
			elif current_tag == "description":
				manifest.description = text_value
			elif current_tag == "revision" or current_tag == "version":
				manifest.revision = text_value
		elif node_type == XMLParser.NODE_ELEMENT_END:
			current_tag = ""
	return manifest

func _scan_mods_directory(mods_root, relative_prefix_base, seen_ids, output_list):
	if not DirAccess.dir_exists_absolute(mods_root):
		return
	var directory_access = DirAccess.open(mods_root)
	if directory_access == null:
		return
	var entry_names = []
	directory_access.list_dir_begin()
	var entry = directory_access.get_next()
	while entry != "":
		if directory_access.current_is_dir() and not entry.begins_with("."):
			entry_names.append(entry)
		entry = directory_access.get_next()
	directory_access.list_dir_end()
	entry_names.sort()
	for entry_name in entry_names:
		var pack_id = "mod:" + entry_name
		if seen_ids.has(pack_id):
			continue
		seen_ids[pack_id] = true
		var root_dir = normalize_dir_path(mods_root + entry_name)
		var data_subdir = "mod/" if DirAccess.dir_exists_absolute(root_dir + "mod") else ("game/" if DirAccess.dir_exists_absolute(root_dir + "game") else "")
		var manifest = _parse_mod_manifest(root_dir, entry_name)
		output_list.append({
			id = pack_id,
			name = manifest.name,
			prefix = relative_prefix_base + entry_name + "/",
			root_dir = root_dir,
			data_subdir = data_subdir,
			kind = "mod",
			metadata = manifest
		})

func get_available_content_packs():
	if _cached_content_packs != null:
		return _cached_content_packs
	_cached_content_packs = []
	var install_directory = dredmor_install_dir()
	if install_directory == null or install_directory == "":
		return _cached_content_packs
	for expansion_id in EXPANSION_INFO.keys():
		var root_dir = install_directory + expansion_id + "/"
		if DirAccess.dir_exists_absolute(root_dir + "game"):
			_cached_content_packs.append({
				id = expansion_id,
				name = EXPANSION_INFO[expansion_id],
				prefix = expansion_id + "/",
				root_dir = root_dir,
				data_subdir = "game/",
				kind = "expansion",
				metadata = {
					name = EXPANSION_INFO[expansion_id],
					author = "Gaslamp Games",
					description = "",
					revision = "",
					require_expansion = []
				}
			})
	var seen_mod_ids = {}
	_scan_mods_directory(install_directory + "mods/", "mods/", seen_mod_ids, _cached_content_packs)
	var user_mods_dir = normalize_dir_path(ProjectSettings.globalize_path("user://mods/"))
	_scan_mods_directory(user_mods_dir, "", seen_mod_ids, _cached_content_packs)
	var home_dir = OS.get_environment("HOME")
	if home_dir != "":
		var gaslamp_mods = normalize_dir_path(home_dir) + ".local/share/Gaslamp Games/Dungeons of Dredmor/mods/"
		_scan_mods_directory(gaslamp_mods, "", seen_mod_ids, _cached_content_packs)
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

func get_gamepad_binds():
	var binds = {}
	for action_name in DEFAULT_GAMEPAD_BINDS.keys():
		var button_index = DEFAULT_GAMEPAD_BINDS[action_name]
		if _settings != null:
			button_index = int(_settings.get_value("gamepad_controls", action_name, button_index))
		binds[action_name] = button_index
	return binds

func gamepad_button_name(button_index):
	var idx = int(button_index)
	if GAMEPAD_BUTTON_NAMES.has(idx):
		return GAMEPAD_BUTTON_NAMES[idx]
	return "Button " + str(idx)

func apply_keybinds():
	var binds = get_keybinds()
	var gamepad_binds = get_gamepad_binds()
	for action_name in binds.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		InputMap.action_erase_events(action_name)
		var key_event = InputEventKey.new()
		key_event.keycode = binds[action_name]
		InputMap.action_add_event(action_name, key_event)
		if gamepad_binds.has(action_name):
			var joy_event = InputEventJoypadButton.new()
			joy_event.button_index = gamepad_binds[action_name]
			InputMap.action_add_event(action_name, joy_event)

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
