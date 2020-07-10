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
		chrome = "ui/menus/main_menubg.png",		
		button = {
			new_game = button_paths("ui/menus/main_newgame"),
			load_game = button_paths("ui/menus/main_loadgame"),
			settings = button_paths("menu/main_settings"),
			quit = button_paths("ui/menus/main_quit"),
			cycle_background = button_paths("ui/menus/main_bg_button"),			
		},
		music = "tunes/finaltitle.ogg",
	},
	difficulty_menu = {
		options_form = "ui/menus/panel_choosedifficulty107.png",
		checkmark_large = "ui/menus/difficulty_x.png",
		checkmark_small = "difficulty_x_small.png"
	}
}

func main_menu():	
	var background_images = []
	for file in _assets.main_menu.backgrounds:
		background_images.append(Load.image(file))
	
	var textures = {
		chrome = Load.image(_assets.main_menu.chrome),
		new_game_button = button_images(_assets.main_menu.button.new_game),
		load_game_button = button_images(_assets.main_menu.button.load_game),
		settings_button = button_images(_assets.main_menu.button.settings, true),
		quit_button = button_images(_assets.main_menu.button.quit),
		background_button = button_images(_assets.main_menu.button.cycle_background),
		backgrounds = background_images	
	}	
	
	var music = {
		title = Load.audio(_assets.main_menu.music)
	}
	return {
		textures = textures,
		music = music
	}
