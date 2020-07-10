extends Node

var _settings = null;

var settings_path = "user://open-dredmor-settings.ini"

func load():
	var config = ConfigFile.new()
	var err = config.load(settings_path)
	if err == OK:		   
		if not config.has_section_key("open_dredmor", "dredmor_install_directory"):
			config.set_value("open_dredmor", "dredmor_install_directory", null)
		if not config.has_section_key("game","audio_volume_master_percent"):
			config.set_value("game", "audio_volume_master_percent", 100)
		config.save(settings_path)
	_settings = config

func change(section, key, value):
	print(section,key,value)
	_settings.set_value(section, key, value)
	_settings.save(settings_path)

var cached_install_dir = null

func dredmor_install_dir():
	if cached_install_dir == null:
		var dir = _settings.get_value("open_dredmor", "dredmor_install_directory")
		if dir != null and dir != "":
			if dir[-1] != '/':
				dir += '/'
			cached_install_dir = dir
	return cached_install_dir
	
func display_size():
	# ProjectSettings.get_setting("display/window/size/width"))
	return get_viewport().size
