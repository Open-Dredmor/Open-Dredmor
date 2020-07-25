extends Node

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
	return xml_parser

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

# https://docs.godotengine.org/en/stable/classes/class_file.html#class-file-method-get-64
# https://docs.godotengine.org/en/stable/classes/class_spriteframes.html#class-spriteframes
# https://github.com/godotengine/godot/issues/18269
# https://github.com/godotengine/godot-proposals/issues/475
func sprite_pro_motion(relative_path):	
	var absolute_path = resolve(relative_path)
	var file = File.new()
	_handle_err(absolute_path, file.open(absolute_path, File.READ))
	# Pro Motion SPR spec
	# https://www.cosmigo.com/promotion/docs/onlinehelp/TechnicalInfos.htm
	var _header = file.get_buffer(3).get_string_from_ascii()
	var frame_count = read_int(file, 2)
	var width = read_int(file, 2)
	var height = read_int(file, 2)
	var frames = []
	var trans_chunk = null
	print("Width "+str(width)+", Height: "+str(height)+", Size: "+str(width*height)+", frames: "+str(frame_count))
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
	if file.get_len() > file.get_position():
			var _trans_header = file.get_buffer(6).get_string_from_ascii()
			trans_chunk = file.get_buffer(width*height)
			print("trans_chunk size: "+str(trans_chunk.size()))
	else:
		print("No alpha found")
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation(relative_path)
	var ii = 0
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
		var test_node = TextureRect.new()
		test_node.texture = image_texture
		ii+=1
		test_node.margin_left = (ii if ii < 6 else ii-5) * 200
		test_node.margin_top = (1 if ii < 6 else 2) * 200
		get_node("/root/Container").add_child(test_node)
		sprite_frames.add_frame(relative_path, image_texture)
	var result = AnimatedSprite.new()
	result.set_sprite_frames(sprite_frames)
	return result

func sprite_xml(_relative_path):
	pass

func sprite_palette(_relative_path):
	pass
	
func _handle_err(resource_path, err):
	if err != OK:
		print("An error occurred while loading [" + resource_path + "]. Error code "+str(err))
		Scenes.quit()
	
	
