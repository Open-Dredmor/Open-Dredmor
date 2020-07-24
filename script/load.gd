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
	var watcher = null
	for _ii in range(frame_count):
		var _delay_milliseconds = read_int(file, 2)
		if _ii == 0:
			print("0 - "+str(_delay_milliseconds))
		var frame_bytes = file.get_buffer(256) # var red = read_int(file, 8)
		if _ii == 0:
			print("1 - "+str(frame_bytes.size()))			
		frame_bytes.append_array(file.get_buffer(256)) # var green = read_int(file, 8)
		if _ii == 0:
			print("2 - "+str(frame_bytes.size()))
		frame_bytes.append_array(file.get_buffer(256)) # var blue = read_int(file, 8)
		if _ii == 0:
			print("3 - "+str(frame_bytes.size()))
		watcher = file.get_buffer(width * height)
		frame_bytes.append_array(watcher) # var image = file.get_buffer(width * height)
		if _ii == 0:
			print("4 - "+str(frame_bytes.size()))
		frames.append(frame_bytes)
	if file.get_len() > file.get_position():
			var _trans_header = file.get_buffer(6).get_string_from_ascii()
			trans_chunk = file.get_buffer(width*height)
			print("trans_chunk size: "+str(trans_chunk.size()))
	else:
		print("No alpha found")
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation(relative_path)
	for frame in frames:
		var image_texture = ImageTexture.new()
		var img = Image.new()
		img.create_from_data(width, height, false, Image.FORMAT_RGB8, frame)
		image_texture.create_from_image(img)
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
	
	
