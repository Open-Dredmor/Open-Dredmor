extends Node2D

class_name PlayerCharacter

var entity_kind = 'player'

func init():
	add_child(Load.animation(ODResource.paths.player.hero.idle.down))