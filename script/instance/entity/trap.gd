extends "res://script/instance/entity/entity.gd"

class_name Trap

var entity_kind = "trap"
var trap_name = "Trap"
var trap_level = 1
var casts_spell = ""
var trigger_mode = "once"
var is_discovered = false
var is_disarmed = false
var is_triggered = false
var cooldown_turns = 0

var _animation = null

func init(trap_def):
	if trap_def != null:
		trap_name = trap_def.get("name", "Trap")
		var raw_trap = trap_def.raw.get("trap", {}) if trap_def.has("raw") and typeof(trap_def.raw) == TYPE_DICTIONARY else {}
		if typeof(raw_trap) == TYPE_DICTIONARY:
			trap_level = int(raw_trap.get("level", trap_def.get("level", 1)))
			casts_spell = raw_trap.get("casts", "")
			trigger_mode = raw_trap.get("trigger", "once")
		var icon_path = trap_def.get("icon", "")
		if icon_path != "" and OD.Load.exists(icon_path):
			_animation = OD.Load.animation(icon_path)
	if _animation == null:
		_animation = OD.Load.animation(OD.Resources.paths.traps[0])
	add_child(_animation)
	visible = false

func update_visibility(player_pos, trap_sight_radius = 2, trap_sense_level = 1):
	if is_disarmed:
		visible = false
		return
	if is_discovered:
		visible = true
		return
	var pos = get_grid_position()
	if pos == null:
		return
	var dist = max(abs(int(pos.x) - int(player_pos.x)), abs(int(pos.y) - int(player_pos.y)))
	if dist <= trap_sight_radius and trap_sense_level + 1 >= trap_level:
		is_discovered = true
		visible = true

func step_on():
	if is_disarmed or (trigger_mode == "once" and is_triggered):
		return null
	is_triggered = true
	is_discovered = true
	visible = true
	OD.Audio.play_sfx("click")
	if trigger_mode == "once":
		is_disarmed = true
	else:
		cooldown_turns = 1
	return {
		trap_name = trap_name,
		casts_spell = casts_spell,
		trigger_mode = trigger_mode
	}

func tick_turn():
	if is_disarmed:
		return false
	if cooldown_turns > 0:
		cooldown_turns -= 1
		if cooldown_turns <= 0 and trigger_mode != "once":
			is_triggered = false
		return true
	return false

func attempt_disarm(trap_affinity = 1):
	if is_disarmed:
		return { success = true, picked_up = false, message = "Trap is already disarmed." }
	if trap_affinity + (randi() % 4) >= trap_level:
		is_disarmed = true
		visible = false
		OD.Audio.play_sfx("click")
		return {
			success = true,
			picked_up = true,
			trap_name = trap_name,
			message = "Disarmed and recovered: " + trap_name
		}
	var trigger_res = step_on()
	return {
		success = false,
		triggered = trigger_res,
		message = "Failed to disarm " + trap_name + "! Triggered " + casts_spell + "!"
	}
