extends Node

func _button_paths(start):
	return {
		normal = start + "0.png",
		hover = start + "1.png",
		pressed = start + "2.png"	
	}

var paths = {
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
			new_game = _button_paths("ui/menus/main_newgame"),
			load_game = _button_paths("ui/menus/main_loadgame"),
			high_scores = _button_paths("ui/menus/main_highscores"),
			settings = _button_paths("menu/main_settings"),
			quit = _button_paths("ui/menus/main_quit"),
			cycle_background = _button_paths("ui/menus/main_bg_button"),			
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
		random_selection = _button_paths("ui/menus/skills_random"),
		last_selection = _button_paths("ui/menus/skills_last")
	},
	character_menu = {
		character_header = "ui/menus/title_choosename.png",
		choose_name_background = "ui/menus/panel_choosename.png",
		choose_hero_background = "ui/menus/panel_choosehero.png",
		hero_portrait = "ui/portrait/portrait_100_stare.png",
		heroine_portrait = "ui/portrait/portraitf_100_stare.png"
	},
	intro = {
		primary = "ui/dredmor_intro1.png",
		secondary_hero = "ui/dredmor_intro2.png",
		secondary_heroine = "ui/dredmor_intro2_fem.png"
	},
	game = {
		music = "tunes/spelunk-repeat.ogg"		
	},
	loot = {
		lockpick = 'items/lockpick.png',
		zorkmids = [
			'items/cash0.png',
			'items/cash1.png',
			'items/cash2.png',
			'items/cash3.png',
			'items/cash4.png',
			'items/cash5.png',
		],
	},
	pedestal = "dungeon/pedestal_empty.spr",
	traps = [
		'dungeon/trap_pressure_plate0.png',
		'dungeon/trap_mine.png',
		'dungeon/trap_magic0.png',
		'dungeon/trap_slime0.png',
		'dungeon/trap_wall_gargoyle0.png'
	],
	element = {
		anvil = "dungeon/statue_anvil.spr",
		bookshelf = "dungeon/bookshelf.spr",
		dredmor_statue = "dungeon/statue_dredmor.png",
		lever = "dungeon/lever1.spr",
		lutefisk_statue = "dungeon/shrine_lutefisk_god.png",
		statues = [
			'dungeon/statue_book.spr',
			'dungeon/statue_cake.spr',
			'dungeon/statue_coffee.spr',
			'dungeon/statue_fish.spr',
			'dungeon/statue_fork.spr',
			'dungeon/statue_fruit.spr',
			'dungeon/statue_gears.spr',
			'dungeon/statue_hammer.spr',
			'dungeon/statue_mandrill.spr',
			'dungeon/statue_penguin.spr',
			'dungeon/statue_quest.spr',
		],
		vendor = {
			bolt = [
				'dungeon/dispenser_bolts0000.png',
				'dungeon/dispenser_bolts0001.png'
			],
			craft = [
				'dungeon/dispenser_crafts0000.png',
				'dungeon/dispenser_crafts0001.png'
			],
			drink = [
				'dungeon/dispenser_drink0000.png',
				'dungeon/dispenser_drink0001.png'
			],
			food = [
				'dungeon/dispenser_food0000.png',
				'dungeon/dispenser_food0001.png'
			],
			thrown = [
				'dungeon/dispenser_thrown0000.png',
				'dungeon/dispenser_thrown0001.png'
			],
		}		
	},
	tileset = {
			basic = "tilesets/basic.png",
			liquids = "tilesets/liquids.png"
	},
	player = {
		hero = {
			idle = {
				down = "sprites/hero/hero_idle_d.spr"
			}
		}
	},
	shared = {
		button = {
			back = _button_paths("ui/skillselect_back"),
			done = _button_paths("ui/skillselect_done"),		
		},
		header_background = "ui/menus/topbar_horz_tile_bg.png",
		font = {
			default = "fonts/Austin.ttf"
		}
	}
}
