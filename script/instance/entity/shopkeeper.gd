extends "res://script/instance/entity/entity.gd"

class_name Shopkeeper

var entity_kind = "monster"
var shop_id = ""
var monster_name = "Brax"
var is_hostile = false
var is_guard = false
var hp = 120
var max_hp = 120
var attack_damage = 10

var _sprites = {}
var _active_sprite = null

func init(keeper_shop_id, target_monster_name = "Brax", start_hostile = false, guard_flag = false):
	shop_id = keeper_shop_id
	monster_name = target_monster_name
	is_hostile = start_hostile
	is_guard = guard_flag
	var monster_def = OD.Database.get_monster(monster_name)
	var palette_path = null
	if monster_def != null and monster_def.has("palette") and typeof(monster_def.palette) == TYPE_DICTIONARY and monster_def.palette.has("name"):
		palette_path = monster_def.palette.name
	var idle_def = monster_def.idleSprite if monster_def != null and monster_def.has("idleSprite") else null
	if idle_def != null:
		for dir_key in ["down", "up", "left", "right"]:
			if idle_def.has(dir_key):
				var anim = OD.Load.animation(idle_def[dir_key], palette_path)
				anim.visible = false
				if anim.is_tall():
					anim.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
				add_child(anim)
				_sprites[dir_key] = anim
	if _sprites.has("down"):
		_active_sprite = _sprites["down"]
		_active_sprite.visible = true
	else:
		var fallback = OD.Load.animation("sprites/monster/brax/brax_run_d.spr")
		if fallback.is_tall():
			fallback.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
		add_child(fallback)
		_active_sprite = fallback
	if monster_name == "Dread Collector":
		hp = 200
		max_hp = 200
		attack_damage = 18

func is_tall():
	return _active_sprite != null and _active_sprite.is_tall()

func set_facing(delta_x, delta_y):
	var dir_key = "down"
	if abs(delta_x) >= abs(delta_y):
		if delta_x < 0:
			dir_key = "left"
		elif delta_x > 0:
			dir_key = "right"
	else:
		if delta_y < 0:
			dir_key = "up"
		else:
			dir_key = "down"
	if _sprites.has(dir_key) and _active_sprite != _sprites[dir_key]:
		if _active_sprite != null:
			_active_sprite.visible = false
		_active_sprite = _sprites[dir_key]
		_active_sprite.visible = true

func teleport_to(target_cell):
	move_to(int(target_cell.x), int(target_cell.y))

func set_hostile(hostile_flag):
	is_hostile = hostile_flag

func step_toward(player_cell, entity_grid):
	if not is_hostile:
		return { acted = false }
	var current_cell = Vector2i(int(_grid_position.x), int(_grid_position.y))
	var dist = max(abs(current_cell.x - player_cell.x), abs(current_cell.y - player_cell.y))
	if dist <= 1:
		set_facing(player_cell.x - current_cell.x, player_cell.y - current_cell.y)
		return {
			acted = true,
			attacked = true,
			damage = attack_damage,
			attacker = monster_name
		}
	var best_step = null
	var best_score = 999999
	for dir_vec in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate = current_cell + dir_vec
		if candidate == player_cell:
			continue
		if not entity_grid.is_walkable(candidate.x, candidate.y):
			continue
		var score = abs(candidate.x - player_cell.x) + abs(candidate.y - player_cell.y)
		if score < best_score:
			best_score = score
			best_step = candidate
	if best_step != null:
		var old_dist = abs(current_cell.x - player_cell.x) + abs(current_cell.y - player_cell.y)
		if best_score <= old_dist:
			set_facing(best_step.x - current_cell.x, best_step.y - current_cell.y)
			move_to(best_step.x, best_step.y)
			return { acted = true, attacked = false }
	return { acted = false }
