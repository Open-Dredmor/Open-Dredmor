extends Node

var DEFAULT_ANIMATION_FRAME_RATE_MILLISECONDS = 400

var cache = {}
var _resolve_cache = {}
var _dir_entries_cache = {}
var _exists_cache = {}
var _anim_frames_cache = {}

func clear_cache():
	cache = {}
	_resolve_cache = {}
	_dir_entries_cache = {}
	_exists_cache = {}
	_anim_frames_cache = {}

func exists(relative_path, internal=false):
	var cache_key = ("res://" if internal else "") + str(relative_path)
	if _exists_cache.has(cache_key):
		return _exists_cache[cache_key]
	var found = FileAccess.file_exists(resolve(relative_path, internal))
	_exists_cache[cache_key] = found
	return found

func _get_dir_entries_lower(dir_path):
	if _dir_entries_cache.has(dir_path):
		return _dir_entries_cache[dir_path]
	var entries = {}
	var dir = DirAccess.open(dir_path)
	if dir != null:
		dir.list_dir_begin()
		var item_name = dir.get_next()
		while item_name != "":
			if item_name != "." and item_name != "..":
				entries[item_name.to_lower()] = item_name
			item_name = dir.get_next()
		dir.list_dir_end()
	_dir_entries_cache[dir_path] = entries
	return entries

func _resolve_case_insensitive(base_dir, relative_path):
	var parts = relative_path.split("/", false)
	var current = base_dir
	for idx in range(parts.size()):
		var part = parts[idx]
		var is_last = idx == parts.size() - 1
		var candidate = current + part
		if is_last:
			if FileAccess.file_exists(candidate):
				current = candidate
				continue
		else:
			if DirAccess.dir_exists_absolute(candidate):
				current = candidate + "/"
				continue
		var entries = _get_dir_entries_lower(current)
		var lower_part = part.to_lower()
		if not entries.has(lower_part):
			return null
		var matched = entries[lower_part]
		current = current + matched + ("" if is_last else "/")
	return current if FileAccess.file_exists(current) else null

func resolve(relative_path, internal = false):
	if internal:
		return "res://asset/" + relative_path
	if _resolve_cache.has(relative_path):
		return _resolve_cache[relative_path]
	var install_dir = OD.Settings.dredmor_install_dir()
	var direct_path = install_dir + relative_path
	if FileAccess.file_exists(direct_path):
		_resolve_cache[relative_path] = direct_path
		return direct_path
	for pack_prefix in OD.Database.get_active_pack_prefixes():
		var pack_path = install_dir + pack_prefix + relative_path
		if FileAccess.file_exists(pack_path):
			_resolve_cache[relative_path] = pack_path
			return pack_path
	var ci_direct = _resolve_case_insensitive(install_dir, relative_path)
	if ci_direct != null:
		_resolve_cache[relative_path] = ci_direct
		return ci_direct
	for pack_prefix in OD.Database.get_active_pack_prefixes():
		var ci_pack = _resolve_case_insensitive(install_dir + pack_prefix, relative_path)
		if ci_pack != null:
			_resolve_cache[relative_path] = ci_pack
			return ci_pack
	if OD.AssetCache != null and OD.AssetCache.has_cached_file(relative_path):
		var cached_path = OD.AssetCache.resolve_cached_path(relative_path)
		_resolve_cache[relative_path] = cached_path
		return cached_path
	_resolve_cache[relative_path] = direct_path
	_exists_cache[relative_path] = false
	return direct_path

func image(relative_path, internal=false):
	if cache.has(relative_path):
		return cache[relative_path]	
	if internal:
		var absolute_path = resolve(relative_path, true)
		if ResourceLoader.exists(absolute_path):
			var stream_texture = load(absolute_path)
			if stream_texture != null:
				var img = stream_texture.get_image()
				var image_texture = ImageTexture.create_from_image(img)
				cache[relative_path] = image_texture
				return image_texture
		var raw_img = Image.new()
		if raw_img.load(ProjectSettings.globalize_path(absolute_path)) == OK:
			var raw_texture = ImageTexture.create_from_image(raw_img)
			cache[relative_path] = raw_texture
			return raw_texture
		return null
	else:
		var img = Image.new()	
		var absolute_path = resolve(relative_path)
		_handle_err(absolute_path, img.load(absolute_path))
		var texture = ImageTexture.create_from_image(img)
		cache[relative_path] = texture
		return texture
	
func audio(relative_path):
	if cache.has(relative_path):
		return cache[relative_path]
	var absolute_path = resolve(relative_path)
	var stream = AudioStreamOggVorbis.load_from_file(absolute_path)
	if stream == null:
		_handle_err(absolute_path, ERR_CANT_OPEN)
	stream.loop = true
	cache[relative_path] = stream
	return stream

func sfx(relative_path):
	var cache_key = "sfx:" + relative_path
	if cache.has(cache_key):
		return cache[cache_key]
	var absolute_path = resolve(relative_path)
	if not FileAccess.file_exists(absolute_path):
		push_warning("SFX file not found: " + absolute_path)
		return null
	var extension = relative_path.get_extension().to_lower()
	var stream = null
	match extension:
		"wav":
			stream = AudioStreamWAV.load_from_file(absolute_path)
		"ogg":
			stream = AudioStreamOggVorbis.load_from_file(absolute_path)
			if stream != null:
				stream.loop = false
		_:
			push_warning("Unsupported SFX format [" + extension + "] for " + relative_path)
			return null
	if stream == null:
		push_warning("Failed to load SFX: " + absolute_path)
		return null
	cache[cache_key] = stream
	return stream
	
func xml(relative_path):	
	var absolute_path = resolve(relative_path)
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	_handle_err(absolute_path, FileAccess.get_open_error() if file == null else OK)
	var xml_content = file.get_as_text()
	# Strip out all comments, otherwise godot can crash without any error
	# https://github.com/godotengine/godot/issues/40415
	var reg_ex = RegEx.new()
	var expression = "<!--[\\s\\S\\n]*?-->"
	reg_ex.compile(expression)
	xml_content = reg_ex.sub(xml_content, "", true)
	var xml_parser = XMLParser.new()
	xml_parser.open_buffer(xml_content.to_utf8_buffer())
	var result = {}
	var element_stack = []
	var reading = true
	var err = null
	while reading:
		var node_type = xml_parser.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				if element_stack.size() > 0:
					element_stack.pop_back()
			XMLParser.NODE_ELEMENT:
				var node_kind = xml_parser.get_node_name()
				var current_node = {}
				var attribute_count = xml_parser.get_attribute_count()
				for ii in range(attribute_count):
					var attribute_name = xml_parser.get_attribute_name(ii)
					current_node[attribute_name] = xml_parser.get_attribute_value(ii)
				var parent_node = element_stack[element_stack.size() - 1] if element_stack.size() > 0 else result
				if parent_node.has(node_kind):
					if typeof(parent_node[node_kind]) != TYPE_ARRAY:
						parent_node[node_kind] = [parent_node[node_kind]]
					parent_node[node_kind].append(current_node)
				else:
					parent_node[node_kind] = current_node
				if not xml_parser.is_empty():
					element_stack.append(current_node)
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				var node_data = xml_parser.get_node_data().strip_edges()
				if node_data.length() > 0 and element_stack.size() > 0:
					var owner_node = element_stack[element_stack.size() - 1]
					if owner_node.has("text"):
						owner_node["text"] += node_data
					else:
						owner_node["text"] = node_data
			_:
				pass
		err = xml_parser.read()
		if err != OK:
			if err != ERR_FILE_EOF:
				print("An error occurred while reading XML: " + str(err))
			reading = false
	return result

func font(relative_path):
	if cache.has(relative_path):
		return cache[relative_path]
	var font_file = FontFile.new()
	var absolute_path = resolve(relative_path)
	_handle_err(absolute_path, font_file.load_dynamic_font(absolute_path))
	cache[relative_path] = font_file
	return font_file

func read_int(file, byte_count):
	var result = 0
	var bytes = file.get_buffer(byte_count)
	for ii in range(byte_count):
		result += int(bytes[ii]) << (8 * ii)
	return result

func png_sprite(relative_path, start, end, delay_milliseconds):
	if not '.png' in relative_path and not '.spr' in relative_path:
		var animation = OD.Animations.new()
		animation.init()
		var ii = start
		while ii < end:
			animation.add_texture_frame(image(relative_path+"000"+str(ii)+'.png'), delay_milliseconds)			
			ii += 1
		return animation
	return null

func split_animation(relative_paths):
	var animation = OD.Animations.new()
	animation.init()
	for path in relative_paths:
		animation.add_texture_frame(image(path), DEFAULT_ANIMATION_FRAME_RATE_MILLISECONDS)
	return animation

func _build_animation_from_cached(frame_list):
	var anim = OD.Animations.new()
	anim.init()
	for entry in frame_list:
		anim.add_texture_frame(entry.texture, entry.delay_milliseconds)
	return anim

func animation(relative_path, palette_path = null):
	var cache_key = str(relative_path) + "|" + (str(palette_path) if palette_path != null else "")
	if _anim_frames_cache.has(cache_key):
		return _build_animation_from_cached(_anim_frames_cache[cache_key])
	var parts = relative_path.split('.')
	var extension = parts[parts.size()-1]
	var frame_list = null
	match extension:
		"spr":
			frame_list = _pro_motion_sprite_frames(relative_path, palette_path)
		"xml":
			frame_list = _xml_sprite_frames(relative_path)
		"png":
			frame_list = [{ texture = image(relative_path), delay_milliseconds = 0 }]
		_:
			print("No handler for animation " + relative_path)
			OD.Scenes.quit()
			return null
	if frame_list == null:
		return null
	_anim_frames_cache[cache_key] = frame_list
	return _build_animation_from_cached(frame_list)

func _parse_color_table(color_table_bytes):
	var color_table = {}
	var color_table_index = 0
	var lookup_index = 0
	while color_table_index + 2 < color_table_bytes.size():
		color_table[lookup_index] = [
			color_table_bytes[color_table_index],
			color_table_bytes[color_table_index + 1],
			color_table_bytes[color_table_index + 2]
		]
		color_table_index += 3
		lookup_index += 1
	return color_table

func sprite_palette(relative_path):
	if cache.has(relative_path):
		return cache[relative_path]
	var absolute_path = resolve(relative_path)
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	_handle_err(absolute_path, FileAccess.get_open_error() if file == null else OK)
	var color_table_bytes = file.get_buffer(256 * 3)
	var color_table = _parse_color_table(color_table_bytes)
	cache[relative_path] = color_table
	return color_table

# Pro Motion SPR spec
# https://www.cosmigo.com/promotion/docs/onlinehelp/TechnicalInfos.htm
func _pro_motion_sprite_frames(relative_path, palette_path = null):
	var absolute_path = resolve(relative_path)
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		_handle_err(absolute_path, FileAccess.get_open_error())
		return null
	var _header = file.get_buffer(3).get_string_from_ascii()
	var frame_count = read_int(file, 2)
	var width = read_int(file, 2)
	var height = read_int(file, 2)
	var frames = []
	var _trans_chunk = null
	var override_palette = sprite_palette(palette_path) if palette_path != null and palette_path != "" else null
	for _ii in range(frame_count):
		var delay_milliseconds = read_int(file, 2)
		var color_table_bytes = file.get_buffer(256*3)
		var color_table = override_palette if override_palette != null else _parse_color_table(color_table_bytes)
		var image_data = file.get_buffer(width * height)
		frames.append({
			delay_milliseconds = delay_milliseconds,
			color_table = color_table,
			image_data = image_data
		})
	if file.get_length() > file.get_position():
		var _trans_header = file.get_buffer(6).get_string_from_ascii()
		_trans_chunk = file.get_buffer(width * height)

	var frame_list = []
	var pixel_count = width * height
	for frame in frames:
		var pixels = PackedByteArray()
		pixels.resize(pixel_count * 4)
		var color_table = frame.color_table
		var image_data = frame.image_data
		for jj in range(pixel_count):
			var color_idx = image_data[jj]
			var rgb = color_table[color_idx]
			var out_idx = jj * 4
			pixels[out_idx] = rgb[0]
			pixels[out_idx + 1] = rgb[1]
			pixels[out_idx + 2] = rgb[2]
			var alpha = 0 if color_idx == 0 else 255
			if _trans_chunk != null and jj < _trans_chunk.size():
				alpha = _trans_chunk[jj]
			pixels[out_idx + 3] = alpha

		var img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)
		var image_texture = ImageTexture.create_from_image(img)
		frame_list.append({ texture = image_texture, delay_milliseconds = frame.delay_milliseconds })

	return frame_list

func _xml_sprite_frames(relative_path):
	var document = xml(relative_path)
	var frame_list = []
	if not document.has("sprite") or not document.sprite.has("frame"):
		return frame_list
	var frames = OD.DataStructure.arrayify(document.sprite.frame)
	var path_parts = relative_path.split('/')
	var image_root = ''
	for ii in range(path_parts.size() - 1):
		image_root += path_parts[ii] + '/'
	for frame in frames:
		if not frame.has("text"):
			continue
		var image_path = image_root + frame.text
		var delay_milliseconds = int(frame.delay) if frame.has("delay") else DEFAULT_ANIMATION_FRAME_RATE_MILLISECONDS
		var texture = image(image_path)
		frame_list.append({ texture = texture, delay_milliseconds = delay_milliseconds })
	return frame_list
	
func _handle_err(resource_path, err):
	if err != OK:
		print("An error occurred while loading [" + resource_path + "]. Error code "+str(err))
		OD.Scenes.quit()
