extends RefCounted

static func get_facing_dir_key(player):
	if abs(player.last_delta_x) >= abs(player.last_delta_y):
		if player.last_delta_x < 0:
			return "left"
		if player.last_delta_x > 0:
			return "right"
	if player.last_delta_y < 0:
		return "up"
	return "down"

static func face_towards(player, target_cell):
	var current_position = player.get_grid_position()
	if current_position == null or target_cell == null:
		return
	var delta_x = int(target_cell.x) - int(current_position.x)
	var delta_y = int(target_cell.y) - int(current_position.y)
	if delta_x == 0 and delta_y == 0:
		return
	player.last_delta_x = delta_x
	player.last_delta_y = delta_y
	idle(player)

static func get_or_load_action_anim(player, group_key, direction_key):
	if not player.animations.has(group_key):
		player.animations[group_key] = {}
	var group = player.animations[group_key]
	if group.has(direction_key):
		return group[direction_key]
	var sprite_paths = OD.Resources.paths.player.heroine if player.hero_kind == "heroine" else OD.Resources.paths.player.hero
	if not sprite_paths.has(group_key):
		return null
	var group_paths = sprite_paths[group_key]
	var resolved_key = direction_key
	if not group_paths.has(resolved_key):
		if group_paths.has("right"):
			resolved_key = "right"
		elif group_paths.has("down"):
			resolved_key = "down"
		else:
			return null
	if group.has(resolved_key):
		return group[resolved_key]
	var animation_node = OD.Load.animation(group_paths[resolved_key])
	if animation_node == null:
		return null
	animation_node.visible = false
	if animation_node.is_tall():
		animation_node.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
	player.add_child(animation_node)
	group[resolved_key] = animation_node
	return animation_node

static func play_action_animation(player, group_key, duration_sec = 0.28, return_to_idle = true):
	if player.animations.is_empty():
		return
	var direction_key = get_facing_dir_key(player)
	var animation = get_or_load_action_anim(player, group_key, direction_key)
	if animation == null:
		return
	player._action_animation_token += 1
	var active_token = player._action_animation_token
	if player.current_animation != null:
		player.current_animation.visible = false
	player.current_animation = animation
	player.current_animation.visible = true
	if player.current_animation.has_method("stop"):
		player.current_animation.stop()
	if player.current_animation.has_method("play"):
		player.current_animation.play()
	if not return_to_idle or not player.is_inside_tree():
		return
	var idle_tween = player.create_tween()
	idle_tween.tween_interval(duration_sec)
	idle_tween.tween_callback(func():
		if is_instance_valid(player) and not player.is_dead and player._action_animation_token == active_token and not player.is_moving():
			idle(player)
	)

static func resolve_melee_attack_group(player):
	for slot_name in ["weapon_right", "weapon_left"]:
		var item = player.equipment.get(slot_name, null)
		if item != null and typeof(item) == TYPE_DICTIONARY and item.get("category", "") == "weapon":
			match int(item.get("type", -1)):
				0:
					return "attack_sword"
				1:
					return "attack_axe"
				2:
					return "attack_mace"
				3:
					return "attack_staff"
				4:
					return "attack_bow"
				5:
					return "attack_thrown"
				7:
					return "attack_dagger"
				8:
					return "attack_polearm"
	return "attack_unarm"

static func update_animation(player, delta_x, delta_y):
	if player.animations.is_empty():
		return
	var next_animation = player.current_animation
	if delta_x != 0:
		next_animation = player.animations.move.left if delta_x < 0 else player.animations.move.right
	elif delta_y != 0:
		next_animation = player.animations.move.up if delta_y < 0 else player.animations.move.down
	if next_animation != player.current_animation:
		if player.current_animation != null:
			player.current_animation.visible = false
		player.current_animation = next_animation
		if player.current_animation != null:
			player.current_animation.visible = true
	player.last_delta_x = delta_x
	player.last_delta_y = delta_y

static func idle(player):
	if player.animations.is_empty():
		return
	if player.current_animation != null:
		player.current_animation.visible = false
	if player.last_delta_x != 0:
		if player.last_delta_x < 0:
			player.current_animation = player.animations.idle.left
		else:
			player.current_animation = player.animations.idle.right
	elif player.last_delta_y != 0:
		if player.last_delta_y < 0:
			player.current_animation = player.animations.idle.up
		else:
			player.current_animation = player.animations.idle.down
	if player.current_animation != null:
		player.current_animation.visible = true

static func load_sprite_animations(player):
	var sprite_paths = OD.Resources.paths.player.heroine if player.hero_kind == "heroine" else OD.Resources.paths.player.hero
	player.animations.move = {
		left = OD.Load.animation(sprite_paths.move.left),
		right = OD.Load.animation(sprite_paths.move.right),
		up = OD.Load.animation(sprite_paths.move.up),
		down = OD.Load.animation(sprite_paths.move.down)
	}
	player.animations.idle = {
		left = OD.Load.animation(sprite_paths.idle.left),
		right = OD.Load.animation(sprite_paths.idle.right),
		up = OD.Load.animation(sprite_paths.idle.up),
		down = OD.Load.animation(sprite_paths.idle.down)
	}
	for group in [player.animations.move, player.animations.idle]:
		for direction in group.values():
			if direction == null:
				continue
			direction.visible = false
			if direction.is_tall():
				direction.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
			player.add_child(direction)
	player.current_animation = player.animations.idle.down
	if player.current_animation != null:
		player.current_animation.visible = true
