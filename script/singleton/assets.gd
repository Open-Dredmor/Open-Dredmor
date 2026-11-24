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
	var paths = OD.Resources.paths.main_menu
	var background_entries = []
	for entry in paths.backgrounds:
		if OD.Load.exists(entry.image):
			var subtitle_texture = null
			if entry.subtitle != null and OD.Load.exists(entry.subtitle):
				subtitle_texture = OD.Load.image(entry.subtitle)
			background_entries.append({
				image = OD.Load.image(entry.image),
				subtitle = subtitle_texture
			})
	
	var textures = {		
		backgrounds = background_entries,
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

func load_game_menu():
	var paths = OD.Resources.paths.load_game_menu
	return {
		textures = {
			header_background = OD.Load.image(OD.Resources.paths.shared.header_background),
			back_button = _button_textures(OD.Resources.paths.shared.button.back),
			done_button = _button_textures(OD.Resources.paths.shared.button.done),
			load_header = OD.Load.image(paths.header),
			info_panel = OD.Load.image(paths.info_panel),
			delete_button = _button_textures(paths.delete_button)
		},
		fonts = {
			default = OD.Load.font(OD.Resources.paths.shared.font.default)
		}
	}

func high_scores_menu():
	return {
		textures = {
			header_background = OD.Load.image(OD.Resources.paths.shared.header_background),
			back_button = _button_textures(OD.Resources.paths.shared.button.back)
		},
		fonts = {
			default = OD.Load.font(OD.Resources.paths.shared.font.default)
		}
	}
	
func difficulty_menu():
	var paths = OD.Resources.paths.difficulty_menu
	var textures = {
		options_form = OD.Load.image(paths.options_form),
		checkmark_large = OD.Load.image(paths.checkmark_large),
		checkmark_small = OD.Load.image(paths.checkmark_small),
		done_button = _button_textures(OD.Resources.paths.shared.button.done),
		back_button = _button_textures(OD.Resources.paths.shared.button.back),
		choose_header = OD.Load.image(paths.choose_header),
		header_background = OD.Load.image(OD.Resources.paths.shared.header_background)
	}
	return {
		textures = textures
	}

func skills_menu():
	var paths = OD.Resources.paths.skills_menu
	var textures = {
		done_button = _button_textures(OD.Resources.paths.shared.button.done),
		back_button = _button_textures(OD.Resources.paths.shared.button.back),
		header_background = OD.Load.image(OD.Resources.paths.shared.header_background),
		skills_header = OD.Load.image(paths.skills_header),
		skill_button_border = OD.Load.image(paths.skill_button_border),
		selected_skills_background = OD.Load.image(paths.selected_skills_background),
		selected_skill_info_background = OD.Load.image(paths.selected_skill_info_background),
		last_selection_button = _button_textures(paths.last_selection),
		random_selection_button = _button_textures(paths.random_selection)
	}
	var fonts = {
		info_header = OD.Load.font(OD.Resources.paths.shared.font.default),
		info_details = OD.Load.font(OD.Resources.paths.shared.font.default),
	}
	var font_sizes = {
		info_header = 25,
		info_details = 20,
	}
	return {
		textures = textures,
		fonts = fonts,
		font_sizes = font_sizes
	}

func character_menu():
	var paths = OD.Resources.paths.character_menu
	var textures = {
		done_button = _button_textures(OD.Resources.paths.shared.button.done),
		back_button = _button_textures(OD.Resources.paths.shared.button.back),
		header_background = OD.Load.image(OD.Resources.paths.shared.header_background),
		character_header = OD.Load.image(paths.character_header),
		choose_name_background = OD.Load.image(paths.choose_name_background),
		choose_hero_background = OD.Load.image(paths.choose_hero_background),
		hero_portrait = OD.Load.image(paths.hero_portrait),
		heroine_portrait = OD.Load.image(paths.heroine_portrait)
	}
	
	var fonts = {
		name_edit = OD.Load.font(OD.Resources.paths.shared.font.default)
	}
	var font_sizes = {
		name_edit = 25
	}
	
	return {
		textures = textures,
		fonts = fonts,
		font_sizes = font_sizes
	}
	
func intro():
	var paths = OD.Resources.paths.intro
	return {
		textures = {
			primary = OD.Load.image(paths.primary),
			secondary_hero = OD.Load.image(paths.secondary_hero),
			secondary_heroine = OD.Load.image(paths.secondary_heroine)
		}
	}

func game():
	var paths = OD.Resources.paths.game
	return {
		music = {
			default = OD.Load.audio(paths.music)
		}
	}

func elements():
	var result = {
		anvil = OD.Load.animation(OD.Resources.paths.element.anvil),
		bookshelf = OD.Load.animation(OD.Resources.paths.element.bookshelf),
		dredmor_statue = OD.Load.animation(OD.Resources.paths.element.dredmor_statue),
		lever = OD.Load.animation(OD.Resources.paths.element.lever),
		lutefisk_statue = OD.Load.animation(OD.Resources.paths.element.lutefisk_statue),
		statues = [],
		vendor = {
			bolt = OD.Load.split_animation(OD.Resources.paths.element.vendor.bolt),
			craft = OD.Load.split_animation(OD.Resources.paths.element.vendor.craft),
			drink = OD.Load.split_animation(OD.Resources.paths.element.vendor.drink),
			food = OD.Load.split_animation(OD.Resources.paths.element.vendor.food),
			thrown = OD.Load.split_animation(OD.Resources.paths.element.vendor.thrown)		
		},
		
	}
	result.lever.set_step_only(true)
	result.bookshelf.set_step_only(true)
	for statue in OD.Resources.paths.element.statues:
		result.statues.append(OD.Load.animation(statue))
	return result

func element(element_type):
	var element_paths = OD.Resources.paths.element
	match element_type:
		"anvil":
			return OD.Load.animation(element_paths.anvil)
		"boltvending":
			return OD.Load.split_animation(element_paths.vendor.bolt)
		"bookshelf":
			var bookshelf_anim = OD.Load.animation(element_paths.bookshelf)
			bookshelf_anim.set_step_only(true)
			return bookshelf_anim
		"craftvending":
			return OD.Load.split_animation(element_paths.vendor.craft)
		"dredmorstatue":
			return OD.Load.animation(element_paths.dredmor_statue)
		"drinkvending":
			return OD.Load.split_animation(element_paths.vendor.drink)
		"foodvending":
			return OD.Load.split_animation(element_paths.vendor.food)
		"lever":
			var lever_anim = OD.Load.animation(element_paths.lever)
			lever_anim.set_step_only(true)
			return lever_anim
		"lutefiskstatue":
			return OD.Load.animation(element_paths.lutefisk_statue)
		"statue":
			return OD.Load.animation(OD.DataStructure.choose(element_paths.statues))
		"thrownvending":
			return OD.Load.split_animation(element_paths.vendor.thrown)
		_:
			return null

var _tilesets = null
var _branch_tilesets = {}

func tilesets():
	if _tilesets != null:
		return _tilesets
	var paths = OD.Resources.paths.tileset
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

func tileset_for_branch(branch_id):
	if _branch_tilesets.has(branch_id):
		return _branch_tilesets[branch_id]
	var base_tilesets = tilesets()
	if branch_id == 0:
		_branch_tilesets[branch_id] = base_tilesets
		return base_tilesets
	var branch_info = OD.Database.get_branch_info(branch_id)
	if branch_info == null or branch_info.tileset == "" or not OD.Load.exists(branch_info.tileset):
		_branch_tilesets[branch_id] = base_tilesets
		return base_tilesets
	var branch_tileset = Tileset.new()
	branch_tileset.set_texture(OD.Load.image(branch_info.tileset))
	branch_tileset.set_branch(branch_id)
	var result = {
		basic = branch_tileset,
		liquids = base_tilesets.liquids
	}
	_branch_tilesets[branch_id] = result
	return result

var _dialog_assets = null

func dialog():
	if _dialog_assets != null:
		return _dialog_assets
	var paths = OD.Resources.paths.shared.dialog
	_dialog_assets = {
		textures = {
			alert = OD.Load.image(paths.alert),
			alert_bigger = OD.Load.image(paths.alert_bigger),
			lutefisk_bg = OD.Load.image(paths.lutefisk_bg),
			krong_pleased = OD.Load.image(paths.krong_pleased),
			krong_displeased = OD.Load.image(paths.krong_displeased),
			close = _button_textures(paths.close),
			ok = _button_textures(paths.ok),
			buy = _button_textures(paths.buy),
			awesome = _button_textures(paths.awesome),
			shucks = _button_textures(paths.shucks)
		},
		font = OD.Load.font(OD.Resources.paths.shared.font.default)
	}
	return _dialog_assets
