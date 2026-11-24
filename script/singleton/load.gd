extends Node

var DEFAULT_ANIMATION_FRAME_RATE_MILLISECONDS = 400

var cache = {}

func clear_cache():
	cache = {}

func exists(relative_path, internal=false):
	return FileAccess.file_exists(resolve(relative_path, internal))

func resolve(relative_path, internal = false):
	if internal:
		return "res://asset/" + relative_path
	var install_dir = OD.Settings.dredmor_install_dir()
	var direct_path = install_dir + relative_path
	if FileAccess.file_exists(direct_path):
		return direct_path
	for pack_prefix in OD.Database.get_active_pack_prefixes():
		var pack_path = install_dir + pack_prefix + relative_path
		if FileAccess.file_exists(pack_path):
			return pack_path
	return direct_path

func image(relative_path, internal=false):
	if cache.has(relative_path):
		return cache[relative_path]	
	if internal:
		var absolute_path = resolve(relative_path, true)
		var stream_texture = load(absolute_path)
		var img = stream_texture.get_image()
		var image_texture = ImageTexture.create_from_image(img)
		cache[relative_path] = image_texture
		return image_texture
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

func animation(relative_path, palette_path = null):
	var parts = relative_path.split('.')
	var extension = parts[parts.size()-1]
	match extension:
		"spr":
			return _pro_motion_sprites(relative_path, palette_path)
		"xml":
			return _xml_sprites(relative_path)
		"png":
			var animation = OD.Animations.new()
			animation.init()
			animation.add_texture_frame(image(relative_path), 0)
			return animation
		_:
			print("No handler for animation " + relative_path)
			OD.Scenes.quit()

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
func _pro_motion_sprites(relative_path, palette_path = null):
	var absolute_path = resolve(relative_path)
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	_handle_err(absolute_path, FileAccess.get_open_error() if file == null else OK)	
	var _header = file.get_buffer(3).get_string_from_ascii()
	var frame_count = read_int(file, 2)
	var width = read_int(file, 2)
	var height = read_int(file, 2)
	var frames = []
	var _trans_chunk = null
	var override_palette = sprite_palette(palette_path) if palette_path != null and palette_path != "" else null
	#print("Width "+str(width)+", Height: "+str(height)+", Size: "+str(width*height)+", frames: "+str(frame_count))
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
		
	var animation = OD.Animations.new()
	animation.init()
	for frame in frames:
		var pixels = PackedByteArray()
		# 156, 154, 156 -> Grey background
		# color_table ignore index = 0
		for jj in range(frame.image_data.size()):
			pixels.append_array(frame.color_table[frame.image_data[jj]])
			var alpha = 0 if frame.image_data[jj] == 0 else 255
			if _trans_chunk != null and jj < _trans_chunk.size():
				alpha = _trans_chunk[jj]
			pixels.append(alpha)
				
		var img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)
		var image_texture = ImageTexture.create_from_image(img)
		animation.add_texture_frame(image_texture, frame.delay_milliseconds)
	
	return animation

func _xml_sprites(relative_path):
	var document = xml(relative_path)
	var animation = OD.Animations.new()
	animation.init()
	if not document.has("sprite") or not document.sprite.has("frame"):
		return animation
	var frames = OD.DataStructure.arrayify(document.sprite.frame)
	var path_parts = relative_path.split('/')
	var image_root = ''
	for ii in range(path_parts.size() - 1): # chop the XML file out of the path
		image_root += path_parts[ii] + '/'
	for frame in frames:
		if not frame.has("text"):
			continue
		var image_path = image_root + frame.text
		var delay_milliseconds = int(frame.delay) if frame.has("delay") else DEFAULT_ANIMATION_FRAME_RATE_MILLISECONDS
		var texture = image(image_path)
		animation.add_texture_frame(texture, delay_milliseconds)
	return animation
	
func _handle_err(resource_path, err):
	if err != OK:
		print("An error occurred while loading [" + resource_path + "]. Error code "+str(err))
		OD.Scenes.quit()
