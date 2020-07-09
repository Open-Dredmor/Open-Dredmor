extends Node

var _assets = {
	"main_menu_backgrounds": [
		"ui/dredmor_main_big_org.png",
		"expansion/ui/dredmor_main_big.png",
		"expansion2/ui/dredmor_main_big.png",
		"expansion3/ui/dredmor_main_big.png"
	],
	"main_menu_cycle_button": {
		"normal":"ui/menus/main_bg_button0.png",
		"hover":"ui/menus/main_bg_button1.png",
		"pressed":"ui/menus/main_bg_button2.png"
	},
	"main_menu_music": "tunes/finaltitle.ogg"
}

func main_menu_backgrounds():	
	var images = []
	for path in _assets.main_menu_backgrounds:
		images.append(Load.image(path))
	return images

func main_menu_button():
	var images = {}
	for key in _assets.main_menu_cycle_button.keys():
		images[key] = Load.image(_assets.main_menu_cycle_button[key])
	return images
	
func main_menu_music():
	return Load.audio(_assets.main_menu_music)
