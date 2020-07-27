extends Node2D

func _ready():
	call_deferred("_load_sprite")
	
func _load_sprite():	
	var container = get_node("/root/Container")
	
	var body = KinematicBody2D.new()
	container.add_child(body)
	
	var pm_sprite = Load.animation("sprites/hero/hero_atk_axe_d.spr")
	pm_sprite.name = "ProMotionSprite"
	pm_sprite.position = Vector2(300,300)
	body.add_child(pm_sprite)
	pm_sprite.play()
	
	var xml_sprite = Load.animation("sprites/hero/hero_atk_dagger_d.xml")
	xml_sprite.name = "XmlSprite"
	xml_sprite.position = Vector2(500,500)
	body.add_child(xml_sprite)
	xml_sprite.play()

	#var _sprite_palette = Load.sprite_palette("sprites/hero/ghost.pal")
