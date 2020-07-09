extends Node

func image(relative_path):
	var img = Image.new()
	var absolute_path = Settings.dredmor_install_dir() + relative_path
	img.load(absolute_path)
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	return texture
	
func audio(relative_path):
	var file = File.new()
	file.open(Settings.dredmor_install_dir() + relative_path, File.READ)
	var bytes = file.get_buffer(file.get_len())
	var stream = AudioStreamOGGVorbis.new()
	stream.loop = true
	stream.data = bytes
	return stream
