extends Node

var CELL_PIXEL_HEIGHT = 32
var CELL_PIXEL_WIDTH = 32

func _button_textures(lookup,internal=false):
	var images = {}
	for key in lookup.keys():
		if OD.Load.exists(lookup[key],internal):
			images[key] = OD.Load.image(lookup[key], internal)
	return images

func main_menu():	
	var paths = OD.Resource.paths.main_menu
	var background_images = []
	for file in paths.backgrounds:
		background_images.append(OD.Load.image(file))
	
	var textures = {		
		backgrounds = background_images,
		title = OD.Load.image(paths.title),
		chrome = OD.Load.image(paths.chrome),
		new_game_button = _button_textures(paths.button.new_game),
		load_game_button = _button_textures(paths.button.load_game),
		high_scores_button = _button_textures(paths.button.high_scores),
		settings_button = _button_textures(paths.button.settings, true),
		quit_button = _button_textures(paths.button.quit),		
		background_button = _button_textures(paths.button.cycle_background),
	}	
	
	var music = {
		title = OD.Load.audio(paths.music)
	}
	return {
		textures = textures,
		music = music
	}
	
func difficulty_menu():
	var paths = OD.Resource.paths.difficulty_menu
	var textures = {
		options_form = OD.Load.image(paths.options_form),
		checkmark_large = OD.Load.image(paths.checkmark_large),
		checkmark_small = OD.Load.image(paths.checkmark_small),
		done_button = _button_textures(OD.Resource.paths.shared.button.done),
		back_button = _button_textures(OD.Resource.paths.shared.button.back),
		choose_header = OD.Load.image(paths.choose_header),
		header_background = OD.Load.image(OD.Resource.paths.shared.header_background)
	}
	return {
		textures = textures
	}

func skills_menu():
	var paths = OD.Resource.paths.skills_menu
	var textures = {
		done_button = _button_textures(OD.Resource.paths.shared.button.done),
		back_button = _button_textures(OD.Resource.paths.shared.button.back),
		header_background = OD.Load.image(OD.Resource.paths.shared.header_background),
		skills_header = OD.Load.image(paths.skills_header),
		skill_button_border = OD.Load.image(paths.skill_button_border),
		selected_skills_background = OD.Load.image(paths.selected_skills_background),
		selected_skill_info_background = OD.Load.image(paths.selected_skill_info_background),
		last_selection_button = _button_textures(paths.last_selection),
		random_selection_button = _button_textures(paths.random_selection)
	}
	var fonts = {
		info_header = OD.Load.font(OD.Resource.paths.shared.font.default, 25),
		info_details = OD.Load.font(OD.Resource.paths.shared.font.default, 20),
	}
	return {
		textures = textures,
		fonts = fonts
	}

func character_menu():
	var paths = OD.Resource.paths.character_menu
	var textures = {
		done_button = _button_textures(OD.Resource.paths.shared.button.done),
		back_button = _button_textures(OD.Resource.paths.shared.button.back),
		header_background = OD.Load.image(OD.Resource.paths.shared.header_background),
		character_header = OD.Load.image(paths.character_header),
		choose_name_background = OD.Load.image(paths.choose_name_background),
		choose_hero_background = OD.Load.image(paths.choose_hero_background),
		hero_portrait = OD.Load.image(paths.hero_portrait),
		heroine_portrait = OD.Load.image(paths.heroine_portrait)
	}
	
	var fonts = {
		name_edit = OD.Load.font(OD.Resource.paths.shared.font.default, 25)
	}
	
	return {
		textures = textures,
		fonts = fonts
	}
	
func intro():
	var paths = OD.Resource.paths.intro
	return {
		textures = {
			primary = OD.Load.image(paths.primary),
			secondary_hero = OD.Load.image(paths.secondary_hero),
			secondary_heroine = OD.Load.image(paths.secondary_heroine)
		}
	}

func game():
	var paths = OD.Resource.paths.game
	return {
		music = {
			default = OD.Load.audio(paths.music)
		}
	}

func elements():
	var result = {
		anvil = OD.Load.animation(OD.Resource.paths.element.anvil),
		bookshelf = OD.Load.animation(OD.Resource.paths.element.bookshelf),
		dredmor_statue = OD.Load.animation(OD.Resource.paths.element.dredmor_statue),
		lever = OD.Load.animation(OD.Resource.paths.element.lever),
		lutefisk_statue = OD.Load.animation(OD.Resource.paths.element.lutefisk_statue),
		statues = [],
		vendor = {
			bolt = OD.Load.split_animation(OD.Resource.paths.element.vendor.bolt),
			craft = OD.Load.split_animation(OD.Resource.paths.element.vendor.craft),
			drink = OD.Load.split_animation(OD.Resource.paths.element.vendor.drink),
			food = OD.Load.split_animation(OD.Resource.paths.element.vendor.food),
			thrown = OD.Load.split_animation(OD.Resource.paths.element.vendor.thrown)		
		},
		
	}
	result.lever.set_step_only(true)
	result.bookshelf.set_step_only(true)
	for statue in OD.Resource.paths.element.statues:
		result.statues.append(OD.Load.animation(statue))
	return result

var _tilesets = null

func tilesets():
	if _tilesets != null:
		return _tilesets
	var paths = OD.Resource.paths.tileset
	_tilesets = {
		basic = Tileset.new(),
		liquids = Tileset.new()
	}
	_tilesets.basic.set_texture(OD.Load.image(paths.basic))
	_tilesets.basic.set_branch(0)
	
	_tilesets.liquids.set_texture(OD.Load.image(paths.liquids))
	# This should be pulled from branchDB instead of hard coded
	_tilesets.liquids.set_animation("water", 0, 2, 3, 250)
	_tilesets.liquids.set_animation("lava", 0, 1, 6, 280)
	_tilesets.liquids.set_animation("ice", 0, 0, 4, 280)
	_tilesets.liquids.set_animation("goo", 0, 3, 3, 300)
	#_tilesets.liquids.set_animation('stars', 0,4,4)
	
	return _tilesets
