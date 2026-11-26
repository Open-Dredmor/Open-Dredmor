extends Node

const CACHE_ROOT = "user://cache/"
const MANIFEST_PATH = "user://cache/manifest.json"
const CACHE_VERSION = 1

const DIALOG_BUTTON_STATES = [
	{ index = 0, label = "normal" },
	{ index = 1, label = "hover" },
	{ index = 2, label = "pressed" }
]

const DIALOG_BUTTON_OUTPUT_DIR = "ui/generated/"

func cache_dir():
	return CACHE_ROOT

func resolve_cached_path(relative_path):
	return CACHE_ROOT + relative_path

func has_cached_file(relative_path):
	return FileAccess.file_exists(resolve_cached_path(relative_path))

func _expected_dialog_button_paths():
	var paths = []
	for state_info in DIALOG_BUTTON_STATES:
		paths.append(DIALOG_BUTTON_OUTPUT_DIR + "dialog_but_blank" + str(state_info.index) + ".png")
	return paths

func _load_manifest():
	if not FileAccess.file_exists(MANIFEST_PATH):
		return null
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return parsed

func _save_manifest(install_dir, generated_files):
	var payload = {
		version = CACHE_VERSION,
		install_dir = install_dir,
		generated_files = generated_files
	}
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "\t"))

func is_cache_valid(install_dir):
	var manifest = _load_manifest()
	if manifest == null:
		return false
	if int(manifest.get("version", -1)) != CACHE_VERSION:
		return false
	if str(manifest.get("install_dir", "")) != str(install_dir):
		return false
	for relative_path in _expected_dialog_button_paths():
		if not has_cached_file(relative_path):
			return false
	return true

func _report_progress(status_text, percent, progress_callback):
	if progress_callback != null and progress_callback.is_valid():
		await progress_callback.call(status_text, percent)
	elif OD.Loading != null:
		await OD.Loading.step(status_text, percent)

func _discover_dialog_button_sources(install_dir, state_index):
	var ui_dir_path = install_dir + "ui/"
	var dir = DirAccess.open(ui_dir_path)
	if dir == null:
		return []
	var suffix = str(state_index) + ".png"
	var matches = []
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if not dir.current_is_dir():
			var lower_name = entry.to_lower()
			if lower_name.begins_with("dialog_but_") and lower_name.ends_with(suffix) and not lower_name.begins_with("dialog_but_blank"):
				matches.append(ui_dir_path + entry)
		entry = dir.get_next()
	dir.list_dir_end()
	matches.sort()
	return matches

func _build_blank_dialog_button(source_paths, output_relative_path):
	if source_paths.is_empty():
		return false
	var loaded_buffers = []
	var target_width = 0
	var target_height = 0
	for source_path in source_paths:
		var img = Image.new()
		if img.load(source_path) != OK:
			continue
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		if target_width == 0:
			target_width = img.get_width()
			target_height = img.get_height()
		elif img.get_width() != target_width or img.get_height() != target_height:
			continue
		loaded_buffers.append(img.get_data())
	if loaded_buffers.is_empty():
		return false

	var pixel_count = target_width * target_height
	var out_bytes = PackedByteArray()
	out_bytes.resize(pixel_count * 4)
	var buffer_count = loaded_buffers.size()
	var median_index = buffer_count >> 1
	var alpha_samples = []
	alpha_samples.resize(buffer_count)

	for pixel_idx in range(pixel_count):
		var byte_offset = pixel_idx * 4
		var max_red = 0
		var max_green = 0
		var max_blue = 0
		for buf_idx in range(buffer_count):
			var buf = loaded_buffers[buf_idx]
			var red = buf[byte_offset]
			var green = buf[byte_offset + 1]
			var blue = buf[byte_offset + 2]
			if red > max_red:
				max_red = red
			if green > max_green:
				max_green = green
			if blue > max_blue:
				max_blue = blue
			alpha_samples[buf_idx] = buf[byte_offset + 3]
		alpha_samples.sort()
		out_bytes[byte_offset] = max_red
		out_bytes[byte_offset + 1] = max_green
		out_bytes[byte_offset + 2] = max_blue
		out_bytes[byte_offset + 3] = alpha_samples[median_index]

	var out_image = Image.create_from_data(target_width, target_height, false, Image.FORMAT_RGBA8, out_bytes)
	var out_abs_path = ProjectSettings.globalize_path(resolve_cached_path(output_relative_path))
	DirAccess.make_dir_recursive_absolute(out_abs_path.get_base_dir())
	return out_image.save_png(out_abs_path) == OK

func ensure_cache(force_rebuild = false, progress_callback = null):
	var install_dir = OD.Settings.dredmor_install_dir()
	if install_dir == null or install_dir == "":
		return false
	if not force_rebuild and is_cache_valid(install_dir):
		return true

	await _report_progress("Scanning retail UI assets...", 15.0, progress_callback)

	var generated_files = []
	var total_states = DIALOG_BUTTON_STATES.size()
	for ii in range(total_states):
		var state_info = DIALOG_BUTTON_STATES[ii]
		var percent = 25.0 + (float(ii) / float(total_states)) * 60.0
		await _report_progress("Generating dialog button (" + state_info.label + ")...", percent, progress_callback)
		var source_paths = _discover_dialog_button_sources(install_dir, state_info.index)
		var out_relative = DIALOG_BUTTON_OUTPUT_DIR + "dialog_but_blank" + str(state_info.index) + ".png"
		if _build_blank_dialog_button(source_paths, out_relative):
			generated_files.append(out_relative)
		else:
			push_warning("Failed to generate cached asset: " + out_relative)

	await _report_progress("Finalizing asset cache...", 95.0, progress_callback)
	_save_manifest(install_dir, generated_files)
	await _report_progress("Asset cache ready.", 100.0, progress_callback)
	return generated_files.size() == total_states
