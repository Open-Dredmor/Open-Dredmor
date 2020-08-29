extends Node

var CELL_PIXEL_HEIGHT = 32
var CELL_PIXEL_WIDTH = 32

func _button_textures(lookup,internal=false):
	var images = {}
	for key in lookup.keys():
		if Load.exists(lookup[key],internal):
			images[key] = Load.image(lookup[key], internal)
	return images

func main_menu():	
	var paths = ODResource.paths.main_menu
	var background_images = []
	for file in paths.backgrounds:
		background_images.append(Load.image(file))
	
	var textures = {		
		backgrounds = background_images,
		title = Load.image(paths.title),
		chrome = Load.image(paths.chrome),
		new_game_button = _button_textures(paths.button.new_game),
		load_game_button = _button_textures(paths.button.load_game),
		high_scores_button = _button_textures(paths.button.high_scores),
		settings_button = _button_textures(paths.button.settings, true),
		quit_button = _button_textures(paths.button.quit),		
		background_button = _button_textures(paths.button.cycle_background),
	}	
	
	var music = {
		title = Load.audio(paths.music)
	}
	return {
		textures = textures,
		music = music
	}
	
func difficulty_menu():
	var paths = ODResource.paths.difficulty_menu
	var textures = {
		options_form = Load.image(paths.options_form),
		checkmark_large = Load.image(paths.checkmark_large),
		checkmark_small = Load.image(paths.checkmark_small),
		done_button = _button_textures(ODResource.paths.shared.button.done),
		back_button = _button_textures(ODResource.paths.shared.button.back),
		choose_header = Load.image(paths.choose_header),
		header_background = Load.image(ODResource.paths.shared.header_background)
	}
	return {
		textures = textures
	}

func skills_menu():
	var paths = ODResource.paths.skills_menu
	var textures = {
		done_button = _button_textures(ODResource.paths.shared.button.done),
		back_button = _button_textures(ODResource.paths.shared.button.back),
		header_background = Load.image(ODResource.paths.shared.header_background),
		skills_header = Load.image(paths.skills_header),
		skill_button_border = Load.image(paths.skill_button_border),
		selected_skills_background = Load.image(paths.selected_skills_background),
		selected_skill_info_background = Load.image(paths.selected_skill_info_background),
		last_selection_button = _button_textures(paths.last_selection),
		random_selection_button = _button_textures(paths.random_selection)
	}
	var fonts = {
		info_header = Load.font(ODResource.paths.shared.font.default, 25),
		info_details = Load.font(ODResource.paths.shared.font.default, 20),
	}
	return {
		textures = textures,
		fonts = fonts
	}

func character_menu():
	var paths = ODResource.paths.character_menu
	var textures = {
		done_button = _button_textures(ODResource.paths.shared.button.done),
		back_button = _button_textures(ODResource.paths.shared.button.back),
		header_background = Load.image(ODResource.paths.shared.header_background),
		character_header = Load.image(paths.character_header),
		choose_name_background = Load.image(paths.choose_name_background),
		choose_hero_background = Load.image(paths.choose_hero_background),
		hero_portrait = Load.image(paths.hero_portrait),
		heroine_portrait = Load.image(paths.heroine_portrait)
	}
	
	var fonts = {
		name_edit = Load.font(ODResource.paths.shared.font.default, 25)
	}
	
	return {
		textures = textures,
		fonts = fonts
	}
	
func intro():
	var paths = ODResource.paths.intro
	return {
		textures = {
			primary = Load.image(paths.primary),
			secondary_hero = Load.image(paths.secondary_hero),
			secondary_heroine = Load.image(paths.secondary_heroine)
		}
	}

func game():
	var paths = ODResource.paths.game
	return {
		music = {
			default = Load.audio(paths.music)
		}
	}

func elements():
	var result = {
		vendor = {
			food = Load.split_animation(ODResource.paths.element.vendor.food),
			drink = Load.split_animation(ODResource.paths.element.vendor.drink)
		},
		lever = Load.animation(ODResource.paths.element.lever),
		bookshelf = Load.animation(ODResource.paths.element.bookshelf)
	}
	result.lever.set_step_only(true)
	result.bookshelf.set_step_only(true)
	return result

var _tilesets = null

func tilesets():
	if _tilesets != null:
		return _tilesets
	var paths = ODResource.paths.tileset
	_tilesets = {
		basic = Tileset.new(),
		liquids = Tileset.new()
	}
	_tilesets.basic.set_texture(Load.image(paths.basic))
	_tilesets.basic.set_branch(0)
	
	_tilesets.liquids.set_texture(Load.image(paths.liquids))
	# This should be pulled from branchDB instead of hard coded
	_tilesets.liquids.set_animation("water", 0, 2, 3, 250)
	_tilesets.liquids.set_animation("lava", 0, 1, 6, 280)
	_tilesets.liquids.set_animation("ice", 0, 0, 4, 280)
	_tilesets.liquids.set_animation("goo", 0, 3, 3, 300)
	#_tilesets.liquids.set_animation('stars', 0,4,4)
	
	return _tilesets
