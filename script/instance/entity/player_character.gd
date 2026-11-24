extends "res://script/instance/entity/entity.gd"

class_name PlayerCharacter

var entity_kind = 'player'

var animations = {}

var current_animation = null

var last_delta_x = 0
var last_delta_y = 0

func update_animation(delta_x, delta_y):
	if last_delta_x != delta_x or last_delta_y != delta_y:
		current_animation.visible = false
		if delta_x != 0:
			if delta_x < 0:
				current_animation = animations.move.left
			else:
				current_animation = animations.move.right
		elif delta_y !=0:
			if delta_y < 0:
				current_animation = animations.move.up
			else:
				current_animation = animations.move.down
		current_animation.visible = true
		last_delta_x = delta_x
		last_delta_y = delta_y

func idle():
	current_animation.visible = false
	if last_delta_x != 0:
		if last_delta_x < 0:
			current_animation = animations.idle.left
		else:
			current_animation = animations.idle.right
	elif last_delta_y !=0:
		if last_delta_y < 0:
			current_animation = animations.idle.up
		else:
			current_animation = animations.idle.down
	current_animation.visible = true

func init():
	animations.move = {
		left = OD.Load.animation(OD.Resources.paths.player.hero.move.left),
		right = OD.Load.animation(OD.Resources.paths.player.hero.move.right),
		up = OD.Load.animation(OD.Resources.paths.player.hero.move.up),
		down = OD.Load.animation(OD.Resources.paths.player.hero.move.down)
	}
	animations.idle = {
		left = OD.Load.animation(OD.Resources.paths.player.hero.idle.left),
		right = OD.Load.animation(OD.Resources.paths.player.hero.idle.right),
		up = OD.Load.animation(OD.Resources.paths.player.hero.idle.up),
		down = OD.Load.animation(OD.Resources.paths.player.hero.idle.down)
	}
	for group in [animations.move, animations.idle]:
		for direction in group.values():
			direction.visible = false
			if direction.is_tall():
				direction.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
			add_child(direction)
	current_animation = animations.idle.down
	current_animation.visible = true
