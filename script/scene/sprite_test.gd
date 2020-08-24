extends Node2D

static func init_container():
	return Node2D.new()

func _ready():
	call_deferred("_load_sprite")
	
func _load_sprite():	
	
	Database.ingest()
	
	var container = get_node("/root/Container")
	
	var body = Node2D.new()
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
	
	var tilesets = Assets.tilesets()
	var tileset_animation = tilesets.liquids.get_animation('water')
	tileset_animation.name = "TilesetSprite"
	tileset_animation.position = Vector2(300,500)
	body.add_child(tileset_animation)
	tileset_animation.play()

	#var _sprite_palette = Load.sprite_palette("sprites/hero/ghost.pal")
