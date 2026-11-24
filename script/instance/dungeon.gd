extends Node2D

class_name Dungeon

const ElementDialogScript = preload("res://script/instance/ui/element_dialog.gd")

var floors = []
# TODO Use ID instead of name
var _branch_name = "The Dungeon"
var _floor_level = 1
var _entity_grid
var _target_cursor
var _player

var FLOOR_STRATEGY = {
	CONNECT_DOORS = "connect_doors",
	DEBUG_ROOMS = "debug_rooms",
	ALL_ROOMS = "all_rooms",
	CENTER_PACK = "center_pack"
}

var _active_strategy = FLOOR_STRATEGY.DEBUG_ROOMS
var _zorkmids_ref = { value = 150 }
var _lutefisk_ref = { value = 10 }
var _interaction_dialog = null

func global_coordinates_to_grid(x, y):
	var xform = get_global_transform_with_canvas()
	var scale_vec = xform.get_scale()
	var local_x = (x - xform.origin.x) / scale_vec.x
	var local_y = (y - xform.origin.y) / scale_vec.y
	var grid_x = floor((local_x + (OD.Assets.CELL_PIXEL_WIDTH / 2.0)) / OD.Assets.CELL_PIXEL_WIDTH)
	var grid_y = floor((local_y + (OD.Assets.CELL_PIXEL_HEIGHT / 2.0)) / OD.Assets.CELL_PIXEL_HEIGHT)
	return Vector2(grid_x, grid_y)
func init():	
	call_deferred("_build_ui")

func _input(ev):
	if is_instance_valid(_interaction_dialog):
		if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
			_close_element_dialog()
		return
	if ev is InputEventKey and ev.is_pressed():
		if ev.keycode == KEY_SPACE and not ev.echo:
			OD.Scenes.goto(OD.Scenes.GAME)
	if ev is InputEventMouseMotion:
		if _target_cursor != null and _entity_grid != null and ! _target_cursor.is_selecting():
			var grid_coords = global_coordinates_to_grid(ev.position.x, ev.position.y)
			_entity_grid.move(grid_coords.x, grid_coords.y, _target_cursor)
	if ev is InputEventMouseButton and ev.pressed and _target_cursor != null:
		var grid_coords = global_coordinates_to_grid(ev.position.x, ev.position.y)
		if ev.button_index == MOUSE_BUTTON_RIGHT and _active_strategy == FLOOR_STRATEGY.DEBUG_ROOMS:
			OD.ActionQueue.clear()
			_target_cursor.select(grid_coords.x, grid_coords.y)
			_player.move_to(grid_coords.x, grid_coords.y)
			_player.idle()
			if _entity_grid != null:
				_entity_grid.evaluate_scripts(_player.get_grid_position())
			return
		if ev.button_index != MOUSE_BUTTON_LEFT:
			return
		var door = _entity_grid.get_door_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if door != null and not door.can_pass():
			door.interact()
			return
		var element = _entity_grid.get_element_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if element != null and not element.is_broken:
			_handle_element_interaction(element, grid_coords)
			return
		var trap = _entity_grid.get_trap_at(grid_coords.x, grid_coords.y) if _entity_grid != null else null
		if trap != null and trap.is_discovered and not trap.is_disarmed:
			_handle_trap_disarm(trap)
			return
		if _entity_grid != null and not _entity_grid.is_walkable(grid_coords.x, grid_coords.y):
			return
		_target_cursor.select(grid_coords.x, grid_coords.y)
		OD.ActionQueue.clear()
		var action = OD.Actions.MoveToLocation.new()
		action.init(_player, grid_coords, _entity_grid)
		OD.ActionQueue.add(action)

func _build_ui():
	var strategy = _active_strategy
	_player = PlayerCharacter.new()	
	_player.init()
	var settings = OD.DungeonSettings.get_settings()
	_entity_grid = load("res://script/instance/room_placement/" + strategy + "_strategy.gd").generate(_branch_name, _floor_level)
	_entity_grid.name = "EntityGrid-"+strategy+"_strategy"
	_entity_grid.add_entity(settings.player_start_x, settings.player_start_y, _player)
	add_child(_entity_grid)
	_target_cursor = TargetCursor.new()
	_target_cursor.init()
	_entity_grid.add_entity(0, 0, _target_cursor)
	_entity_grid.update_trap_visibility(_player.get_grid_position())
	_entity_grid.trap_triggered.connect(_on_trap_triggered)

func _on_trap_triggered(trap_result, grid_pos):
	_spawn_spell_vfx(trap_result.casts_spell, grid_pos)
	_spawn_floating_text(grid_pos, trap_result.trap_name + "!", Color(1.0, 0.35, 0.25))

func _handle_trap_disarm(trap):
	var disarm_res = trap.attempt_disarm()
	var pos = trap.get_grid_position()
	if disarm_res.success:
		_spawn_floating_text(pos, "Disarmed!", Color(0.45, 0.95, 0.45))
	else:
		if disarm_res.has("triggered") and disarm_res.triggered != null:
			_spawn_spell_vfx(disarm_res.triggered.casts_spell, pos)
		_spawn_floating_text(pos, "Trap Triggered!", Color(1.0, 0.35, 0.25))

func _spawn_spell_vfx(spell_name, grid_pos):
	if spell_name == "" or _entity_grid == null:
		return
	var spell = OD.Database.get_spell(spell_name)
	if spell == null or spell.anim == null or typeof(spell.anim) != TYPE_DICTIONARY:
		return
	var anim_def = spell.anim
	if anim_def.has("sfx"):
		OD.Audio.play_sfx(anim_def.sfx)
	if anim_def.has("sprite") and anim_def.has("frames"):
		var first_idx = int(anim_def.get("first", 0))
		var frame_count = int(anim_def.frames)
		var frame_rate = int(anim_def.get("framerate", 80))
		var vfx = OD.Load.png_sprite(anim_def.sprite, first_idx, first_idx + frame_count, frame_rate)
		if vfx != null:
			var px = OD.Math.grid_to_pixel(grid_pos.x, grid_pos.y)
			_entity_grid.add_animation(px.x, px.y, "player", vfx)
			vfx.animation_complete.connect(func():
				if is_instance_valid(vfx):
					vfx.queue_free()
			)

func _spawn_floating_text(grid_pos, text, color):
	if _entity_grid == null:
		return
	var label = Label.new()
	label.text = text
	var px = OD.Math.grid_to_pixel(grid_pos.x, grid_pos.y)
	label.position = px + Vector2(-80, -32)
	label.custom_minimum_size = Vector2(160, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OD.Assets.dialog().font)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_entity_grid.get_layer("player").add_child(label)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

func _close_element_dialog():
	if is_instance_valid(_interaction_dialog):
		_interaction_dialog.queue_free()
		_interaction_dialog = null

func _handle_element_interaction(element, grid_coords):
	_close_element_dialog()
	_interaction_dialog = ElementDialogScript.new()
	add_child(_interaction_dialog)
	_interaction_dialog.show_element_dialog(
		element,
		_zorkmids_ref,
		_lutefisk_ref,
		func(): _interaction_dialog = null,
		func(): _entity_grid.unblock_cell(grid_coords.x, grid_coords.y)
	)
		
