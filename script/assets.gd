extends Node

func button_paths(start):
	return {
		"normal": start + "0.png",
		"hover": start + "1.png",
		"pressed":start + "2.png"	
	}

func button_images(lookup):
	var images = {}
	for key in lookup.keys():
		images[key] = Load.image(lookup[key])
	return images

var _assets = {
	"main_menu": {
		"backgrounds": [
			"ui/dredmor_main_big_org.png",
			"expansion/ui/dredmor_main_big.png",
			"expansion2/ui/dredmor_main_big.png",
			"expansion3/ui/dredmor_main_big.png"
		],
		"chrome": "ui/menus/main_menubg.png",		
		"button": {
			"new_game": button_paths("ui/menus/main_newgame"),
			"load_game": button_paths("ui/menus/main_loadgame"),
			"quit": button_paths("ui/menus/main_quit"),
			"cycle_background": button_paths("ui/menus/main_bg_button"),			
		},
		"music": "tunes/finaltitle.ogg",
	}
}

func main_menu_backgrounds():	
	var images = []
	for path in _assets.main_menu.backgrounds:
		images.append(Load.image(path))
	return images

func main_menu_chrome():
	return Load.image(_assets.main_menu.chrome)

func main_menu_new_game_button():
	return button_images(_assets.main_menu.button.new_game)

func main_menu_load_game_button():
	return button_images(_assets.main_menu.button.load_game)

func main_menu_quit_button():
	return button_images(_assets.main_menu.button.quit)
	
func main_menu_background_button():
	return button_images(_assets.main_menu.button.cycle_background)

func main_menu_music():
	return Load.audio(_assets.main_menu.music)
