extends Node

class_name TurnScheduler

enum State {
	WAITING_FOR_INPUT,
	PLAYER_PHASE,
	WORLD_PHASE
}

const DEFAULT_BASE_TURN_SECONDS = 0.5
const MIN_GAME_SPEED = 0.25
const MAX_GAME_SPEED = 20.0

signal turn_started(turn_number)
signal player_phase_completed(turn_number)
signal world_phase_completed(turn_number, summary)
signal turn_completed(turn_number, summary)
signal state_changed(new_state)

var turn_count = 0
var state = State.WAITING_FOR_INPUT

var _command_processor = null
var _base_turn_seconds = DEFAULT_BASE_TURN_SECONDS
var _game_speed_override = -1.0
var _phase_timer = Timer.new()
var _active_context = {}
var _cancel_auto_requested = false
var _cooldowns = {}
var _status_effects = []
var _regen_targets = {}

func _ready():
	_phase_timer.one_shot = true
	_phase_timer.timeout.connect(_on_phase_timeout)
	add_child(_phase_timer)

func init(command_processor, base_turn_seconds = DEFAULT_BASE_TURN_SECONDS):
	_command_processor = command_processor
	_base_turn_seconds = max(0.0, float(base_turn_seconds))
	return self

func set_base_turn_seconds(seconds):
	_base_turn_seconds = max(0.0, float(seconds))

func get_base_turn_seconds():
	return _base_turn_seconds

func set_game_speed(speed_multiplier):
	var clamped = clamp(float(speed_multiplier), MIN_GAME_SPEED, MAX_GAME_SPEED)
	_game_speed_override = clamped
	if OD.Settings != null and OD.Settings.has_method("set_game_speed"):
		OD.Settings.set_game_speed(clamped)
	return clamped

func get_game_speed():
	if _game_speed_override > 0.0:
		return _game_speed_override
	if OD.Settings != null and OD.Settings.has_method("get_game_speed"):
		return OD.Settings.get_game_speed()
	return 1.0

func get_phase_duration():
	return (_base_turn_seconds * 0.5) / max(0.01, get_game_speed())

func is_accepting_input():
	return state == State.WAITING_FOR_INPUT

func is_busy():
	return state != State.WAITING_FOR_INPUT

func is_auto_stepping():
	return OD.ActionQueue != null and OD.ActionQueue.has_pending()

func _set_state(new_state):
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)

func cancel_auto_actions():
	_cancel_auto_requested = true
	if OD.ActionQueue != null:
		OD.ActionQueue.clear()

func submit_command(command, context):
	if state != State.WAITING_FOR_INPUT:
		return { executed = false, consumes_turn = false, rejected_busy = true, message = "" }
	if _command_processor == null:
		return { executed = false, consumes_turn = false, message = "" }
	_cancel_auto_requested = false
	var result = _command_processor.submit(command, context)
	if result == null or typeof(result) != TYPE_DICTIONARY or not result.get("executed", false):
		_set_state(State.WAITING_FOR_INPUT)
		return result if result != null else { executed = false, consumes_turn = false, message = "" }
	if result.get("starts_action_queue", false) or (OD.ActionQueue != null and OD.ActionQueue.has_pending()):
		_active_context = context
		_begin_player_phase_from_queue()
		return result
	if result.get("consumes_turn", false):
		_active_context = context
		turn_started.emit(turn_count + 1)
		_set_state(State.PLAYER_PHASE)
		_schedule_phase_tick()
		return result
	_set_state(State.WAITING_FOR_INPUT)
	return result

func start_queued_actions(context):
	if OD.ActionQueue == null or not OD.ActionQueue.has_pending():
		return
	_cancel_auto_requested = false
	_active_context = context
	if state == State.WAITING_FOR_INPUT:
		_begin_player_phase_from_queue()

func _begin_player_phase_from_queue():
	if _cancel_auto_requested or OD.ActionQueue == null or not OD.ActionQueue.has_pending():
		_cancel_auto_requested = false
		_set_state(State.WAITING_FOR_INPUT)
		return
	var stepped = OD.ActionQueue.step_once()
	if stepped:
		turn_started.emit(turn_count + 1)
		_set_state(State.PLAYER_PHASE)
		_schedule_phase_tick()
	else:
		_set_state(State.WAITING_FOR_INPUT)

func _schedule_phase_tick():
	var duration = get_phase_duration()
	if duration <= 0.001 or not is_inside_tree():
		_on_phase_timeout()
		return
	_phase_timer.stop()
	_phase_timer.wait_time = duration
	_phase_timer.start()

func _on_phase_timeout():
	if state == State.PLAYER_PHASE:
		player_phase_completed.emit(turn_count + 1)
		_set_state(State.WORLD_PHASE)
		advance_turn(_active_context)
		_schedule_phase_tick()
		return
	if state == State.WORLD_PHASE:
		if not _cancel_auto_requested and OD.ActionQueue != null and OD.ActionQueue.has_pending():
			_begin_player_phase_from_queue()
			return
		_cancel_auto_requested = false
		_set_state(State.WAITING_FOR_INPUT)

func advance_turn(context):
	turn_count += 1
	var monsters_acted = _advance_monsters(context)
	var traps_ticked = _advance_traps(context)
	var cooldowns_ticked = _advance_cooldowns(context)
	var regen_ticked = _advance_regen(context)
	var effects_ticked = _advance_status_effects(context)
	var summary = {
		turn = turn_count,
		monsters_acted = monsters_acted,
		traps_ticked = traps_ticked,
		cooldowns_ticked = cooldowns_ticked,
		regen_ticked = regen_ticked,
		effects_ticked = effects_ticked
	}
	world_phase_completed.emit(turn_count, summary)
	turn_completed.emit(turn_count, summary)
	return summary

func _advance_monsters(context):
	var entity_grid = context.get("entity_grid", null)
	var player = context.get("player", null)
	if entity_grid == null or player == null or not is_instance_valid(player):
		return 0
	var player_pos = player.get_grid_position()
	if player_pos == null:
		return 0
	if entity_grid.has_method("step_monsters"):
		return int(entity_grid.step_monsters(player_pos))
	if entity_grid.shop_manager != null:
		entity_grid.shop_manager.step_hostile_actors(entity_grid, player_pos)
		return 1
	return 0

func _advance_traps(context):
	var entity_grid = context.get("entity_grid", null)
	if entity_grid != null and entity_grid.has_method("tick_traps"):
		return int(entity_grid.tick_traps())
	return 0

func set_cooldown(cooldown_id, turns):
	if turns <= 0:
		_cooldowns.erase(cooldown_id)
	else:
		_cooldowns[cooldown_id] = int(turns)

func get_cooldown(cooldown_id):
	return int(_cooldowns.get(cooldown_id, 0))

func get_all_cooldowns():
	return _cooldowns.duplicate()

func _advance_cooldowns(context):
	var ticked = 0
	var keys = _cooldowns.keys()
	for cooldown_id in keys:
		var remaining = int(_cooldowns[cooldown_id]) - 1
		ticked += 1
		if remaining <= 0:
			_cooldowns.erase(cooldown_id)
		else:
			_cooldowns[cooldown_id] = remaining
	var player = context.get("player", null)
	if player != null and is_instance_valid(player) and player.has_method("tick_cooldowns"):
		ticked += int(player.tick_cooldowns())
	return ticked

func register_regen_target(target_id, target_obj, hp_interval = 10, mp_interval = 10):
	_regen_targets[target_id] = {
		target = target_obj,
		hp_interval = max(1, int(hp_interval)),
		mp_interval = max(1, int(mp_interval)),
		hp_counter = 0,
		mp_counter = 0
	}

func _advance_regen(context):
	var ticked = 0
	for target_id in _regen_targets.keys():
		var entry = _regen_targets[target_id]
		var target_obj = entry.target
		if target_obj == null or not is_instance_valid(target_obj):
			continue
		ticked += 1
		entry.hp_counter += 1
		if entry.hp_counter >= entry.hp_interval:
			entry.hp_counter = 0
			if target_obj.has_method("regenerate_hp"):
				target_obj.regenerate_hp(1)
		entry.mp_counter += 1
		if entry.mp_counter >= entry.mp_interval:
			entry.mp_counter = 0
			if target_obj.has_method("regenerate_mp"):
				target_obj.regenerate_mp(1)
	var player = context.get("player", null)
	if player != null and is_instance_valid(player) and player.has_method("tick_regen"):
		ticked += int(player.tick_regen(turn_count))
	return ticked

func add_status_effect(effect_def):
	if effect_def == null or typeof(effect_def) != TYPE_DICTIONARY:
		return
	var entry = effect_def.duplicate()
	if not entry.has("remaining_turns"):
		entry["remaining_turns"] = int(entry.get("duration", 1))
	_status_effects.append(entry)

func get_status_effects():
	return _status_effects.duplicate(true)

func clear_status_effects():
	_status_effects.clear()

func _advance_status_effects(context):
	var ticked = 0
	var ii = 0
	while ii < _status_effects.size():
		var effect = _status_effects[ii]
		ticked += 1
		if effect.has("on_tick") and effect.on_tick is Callable:
			effect.on_tick.call(effect, turn_count)
		effect.remaining_turns = int(effect.remaining_turns) - 1
		if effect.remaining_turns <= 0:
			if effect.has("on_expire") and effect.on_expire is Callable:
				effect.on_expire.call(effect, turn_count)
			_status_effects.remove_at(ii)
		else:
			ii += 1
	var player = context.get("player", null)
	if player != null and is_instance_valid(player) and player.has_method("tick_status_effects"):
		ticked += int(player.tick_status_effects())
	var entity_grid = context.get("entity_grid", null)
	if entity_grid != null and entity_grid.has_method("tick_status_effects"):
		ticked += int(entity_grid.tick_status_effects())
	return ticked
