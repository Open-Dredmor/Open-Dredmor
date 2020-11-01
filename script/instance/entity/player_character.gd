extends "res://script/instance/entity/entity.gd"

class_name PlayerCharacter

var entity_kind = 'player'

func init():
	add_child(OD.Load.animation(OD.Resource.paths.player.hero.idle.down))
