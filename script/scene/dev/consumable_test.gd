extends Control

const InventoryDialogScript = preload("res://script/instance/ui/inventory_dialog.gd")
const BuffBarScript = preload("res://script/instance/ui/buff_bar.gd")

static func init_container():
	return Control.new()

var _player = null
var _inventory_dialog = null
var _buff_bar = null
var _stats_label = null
var _log_label = null

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_hero("heroine")
	OD.DungeonSettings.set_character_name("Consumable Tester")
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 4, 19, 20, 21])

	_player = PlayerCharacter.new()
	_player.init()
	add_child(_player)
	_player.visible = false
	_player.hp = max(1, _player.max_hp - 25)
	_player.mp = max(0, _player.max_mp - 20)
	_player.stats_changed.connect(_refresh_summary)
	_player.buffs_changed.connect(_refresh_summary)
	_player.inventory_changed.connect(_refresh_summary)

	_seed_test_items()

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	_buff_bar = BuffBarScript.new().init(_player)
	container.add_child(_buff_bar)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 20)
	container.add_child(margin)

	var vertical_box = VBoxContainer.new()
	vertical_box.add_theme_constant_override("separation", 12)
	margin.add_child(vertical_box)

	var title = Label.new()
	title.text = "Consumables & Wands Verification"
	title.add_theme_font_size_override("font_size", 26)
	vertical_box.add_child(title)

	var button_horizontal_box = HBoxContainer.new()
	button_horizontal_box.add_theme_constant_override("separation", 10)
	vertical_box.add_child(button_horizontal_box)

	var open_inventory_button = Button.new()
	open_inventory_button.text = "Open Inventory"
	open_inventory_button.pressed.connect(open_inventory)
	button_horizontal_box.add_child(open_inventory_button)

	var tick_button = Button.new()
	tick_button.text = "Tick 1 Turn"
	tick_button.pressed.connect(func():
		_player.tick_status_effects()
		_log_label.text = "Ticked 1 turn. HP=" + str(_player.hp) + "/" + str(_player.max_hp) + " MP=" + str(_player.mp) + "/" + str(_player.max_mp)
		_refresh_summary()
	)
	button_horizontal_box.add_child(tick_button)

	var check_button = Button.new()
	check_button.text = "Run Automated Self-Check"
	check_button.pressed.connect(_run_self_check)
	button_horizontal_box.add_child(check_button)

	var game_button = Button.new()
	game_button.text = "Launch Game"
	game_button.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.GAME))
	button_horizontal_box.add_child(game_button)

	_stats_label = Label.new()
	_stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vertical_box.add_child(_stats_label)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.text = "Ready."
	vertical_box.add_child(_log_label)

	_refresh_summary()
	_run_self_check()

func _seed_test_items():
	var names = [
		"Steak",
		"Lutefisk",
		"Sewer Brew",
		"Grog",
		"Potion of Healing",
		"Potion of Mana",
		"Potion of Steeling",
		"Night Cap",
		"Wand of Tesla",
		"Arcane Wand",
		"Coral Wand"
	]
	for item_name in names:
		var inst = OD.Database.create_item_instance(item_name)
		if inst != null:
			_player.add_item(inst)

func open_inventory():
	if is_instance_valid(_inventory_dialog):
		return
	_inventory_dialog = InventoryDialogScript.new().init(_player, {
		on_use_inventory = func(inv_idx):
			var result = _player.use_consumable_at(inv_idx)
			_log_label.text = "Used item: " + str(result)
			_refresh_summary(),
		on_close = func():
			_inventory_dialog = null
	})
	add_child(_inventory_dialog)

func _refresh_summary():
	if _player == null or _stats_label == null:
		return
	var buff_names = []
	for buff in _player.get_active_buffs():
		buff_names.append(str(buff.get("name", "")) + " (" + str(int(buff.get("remaining_turns", 0))) + "t, x" + str(int(buff.get("stacks", 1))) + ")")
	var inventory_lines = []
	for entry in _player.get_inventory_items():
		var item = entry.item
		var extra = ""
		if str(item.get("category", "")) == "wand":
			extra = " [" + str(int(item.get("charges", 0))) + "/" + str(int(item.get("max_charges", 0))) + " chg]"
		elif int(item.get("count", 1)) > 1:
			extra = " x" + str(int(item.get("count", 1)))
		inventory_lines.append("[" + str(entry.slot_index) + "] " + str(item.get("name", "")) + extra)
	_stats_label.text = (
		"HP: %d/%d  |  MP: %d/%d  |  Magic Power: %d  |  Melee Power: %d  |  Dodge: %d\n" % [
			_player.hp, _player.max_hp, _player.mp, _player.max_mp,
			_player.get_secondary_stat("magic_power"),
			_player.get_secondary_stat("melee_power"),
			_player.get_secondary_stat("dodge_chance")
		]
		+ "Active Buffs: " + (", ".join(buff_names) if not buff_names.is_empty() else "None") + "\n\n"
		+ "Inventory:\n" + "\n".join(inventory_lines)
	)

func _find_slot_by_name(item_name):
	for ii in range(_player.inventory.size()):
		if _player.inventory[ii] != null and str(_player.inventory[ii].get("name", "")) == item_name:
			return ii
	return -1

func _run_self_check():
	var issues = []

	var check_player = PlayerCharacter.new()
	check_player.init()
	add_child(check_player)
	check_player.visible = false
	check_player.hp = 5
	check_player.mp = 2

	var steak = OD.Database.create_item_instance("Steak")
	check_player.add_item(steak)
	var food_result = check_player.use_consumable_at(0)
	if not food_result.get("executed", false) or not check_player.has_buff("Digestion"):
		issues.append("Food did not apply Digestion buff")
	var hp_before_tick = check_player.hp
	check_player.tick_status_effects()
	if check_player.hp <= hp_before_tick:
		issues.append("Food did not restore HP on turn tick")

	var grog = OD.Database.create_item_instance("Grog")
	check_player.add_item(grog)
	var magic_before = check_player.get_secondary_stat("magic_power")
	var booze_result = check_player.use_consumable_at(0)
	if not booze_result.get("executed", false) or not check_player.has_buff("Tipsy"):
		issues.append("Booze did not apply Tipsy buff")
	if check_player.get_secondary_stat("magic_power") <= magic_before:
		issues.append("Tipsy buff did not modify Magic Power")
	var mp_before_tick = check_player.mp
	check_player.tick_status_effects()
	if check_player.mp <= mp_before_tick:
		issues.append("Booze did not restore MP on turn tick")

	var hp_pot = OD.Database.create_item_instance("Potion of Healing")
	check_player.add_item(hp_pot)
	var hp_before_pot = check_player.hp
	var pot_result = check_player.use_consumable_at(0)
	if not pot_result.get("executed", false) or check_player.hp <= hp_before_pot:
		issues.append("Potion of Healing did not restore HP")

	var steel_pot = OD.Database.create_item_instance("Potion of Steeling")
	check_player.add_item(steel_pot)
	check_player.use_consumable_at(0)
	if not check_player.has_buff("Armouring"):
		issues.append("Potion of Steeling did not apply Armouring buff")

	var wand = OD.Database.create_item_instance("Wand of Tesla")
	wand["charges"] = 2
	wand["max_charges"] = 2
	check_player.add_item(wand)
	var wand_res1 = check_player.use_consumable_at(0)
	if not wand_res1.get("executed", false) or int(wand_res1.get("remaining_charges", -1)) != 1:
		issues.append("Wand first cast did not decrement charges to 1")
	if not check_player.has_buff("Voltaic Empowerment"):
		issues.append("Wand of Tesla did not apply Voltaic Empowerment buff")
	var wand_res2 = check_player.use_consumable_at(0)
	if not wand_res2.get("executed", false) or not wand_res2.get("burned_out", false):
		issues.append("Wand did not burn out at 0 charges")
	if check_player.inventory[0] != null:
		issues.append("Burned out wand was not removed from inventory")

	check_player.queue_free()

	if issues.is_empty():
		_log_label.text = "ALL SELF-CHECKS PASSED (food HP/turn, booze MP/turn + Tipsy, potion spells, wand charges & burnout)."
		print("CONSUMABLE_TEST_PASS")
	else:
		_log_label.text = "SELF-CHECK FAILED:\n- " + "\n- ".join(issues)
		print("CONSUMABLE_TEST_FAIL: " + "; ".join(issues))
