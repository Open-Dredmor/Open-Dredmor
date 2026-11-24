extends Node

var _settings = null;

var settings_path = "user://open-dredmor-settings.ini"

func load():
	var config = ConfigFile.new()
	var err = config.load(settings_path)
	if err == OK:		   
		if not config.has_section_key("open_dredmor", "dredmor_install_directory"):
			config.set_value("open_dredmor", "dredmor_install_directory", null)
		if not config.has_section_key("game","audio_enabled"):
			config.set_value("game", "audio_enabled", true)
		if not config.has_section_key("game","audio_volume_master_percent"):
			config.set_value("game", "audio_volume_master_percent", 100)
		
		config.save(settings_path)
	_settings = config

func change(section, key, value):
	_settings.set_value(section, key, value)
	_settings.save(settings_path)
	cached_install_dir = null

var cached_install_dir = null

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
	
func audio_enabled():
	var result = _settings.get_value("game","audio_enabled")
	if result == null:
		return true
	return result
	
func display_size():
	# ProjectOD.Settings.get_setting("display/window/size/viewport_width"))
	return get_viewport().get_visible_rect().size
