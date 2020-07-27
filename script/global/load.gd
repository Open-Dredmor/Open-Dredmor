extends Node

var ODAnimation = load("res://script/instance/od_animation.gd")	

var cache = {}

func clear_cache():
	cache = {}

func exists(relative_path, internal=false):
	var file = File.new()
	return file.file_exists(resolve(relative_path, internal))

func resolve(relative_path, internal = false):
	if internal:
		return "res://asset/" + relative_path
	return Settings.dredmor_install_dir() + relative_path

func image(relative_path, internal=false):
	if cache.has(relative_path):
		return cache[relative_path]	
	if internal:
		var absolute_path = resolve(relative_path, true)
		var stream_texture = load(absolute_path)
		var image_texture = ImageTexture.new()
		var img = stream_texture.get_data()
		image_texture.create_from_image(img)
		cache[relative_path] = image_texture
		return image_texture
	else:
		var img = Image.new()	
		var absolute_path = resolve(relative_path)
		_handle_err(absolute_path, img.load(absolute_path))
		var texture = ImageTexture.new()
		texture.create_from_image(img)
		cache[relative_path] = texture
		return texture
	
func audio(relative_path):
	if cache.has(relative_path):
		return cache[relative_path]
	var file = File.new()
	var absolute_path = resolve(relative_path)
	_handle_err(absolute_path, file.open(absolute_path, File.READ))
	var bytes = file.get_buffer(file.get_len())
	var stream = AudioStreamOGGVorbis.new()
	stream.loop = true
	stream.data = bytes
	cache[relative_path] = stream
	return stream
	
func xml(relative_path):	
	var absolute_path = resolve(relative_path)
	var file = File.new()
	_handle_err(absolute_path, file.open(absolute_path, File.READ))
	var xml_content = file.get_as_text()
	# Strip out all comments, otherwise godot can crash without any error
	# https://github.com/godotengine/godot/issues/40415
	var reg_ex = RegEx.new()
	var expression = "<!--[\\s\\S\\n]*?-->"
	reg_ex.compile(expression)
	xml_content = reg_ex.sub(xml_content, "", true)
	var xml_parser = XMLParser.new()
	xml_parser.open_buffer(xml_content.to_utf8())
	var result = {}
	var manual_close_nodes = {}
	var reading = true
	var err
	
	while reading:		
		var node_type = xml_parser.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				var node_kind = xml_parser.get_node_name()
				if ! manual_close_nodes.has(node_kind):
					manual_close_nodes[node_kind] = 1
				else:
					manual_close_nodes[node_kind] = manual_close_nodes[node_kind] + 1
		err = xml_parser.read()
		if err != OK:
			if err != ERR_FILE_EOF:
				print("An error occurred while reading XML: "+str(err))
			reading = false
	manual_close_nodes = manual_close_nodes.keys()
	
	xml_parser.seek(0)
	var depth_queue = DataStructure.NewQueue()	
	reading = true
	err = null
	while reading:		
		var node_type = xml_parser.get_node_type()		
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				depth_queue.pop()
			XMLParser.NODE_ELEMENT:
				var node_kind = xml_parser.get_node_name()
				var current_node = {}
				var attribute_count = xml_parser.get_attribute_count()						
				for ii in range(attribute_count):					
					var attribute_name = xml_parser.get_attribute_name(ii)
					current_node[attribute_name] = xml_parser.get_attribute_value(ii)
				
				var depth_tree = depth_queue.tree()
				var target_node = result
				for ii in range(depth_tree.size()):
					target_node = target_node[depth_tree[ii]]
					if typeof(target_node) == TYPE_ARRAY:
						target_node = target_node[target_node.size()-1]
				if target_node.has(node_kind):
					if typeof(target_node[node_kind]) != TYPE_ARRAY:
						target_node[node_kind] = [target_node[node_kind]]
					target_node[node_kind].append(current_node)
				else:
					target_node[node_kind] = current_node
				if manual_close_nodes.has(node_kind):
					depth_queue.push(node_kind)
			XMLParser.NODE_TEXT:
				# I would prefer to hang a 'node_data' prop off the leaf node, but this is a quick and dirty workaround
				if ! result.has('data_nodes'):
					result['data_nodes'] = []
				var node_data = xml_parser.get_node_data()
				# FIXME This is a brittle workaround for some null looking characters showing up as NODE_TEXT
				if node_data.length() > 4:
					result['data_nodes'].append(node_data)
			_:
				pass
		err = xml_parser.read()
		if err != OK:
			reading = false	
	return result

func font(relative_path, size):
	var slug = relative_path + str(size)
	if cache.has(slug):
		return cache[slug]
	var font = DynamicFont.new()
	font.size = size
	font.font_data = load(resolve(relative_path))
	cache[slug] = font
	return font

func read_int(file, byte_count):
	var result = 0
	var bytes = file.get_buffer(byte_count)
	for ii in range(byte_count):
		result += bytes[ii] * (pow(2, ii))
	return result

func animation(relative_path):
	var parts = relative_path.split('.')
	var extension = parts[parts.size()-1]
	match extension:
		"spr":
			return _pro_motion_sprites(relative_path)
		"xml":
			return _xml_sprites(relative_path)
		_:
			print("No handler for animation "+relative_path)
			Scenes.quit()

# Pro Motion SPR spec
# https://www.cosmigo.com/promotion/docs/onlinehelp/TechnicalInfos.htm
func _pro_motion_sprites(relative_path):
	var absolute_path = resolve(relative_path)
	var file = File.new()
	_handle_err(absolute_path, file.open(absolute_path, File.READ))	
	var _header = file.get_buffer(3).get_string_from_ascii()
	var frame_count = read_int(file, 2)
	var width = read_int(file, 2)
	var height = read_int(file, 2)
	var frames = []
	var _trans_chunk = null
	#print("Width "+str(width)+", Height: "+str(height)+", Size: "+str(width*height)+", frames: "+str(frame_count))
	for _ii in range(frame_count):
		var delay_milliseconds = read_int(file, 2)
		var color_table_bytes = file.get_buffer(256*3)
		var color_table = {}
		var color_table_index = 0
		var lookup_index = 0
		while color_table_index + 2 < color_table_bytes.size():
			color_table[lookup_index] = [
				color_table_bytes[color_table_index],
				color_table_bytes[color_table_index+1],
				color_table_bytes[color_table_index+2]
			]
			color_table_index += 3
			lookup_index += 1
		var image_data = file.get_buffer(width * height)
		frames.append({
			delay_milliseconds = delay_milliseconds,
			color_table = color_table,
			image_data = image_data
		})
	# TODO Apply this transparency information to the frame textures
	if file.get_len() > file.get_position():
			var _trans_header = file.get_buffer(6).get_string_from_ascii()
			_trans_chunk = file.get_buffer(width*height)
			#print("trans_chunk size: "+str(trans_chunk.size()))
		
	var animation = ODAnimation.new()
	for frame in frames:
		var image_texture = ImageTexture.new()
		var img = Image.new()
		var pixels = PoolByteArray()
		# 156, 154, 156 -> Grey background
		# color_table ignore index = 0
		for jj in range(frame.image_data.size()):
			pixels.append_array(frame.color_table[frame.image_data[jj]])
			pixels.append(0 if frame.image_data[jj] == 0 else 255) # Set alpha to 0 if transparent lookup
				
		img.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)
		image_texture.create_from_image(img)
		animation.add_frame(image_texture, frame.delay_milliseconds)
	
	return animation

func _xml_sprites(relative_path):
	var document = xml(relative_path)
	var animation = ODAnimation.new()
	var image_count = document.data_nodes.size()
	var path_parts = relative_path.split('/')
	var image_root = ''
	for ii in range(path_parts.size() - 1): # chop the XML file out of the path
		image_root += path_parts[ii] + '/'
	for ii in range(image_count):
		var image_name = document.data_nodes[ii]
		var image_path = image_root + image_name
		var delay_milliseconds = document.sprite.frame[ii].delay
		var texture = image(image_path)
		animation.add_frame(texture, delay_milliseconds)
	return animation
	
func _handle_err(resource_path, err):
	if err != OK:
		print("An error occurred while loading [" + resource_path + "]. Error code "+str(err))
		Scenes.quit()
	
	
