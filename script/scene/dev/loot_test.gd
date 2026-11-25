extends Control

const InventoryDialogScript = preload("res://script/instance/ui/inventory_dialog.gd")
const MonsterEntityScript = preload("res://script/instance/entity/monster_entity.gd")
const DungeonElementScript = preload("res://script/instance/entity/dungeon_element.gd")

static func init_container():
	return Control.new()

var _player = null
var _inventory_dialog = null
var _summary_label = null
var _log_label = null

func _ready():
	call_deferred("_build_ui")

func _build_ui():
	OD.Audio.setup(get_tree().get_root())
	OD.Database.ingest()
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_hero("heroine")
	OD.DungeonSettings.set_character_name("Artifact Hunter")
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 4, 19, 20, 21])

	_player = PlayerCharacter.new()
	_player.init()
	add_child(_player)
	_player.visible = false
	_player.stats_changed.connect(_refresh_summary)
	_player.inventory_changed.connect(_refresh_summary)

	_seed_initial_loot()

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Loot Generation & Artifacts Verification"
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)

	var open_inv_btn = Button.new()
	open_inv_btn.text = "Open Inventory (Inspect & Equip)"
	open_inv_btn.pressed.connect(open_inventory)
	btn_hbox.add_child(open_inv_btn)

	var roll_f1_btn = Button.new()
	roll_f1_btn.text = "Roll Floor 1 Artifact"
	roll_f1_btn.pressed.connect(func(): _grant_rolled_artifact(1))
	btn_hbox.add_child(roll_f1_btn)

	var roll_f8_btn = Button.new()
	roll_f8_btn.text = "Roll Floor 8 Artifact"
	roll_f8_btn.pressed.connect(func(): _grant_rolled_artifact(8))
	btn_hbox.add_child(roll_f8_btn)

	var check_btn = Button.new()
	check_btn.text = "Run Automated Self-Check"
	check_btn.pressed.connect(_run_self_check)
	btn_hbox.add_child(check_btn)

	var game_btn = Button.new()
	game_btn.text = "Launch Game"
	game_btn.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.GAME))
	btn_hbox.add_child(game_btn)

	_summary_label = Label.new()
	_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_summary_label)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.text = "Ready."
	vbox.add_child(_log_label)

	_refresh_summary()
	_run_self_check()

func _seed_initial_loot():
	for floor_lvl in [1, 4, 8]:
		var art = OD.Database.create_artifact_instance(null, floor_lvl)
		if art != null:
			_player.add_item(art)
	for kind in ["component", "reagent", "gem", "potion", "booze", "wand"]:
		var rolled = OD.Database.roll_floor_loot(3, kind, 0.0)
		if rolled != null and rolled.has("item"):
			_player.add_item(rolled.item)

func _grant_rolled_artifact(floor_lvl):
	var art = OD.Database.create_artifact_instance(null, floor_lvl)
	if art == null:
		_log_label.text = "Failed to generate artifact for floor " + str(floor_lvl)
		return
	var res = _player.add_item(art)
	_log_label.text = "Generated Floor " + str(floor_lvl) + " Artifact: " + str(art.get("name", "")) + " (Q" + str(art.get("artifact_quality", 1)) + ") | Added=" + str(res.added)
	_refresh_summary()

func open_inventory():
	if is_instance_valid(_inventory_dialog):
		return
	_inventory_dialog = InventoryDialogScript.new().init(_player, {
		on_close = func():
			_inventory_dialog = null
	})
	add_child(_inventory_dialog)

func _refresh_summary():
	if _player == null or _summary_label == null:
		return
	var inv_lines = []
	var items = _player.get_inventory_items()
	for idx in range(items.size()):
		var it = items[idx]
		if it != null:
			var tag = " [ART Q" + str(it.get("artifact_quality", 1)) + "]" if bool(it.get("is_artifact", false)) else ""
			inv_lines.append("%s (Lvl %d, %s)%s" % [str(it.get("name", "")), int(it.get("level", 1)), str(it.get("category", "")), tag])
	_summary_label.text = "Primary Stats: " + str(_player.primary_stats) + "\nInventory (" + str(inv_lines.size()) + "):\n- " + "\n- ".join(inv_lines)

func _run_self_check():
	var failures = []

	var f1_weapon = OD.Database.get_loot("weapon", null, 1)
	if f1_weapon == null:
		failures.append("get_loot(weapon, floor 1) returned null")
	else:
		var w1_lvl = int(f1_weapon.get("level", 1))
		if w1_lvl > 3:
			failures.append("Floor 1 weapon level too high: " + str(w1_lvl))

	var f8_armour = OD.Database.get_loot("armour", null, 8)
	if f8_armour == null:
		failures.append("get_loot(armour, floor 8) returned null")
	else:
		var a8_def = OD.Database.get_item(str(f8_armour.get("name", "")))
		if a8_def == null or int(a8_def.get("level", 1)) < 5 or int(a8_def.get("level", 1)) > 10:
			failures.append("Floor 8 armour level out of range: " + str(a8_def.get("level", -1) if a8_def != null else -1))

	var comp = OD.Database.get_loot("component", null, 2)
	var reag = OD.Database.get_loot("reagent", null, 2)
	if comp == null or reag == null:
		failures.append("component or reagent get_loot returned null (comp=" + str(comp != null) + ", reag=" + str(reag != null) + ")")
	elif str(comp.get("name", "")) == str(reag.get("name", "")):
		failures.append("component and reagent returned identical item")

	var art_base = OD.Database.get_item("Crude Iron Sword")
	var proc_art = OD.Database.create_artifact_instance(art_base, 6, 4)
	if proc_art == null:
		failures.append("create_artifact_instance returned null")
	else:
		if not bool(proc_art.get("is_artifact", false)) or int(proc_art.get("artifact_quality", 0)) != 4:
			failures.append("artifact metadata missing on procedural artifact")
		if str(proc_art.get("name", "")) == "Crude Iron Sword":
			failures.append("procedural artifact did not receive a random name")
		var bonus_count = proc_art.primary_buffs.size() + proc_art.secondary_buffs.size() + proc_art.resist_buffs.size() + proc_art.damage_buffs.size()
		if bonus_count == 0 and proc_art.weapon_damage.size() <= 2:
			failures.append("procedural artifact received no bonus stats")

	var uberchest = DungeonElementScript.new()
	uberchest.init("uberchest", null, { floor_level = 5 })
	var chest_res = uberchest.interact()
	if not chest_res.has("granted_item") or chest_res.granted_item == null:
		failures.append("uberchest did not grant an item")

	var evilchest = DungeonElementScript.new()
	evilchest.init("evilchest", null, { floor_level = 5 })
	var evil_res = evilchest.interact()
	if not evil_res.has("granted_item") or evil_res.granted_item == null:
		failures.append("evilchest did not grant an item")

	var pedestal = DungeonElementScript.new()
	pedestal.init("pedestal", null, { floor_level = 5 })
	var ped_res = pedestal.interact()
	if not ped_res.has("granted_item") or ped_res.granted_item == null or not bool(ped_res.granted_item.get("is_artifact", false)):
		failures.append("pedestal did not grant an artifact")

	var mon_def = OD.Database.get_random_monster()
	if mon_def != null:
		var mon = MonsterEntityScript.new()
		mon.init(mon_def, 3)
		var saw_drop = false
		for _ii in range(30):
			if not mon.roll_drops().is_empty():
				saw_drop = true
				break
		if not saw_drop:
			failures.append("monster roll_drops never produced a drop across 30 trials")
		mon.queue_free()

	uberchest.queue_free()
	evilchest.queue_free()
	pedestal.queue_free()

	if failures.is_empty():
		_log_label.text = "ALL LOOT & ARTIFACT CHECKS PASSED!"
		print("[LOOT_TEST] PASS")
	else:
		_log_label.text = "FAILURES: " + "; ".join(failures)
		print("[LOOT_TEST] FAIL: ", failures)
	_refresh_summary()
