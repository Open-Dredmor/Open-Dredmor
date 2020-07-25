extends Node2D

func _ready():
	call_deferred("_load_sprite")
	
func _load_sprite():	
	var container = get_node("/root/Container")
	
	var body = KinematicBody2D.new()
	container.add_child(body)
	
	var pm_sprite = Load.sprite_pro_motion("sprites/hero/hero_atk_axe_d.spr")
	#var pm_sprite = Load.sprite_pro_motion("sprites/test.spr")
	pm_sprite.name = "ProMotionSprite"
	pm_sprite.position = Vector2(300,300)
	body.add_child(pm_sprite)
	pm_sprite.play()
	
	var _xml_sprite = Load.sprite_xml("sprites/hero/hero_atk_dagger_d.xml")
	var _sprite_palette = Load.sprite_palette("sprites/hero/ghost.pal")
	pass
