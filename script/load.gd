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
	
func _handle_err(resource_path, err):
	if err != OK:
		print("An error occurred while loading [" + resource_path + "]. Error code "+str(err))
		Scenes.quit()
	
	
