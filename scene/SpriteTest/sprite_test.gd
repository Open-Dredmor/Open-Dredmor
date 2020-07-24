extends Node2D

func _ready():
	call_deferred("_load_sprite")
	
func _load_sprite():	
	var container = get_node("/root/Container")
	
	#var _pm_sprite = Load.sprite_pro_motion("sprites/hero/hero_atk_axe_d.spr")
	var _pm_sprite = Load.sprite_pro_motion("sprites/test.spr")
	container.add_child(_pm_sprite)
	
	var _xml_sprite = Load.sprite_xml("sprites/hero/hero_atk_dagger_d.xml")
	var _sprite_palette = Load.sprite_palette("sprites/hero/ghost.pal")
	pass
