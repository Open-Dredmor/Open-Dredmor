extends Control

const InventoryDialogScript = preload("res://script/instance/ui/inventory_dialog.gd")

static func init_container():
	return Control.new()

var _player = null
var _floor_loot = []
var _inventory_dialog = null
var _stats_label = null
var _floor_label = null
var _log_label = null

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_hero("heroine")
	OD.DungeonSettings.set_character_name("Test Adventurer")
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 4, 19, 20, 21])

	_player = PlayerCharacter.new()
	_player.init()
	add_child(_player)
	_player.visible = false
	_player.stats_changed.connect(_refresh_summary)
	_player.equipment_changed.connect(_refresh_summary)
	_player.inventory_changed.connect(_refresh_summary)

	_seed_test_items()

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Inventory & Equipment Verification"
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)

	var open_inv_btn = Button.new()
	open_inv_btn.text = "Open Inventory (I)"
	open_inv_btn.pressed.connect(open_inventory)
	btn_hbox.add_child(open_inv_btn)

	var pickup_btn = Button.new()
	pickup_btn.text = "Pick Up Floor Item"
	pickup_btn.pressed.connect(_pickup_next_floor_item)
	btn_hbox.add_child(pickup_btn)

	var self_check_btn = Button.new()
	self_check_btn.text = "Run Automated Self-Check"
	self_check_btn.pressed.connect(_run_self_check)
	btn_hbox.add_child(self_check_btn)

	var game_btn = Button.new()
	game_btn.text = "Launch Game"
	game_btn.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.GAME))
	btn_hbox.add_child(game_btn)

	var split_hbox = HBoxContainer.new()
	split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(split_hbox)

	_stats_label = Label.new()
	_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	split_hbox.add_child(_stats_label)

	_floor_label = Label.new()
	_floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	split_hbox.add_child(_floor_label)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.text = "Ready. Press 'Open Inventory (I)' to inspect/equip/drop items."
	vbox.add_child(_log_label)

	_refresh_summary()
	open_inventory()
	_run_self_check()

func _seed_test_items():
	var candidate_names = [
		"Crude Iron Sword",
		"Rough Bronze Aspis",
		"Wooden Crossbow",
		"Wooden Bolt",
		"Throwing Axe",
		"Spectacles",
		"Leather Cuirass",
		"Padded Trousers",
		"Leather Boots",
		"Leather Gloves",
		"Bronze Ring",
		"Silver Ring",
		"Amulet of Vitality",
		"Leather Belt",
		"Lutefisk",
		"Lutefisk",
		"Potion of Healing"
	]
	for item_name in candidate_names:
		var inst = OD.Database.create_item_instance(item_name)
		if inst != null:
			_player.add_item(inst)

	var floor_candidates = ["Bronze Sword", "Potion of Healing", "Amber", "Copper Bolt"]
	for f_name in floor_candidates:
		var inst = OD.Database.create_item_instance(f_name, 3 if f_name == "Copper Bolt" else 1)
		if inst != null:
			_floor_loot.append(inst)

func open_inventory():
	if is_instance_valid(_inventory_dialog):
		return
	_inventory_dialog = InventoryDialogScript.new().init(_player, {
		on_drop_inventory = func(inv_idx, count):
			var removed = _player.remove_item_at(inv_idx, count)
			if removed != null:
				_floor_loot.append(removed)
				_log_label.text = "Dropped " + str(removed.get("name", "Item")) + " x" + str(removed.get("count", 1)) + " to floor."
				_refresh_summary(),
		on_drop_equipped = func(slot_name):
			var equipped = _player.get_equipped_item(slot_name)
			if equipped != null:
				_player.equipment[slot_name] = null
				_player.recalculate_stats()
				_player.equipment_changed.emit()
				_floor_loot.append(equipped)
				_log_label.text = "Dropped equipped " + str(equipped.get("name", "Item")) + " to floor."
				_refresh_summary(),
		on_pickup = _pickup_next_floor_item,
		on_close = func():
			_inventory_dialog = null
	})
	add_child(_inventory_dialog)

func _pickup_next_floor_item():
	if _floor_loot.is_empty():
		_log_label.text = "No floor items remaining."
		return
	var next_item = _floor_loot[0]
	var res = _player.add_item(next_item)
	if res.added:
		if res.remaining > 0:
			next_item["count"] = res.remaining
		else:
			_floor_loot.remove_at(0)
		_log_label.text = "Picked up " + str(next_item.get("name", "Item")) + "!"
	else:
		_log_label.text = "Inventory is full!"
	_refresh_summary()

func _refresh_summary():
	if _player == null or _stats_label == null:
		return
	var equip_lines = []
	for slot_name in PlayerCharacter.EQUIPMENT_SLOTS:
		var eq = _player.get_equipped_item(slot_name)
		equip_lines.append(slot_name + ": " + (str(eq.get("name", "")) if eq != null else "(empty)"))
	_stats_label.text = "HP: %d/%d | MP: %d/%d | Armour: %d | Block: %d | Melee: %d\n\nEquipped:\n%s" % [
		_player.hp, _player.max_hp, _player.mp, _player.max_mp,
		_player.get_secondary_stat("armour_absorption"),
		_player.get_secondary_stat("block_chance"),
		_player.get_secondary_stat("melee_power"),
		"\n".join(equip_lines)
	]
	var floor_lines = ["Floor Loot (" + str(_floor_loot.size()) + "):"]
	for item in _floor_loot:
		floor_lines.append("- " + str(item.get("name", "Item")) + " x" + str(item.get("count", 1)))
	_floor_label.text = "\n".join(floor_lines)

func _input(ev):
	if ev is InputEventKey and ev.is_pressed() and not ev.echo and ev.keycode == KEY_I:
		if is_instance_valid(_inventory_dialog):
			_inventory_dialog.dismiss()
		else:
			open_inventory()

func _run_self_check():
	var test_player = PlayerCharacter.new()
	test_player.init()
	var lutefisk_a = OD.Database.create_item_instance("Lutefisk", 2)
	var lutefisk_b = OD.Database.create_item_instance("Lutefisk", 3)
	test_player.add_item(lutefisk_a)
	test_player.add_item(lutefisk_b)
	var stack_ok = test_player.inventory[0] != null and int(test_player.inventory[0].count) == 5 and test_player.inventory[1] == null

	var base_armour = test_player.get_secondary_stat("armour_absorption")
	var helm = OD.Database.create_item_instance("Spectacles")
	var add_helm = test_player.add_item(helm)
	test_player.equip_from_inventory(add_helm.slot_index)
	var stats_updated = test_player.get_equipped_item("head") != null and test_player.get_secondary_stat("visual_sight_radius") >= 8

	var ring_a = OD.Database.create_item_instance("Bronze Ring")
	var ring_b = OD.Database.create_item_instance("Silver Ring")
	if ring_a != null and ring_b != null:
		var r1 = test_player.add_item(ring_a)
		var r2 = test_player.add_item(ring_b)
		test_player.equip_from_inventory(r1.slot_index)
		test_player.equip_from_inventory(r2.slot_index)
	var rings_ok = test_player.get_equipped_item("ring_left") != null and test_player.get_equipped_item("ring_right") != null

	test_player.free()
	var msg = "Self-check -> Stack=%s, EquipStats=%s (baseArmour=%d), 2xRings=%s" % [str(stack_ok), str(stats_updated), base_armour, str(rings_ok)]
	_log_label.text = msg
	print(msg)
