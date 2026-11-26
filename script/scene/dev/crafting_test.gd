extends Control

const CraftingDialogScript = preload("res://script/instance/ui/crafting_dialog.gd")
const InventoryDialogScript = preload("res://script/instance/ui/inventory_dialog.gd")

static func init_container():
	return Control.new()

var _player = null
var _crafting_dialog = null
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
	OD.DungeonSettings.set_character_name("Master Crafter")
	OD.DungeonSettings.set_starting_skill_ids([0, 1, 2, 4, 19, 20, 21])

	_player = PlayerCharacter.new()
	_player.init()
	_player.bonus_secondary_stats["smithing_level"] = 1
	_player.bonus_secondary_stats["alchemy_level"] = 1
	_player.bonus_secondary_stats["tinkering_level"] = 1
	_player.bonus_secondary_stats["wandcrafting_level"] = 1
	_player.recalculate_stats()
	add_child(_player)
	_player.visible = false
	_player.inventory_changed.connect(_refresh_summary)

	_seed_crafting_gear()

	var container = OD.Scenes.container()
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	container.add_child(margin)

	var vertical_box = VBoxContainer.new()
	vertical_box.add_theme_constant_override("separation", 12)
	margin.add_child(vertical_box)

	var title = Label.new()
	title.text = "Crafting System Verification"
	title.add_theme_font_size_override("font_size", 26)
	vertical_box.add_child(title)

	var button_horizontal_box = HBoxContainer.new()
	button_horizontal_box.add_theme_constant_override("separation", 10)
	vertical_box.add_child(button_horizontal_box)

	var open_craft_button = Button.new()
	open_craft_button.text = "Open Crafting Workbench"
	open_craft_button.pressed.connect(func(): open_crafting("", "craft"))
	button_horizontal_box.add_child(open_craft_button)

	var open_encrust_button = Button.new()
	open_encrust_button.text = "Open Encrusting Workbench"
	open_encrust_button.pressed.connect(func(): open_crafting("smithing", "encrust"))
	button_horizontal_box.add_child(open_encrust_button)

	var open_inventory_button = Button.new()
	open_inventory_button.text = "Open Inventory"
	open_inventory_button.pressed.connect(open_inventory)
	button_horizontal_box.add_child(open_inventory_button)

	var check_button = Button.new()
	check_button.text = "Run Automated Self-Check"
	check_button.pressed.connect(_run_self_check)
	button_horizontal_box.add_child(check_button)

	var game_button = Button.new()
	game_button.text = "Launch Game"
	game_button.pressed.connect(func(): OD.Scenes.goto(OD.Scenes.GAME))
	button_horizontal_box.add_child(game_button)

	_summary_label = Label.new()
	_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vertical_box.add_child(_summary_label)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.text = "Ready."
	vertical_box.add_child(_log_label)

	_refresh_summary()
	_run_self_check()

func _seed_crafting_gear():
	var seed_list = [
		["My Little Anvil Junior Smithing Kit", 1],
		["Modular Alchemy Box", 1],
		["Porta-Still", 1],
		["Disposable Ingot Press", 1],
		["Elven Ingot Grinder", 1],
		["Tinkerer Parts", 1],
		["n-Dimensional Lathe", 1],
		["Native Iron", 4],
		["Hematite", 4],
		["Bituminous Coal", 6],
		["Iron Ingot", 4],
		["Copper Ingot", 4],
		["Plastic Ingot", 6],
		["Apple", 4],
		["Brass Mechanism", 2],
		["Brimstone", 2],
		["Saltpetre", 2],
		["Burnt Out Wand", 1],
		["Gold Ingot", 2],
		["Iron Sword", 1],
		["Brass Ring", 1]
	]
	for pair in seed_list:
		var inst = OD.Database.create_item_instance(pair[0], pair[1])
		if inst != null:
			_player.add_item(inst)

func open_crafting(tool_tag = "", mode = "craft"):
	if is_instance_valid(_crafting_dialog):
		return
	_crafting_dialog = CraftingDialogScript.new().init(_player, tool_tag, {
		mode = mode,
		on_close = func():
			_crafting_dialog = null
	})
	add_child(_crafting_dialog)

func open_inventory():
	if is_instance_valid(_inventory_dialog):
		return
	_inventory_dialog = InventoryDialogScript.new().init(_player, {
		on_use_inventory = func(inv_idx):
			var item = _player.inventory[inv_idx]
			if item != null and str(item.get("category", "")) == "toolkit":
				var tag = OD.Database.get_toolkit_tag_for_item(item)
				_inventory_dialog.dismiss()
				_inventory_dialog = null
				open_crafting(tag),
		on_close = func():
			_inventory_dialog = null
	})
	add_child(_inventory_dialog)

func _refresh_summary():
	if _player == null or _summary_label == null:
		return
	var possessed = _player.get_possessed_toolkits()
	var inventory_lines = []
	for entry in _player.get_inventory_items():
		var item = entry.get("item", null)
		if item != null:
			inventory_lines.append("%s x%d" % [str(item.get("name", "")), int(item.get("count", 1))])
	_summary_label.text = "Possessed Tools: " + str(possessed.keys()) + "\nSkills: Smith=" + str(_player.get_crafting_skill_level("smithing")) + " Tinker=" + str(_player.get_crafting_skill_level("tinkerer")) + " Alch=" + str(_player.get_crafting_skill_level("alchemy")) + " Wand=" + str(_player.get_crafting_skill_level("lathe")) + "\nInventory:\n- " + "\n- ".join(inventory_lines)

func _run_self_check():
	var failures = []

	var possessed = _player.get_possessed_toolkits()
	for expected_tool in ["smithing", "alchemy", "still", "ingot", "grinder", "tinkerer", "lathe"]:
		if not possessed.has(expected_tool):
			failures.append("Missing possessed toolkit: " + expected_tool)

	var ingot_recipes = OD.Database.get_crafts_by_tool("ingot")
	var iron_recipe = null
	for rec in ingot_recipes:
		if not rec.outputs.is_empty() and str(rec.outputs[0].get("name", "")) == "Iron Ingot":
			iron_recipe = rec
			break
	if iron_recipe == null:
		failures.append("Could not find Iron Ingot recipe")
	else:
		var before_iron = _player.count_item_in_inventory("Iron Ingot")
		var craft_result = _player.craft_recipe(iron_recipe)
		if not craft_result.ok:
			failures.append("Failed to craft Iron Ingot: " + str(craft_result.get("reason", "")))
		elif _player.count_item_in_inventory("Iron Ingot") <= before_iron:
			failures.append("Iron Ingot count did not increase after crafting")

	var still_recipes = OD.Database.get_crafts_by_tool("still")
	var cider_recipe = null
	for rec in still_recipes:
		if not rec.outputs.is_empty() and str(rec.outputs[0].get("name", "")) == "Hard Cider":
			cider_recipe = rec
			break
	if cider_recipe == null:
		failures.append("Could not find Hard Cider still recipe")
	else:
		var before_cider = _player.count_item_in_inventory("Hard Cider")
		var still_result = _player.craft_recipe(cider_recipe)
		if not still_result.ok:
			failures.append("Failed to distill Hard Cider: " + str(still_result.get("reason", "")))
		elif _player.count_item_in_inventory("Hard Cider") <= before_cider:
			failures.append("Hard Cider count did not increase after distilling")

	var smith_recipes = OD.Database.get_crafts_by_tool("smithing")
	var boots_recipe = null
	for rec in smith_recipes:
		if not rec.outputs.is_empty() and str(rec.outputs[0].get("name", "")) == "Copper Plate Boots":
			boots_recipe = rec
			break
	if boots_recipe == null:
		failures.append("Could not find Copper Plate Boots smithing recipe")
	else:
		var before_boots = _player.count_item_in_inventory("Copper Plate Boots")
		var smith_result = _player.craft_recipe(boots_recipe)
		if not smith_result.ok:
			failures.append("Failed to smith Copper Plate Boots: " + str(smith_result.get("reason", "")))
		elif _player.count_item_in_inventory("Copper Plate Boots") <= before_boots:
			failures.append("Copper Plate Boots count did not increase after smithing")

	var encrust_definition = OD.Database.get_encrust("Polymer Shell")
	if encrust_definition == null:
		failures.append("Could not find Polymer Shell encrust")
	else:
		var test_sword = null
		for entry in _player.get_inventory_items():
			var inventory_item = entry.get("item", null)
			if inventory_item != null and str(inventory_item.get("base_name", inventory_item.get("name", ""))) == "Iron Sword":
				test_sword = inventory_item
				break
		if test_sword == null:
			failures.append("Missing Iron Sword for encrust test")
		else:
			var enc_result = _player.encrust_item(encrust_definition, test_sword)
			if not enc_result.ok:
				failures.append("Failed to encrust Iron Sword: " + str(enc_result.get("reason", "")))
			elif not ("Polymer Shell" in test_sword.get("encrusts", [])):
				failures.append("Iron Sword missing Polymer Shell encrust record")

	var lathe_recipes = OD.Database.get_crafts_by_tool("lathe")
	var bling_recipe = null
	for rec in lathe_recipes:
		if not rec.outputs.is_empty() and str(rec.outputs[0].get("name", "")) == "Wand of Bling":
			bling_recipe = rec
			break
	if bling_recipe == null:
		failures.append("Could not find Wand of Bling recipe")
	else:
		_player.bonus_secondary_stats["wandcrafting_level"] = 0
		_player.recalculate_stats()
		var low_check = _player.can_craft_recipe(bling_recipe)
		if low_check.ok:
			failures.append("Should not allow crafting Wand of Bling at wandcrafting_level 0")
		_player.bonus_secondary_stats["wandcrafting_level"] = 1
		_player.recalculate_stats()
		var slot_craft = _player.craft_from_slots("lathe", ["Gold Ingot", "Burnt Out Wand"])
		if not slot_craft.ok:
			failures.append("craft_from_slots failed for Wand of Bling: " + str(slot_craft.get("reason", "")))

	var hidden_recipe = null
	for rec in OD.Database.get_all_crafts():
		if bool(rec.get("hidden", false)):
			hidden_recipe = rec
			break
	if hidden_recipe != null:
		if _player.knows_recipe(hidden_recipe):
			failures.append("Player should not know hidden recipe before learning it")
		_player.learn_recipe(hidden_recipe)
		if not _player.knows_recipe(hidden_recipe):
			failures.append("Player did not learn hidden recipe")

	var dialog = CraftingDialogScript.new().init(_player, "alchemy", {})
	if dialog == null:
		failures.append("Failed to instantiate CraftingDialog")
	else:
		dialog.queue_free()

	var enc_dialog = CraftingDialogScript.new().init(_player, "smithing", { mode = "encrust" })
	if enc_dialog == null:
		failures.append("Failed to instantiate Encrusting CraftingDialog")
	else:
		enc_dialog.queue_free()

	if failures.is_empty():
		_log_label.text = "ALL CRAFTING CHECKS PASSED!"
		print("[CRAFTING_TEST] PASS")
	else:
		_log_label.text = "FAILURES: " + "; ".join(failures)
		print("[CRAFTING_TEST] FAIL: ", failures)
	_refresh_summary()
