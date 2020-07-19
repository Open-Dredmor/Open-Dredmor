extends Node

func button_paths(start):
	return {
		"normal": start + "0.png",
		"hover": start + "1.png",
		"pressed":start + "2.png"	
	}

func button_images(lookup,internal=false):
	var images = {}
	for key in lookup.keys():
		if Load.exists(lookup[key],internal):
			images[key] = Load.image(lookup[key], internal)
	return images

var _assets = {
	main_menu = {
		backgrounds = [
			"ui/dredmor_main_big_org.png",
			"expansion/ui/dredmor_main_big.png",
			"expansion2/ui/dredmor_main_big.png",
			"expansion3/ui/dredmor_main_big.png"
		],
		title = "ui/menus/main_titletext.png",
		subtitles = [
			# Vanilla has no subtitle
			"expansion/ui/rotdg_title_small2.png",
			# At first glance, the second expansion subtitle isn't baked
			"expansion3/ui/cotw_title.png"
		],
		chrome = "ui/menus/main_menubg.png",		
		button = {
			new_game = button_paths("ui/menus/main_newgame"),
			load_game = button_paths("ui/menus/main_loadgame"),
			high_scores = button_paths("ui/menus/main_highscores"),
			settings = button_paths("menu/main_settings"),
			quit = button_paths("ui/menus/main_quit"),
			cycle_background = button_paths("ui/menus/main_bg_button"),			
		},
		music = "tunes/finaltitle.ogg",
	},
	difficulty_menu = {
		options_form = "ui/menus/panel_choosedifficulty107.png",
		checkmark_large = "ui/menus/difficulty_x.png",
		checkmark_small = "ui/menus/difficulty_x_small.png",
		choose_header = "ui/menus/title_choosedifficulty.png"
	},
	skills_menu = {
		skills_header = "ui/menus/title_chooseskills.png",
		skill_button_border = "ui/menus/panel_skilliconbox.png",
		selected_skills_background = "ui/menus/selected_skills_panel.png",
		selected_skill_info_background ="ui/menus/skillchoose_skillinfo_bg.png",
		random_selection = button_paths("ui/menus/skills_random"),
		last_selection = button_paths("ui/menus/skills_last")
	},
	shared = {
		button = {
			back = button_paths("ui/skillselect_back"),
			done = button_paths("ui/skillselect_done"),		
		},
		header_background = "ui/menus/topbar_horz_tile_bg.png",
		font = {
			default = "fonts/Austin.ttf"
		}
	}
}

func main_menu():	
	var paths = _assets.main_menu
	var background_images = []
	for file in paths.backgrounds:
		background_images.append(Load.image(file))
	
	var textures = {		
		backgrounds = background_images,
		title = Load.image(paths.title),
		chrome = Load.image(paths.chrome),
		new_game_button = button_images(paths.button.new_game),
		load_game_button = button_images(paths.button.load_game),
		high_scores_button = button_images(paths.button.high_scores),
		settings_button = button_images(paths.button.settings, true),
		quit_button = button_images(paths.button.quit),		
		background_button = button_images(paths.button.cycle_background),
	}	
	
	var music = {
		title = Load.audio(paths.music)
	}
	return {
		textures = textures,
		music = music
	}
	
func difficulty_menu():
	var paths = _assets.difficulty_menu
	var textures = {
		options_form = Load.image(paths.options_form),
		checkmark_large = Load.image(paths.checkmark_large),
		checkmark_small = Load.image(paths.checkmark_small),
		done_button = button_images(_assets.shared.button.done),
		back_button = button_images(_assets.shared.button.back),
		choose_header = Load.image(paths.choose_header),
		header_background = Load.image(_assets.shared.header_background)
	}
	return {
		textures = textures
	}

func skills_menu():
	var paths = _assets.skills_menu
	var textures = {
		done_button = button_images(_assets.shared.button.done),
		back_button = button_images(_assets.shared.button.back),
		header_background = Load.image(_assets.shared.header_background),
		skills_header = Load.image(paths.skills_header),
		skill_button_border = Load.image(paths.skill_button_border),
		selected_skills_background = Load.image(paths.selected_skills_background),
		selected_skill_info_background = Load.image(paths.selected_skill_info_background),
		last_selection_button = button_images(paths.last_selection),
		random_selection_button = button_images(paths.random_selection)
	}
	var fonts = {
		info_header = Load.font(_assets.shared.font.default, 36),
		info_details = Load.font(_assets.shared.font.default, 20),
	}
	return {
		textures = textures,
		fonts = fonts
	}
