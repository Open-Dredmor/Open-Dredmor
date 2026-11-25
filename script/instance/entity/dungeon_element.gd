extends "res://script/instance/entity/entity.gd"

class_name DungeonElement

var entity_kind = "element"
var element_type = ""
var used = false
var is_broken = false
var state_data = {}

var _animation = null

func init(elem_type, animation, initial_data = {}):
	element_type = elem_type
	_animation = animation
	state_data = initial_data.duplicate(true)
	if _animation != null:
		if _animation.is_tall():
			_animation.position.y -= OD.Assets.CELL_PIXEL_HEIGHT / 2.0
		add_child(_animation)
		if element_type in ["lever", "bookshelf", "uberchest", "freezer"]:
			_animation.set_step_only(true)
			_animation.set_frame(0)
	_init_element_state()

func is_tall():
	return _animation != null and _animation.is_tall()

func _init_element_state():
	if element_type.ends_with("vending") and not state_data.has("vending_stock"):
		state_data["vending_stock"] = _roll_vending_stock(element_type)
	elif element_type == "pedestal" and not state_data.has("item"):
		var floor_lvl = int(state_data.get("floor_level", 1))
		var loot = OD.Database.create_artifact_instance(null, floor_lvl)
		if loot != null:
			state_data["item"] = loot
	elif element_type == "lutefiskstatue" and not state_data.has("offerings"):
		state_data["offerings"] = 0

func _roll_vending_stock(vending_type):
	var category = "food"
	match vending_type:
		"boltvending":
			category = "bolts"
		"craftvending":
			category = "component"
		"drinkvending":
			category = "potion"
		"foodvending":
			category = "food"
		"thrownvending":
			category = "weapon"
	var pool = OD.Database.get_items_by_category(category)
	if pool.is_empty():
		return []
	var stock = []
	var count = min(4, pool.size())
	for ii in range(count):
		var item = pool[randi() % pool.size()]
		var price = max(5, int(item.price) if item.price > 0 else 15)
		stock.append({
			name = item.name,
			price = price,
			icon = item.icon,
			description = item.description
		})
	return stock

func interact():
	match element_type:
		"anvil":
			return _interact_anvil()
		"bookshelf":
			return _interact_bookshelf()
		"lever":
			return _interact_lever()
		"boltvending", "craftvending", "drinkvending", "foodvending", "thrownvending":
			OD.Audio.play_sfx("vending")
			return {
				kind = "vending",
				title = element_type.replace("vending", " Vending Machine").capitalize(),
				message = "Select an item to purchase:",
				stock = state_data.get("vending_stock", [])
			}
		"lutefiskstatue":
			return {
				kind = "lutefisk",
				title = "Lutefisk God Statue",
				message = "Offerings made: " + str(state_data.get("offerings", 0)) + " / 10 Lutefisk."
			}
		"dredmorstatue":
			return {
				kind = "dredmorstatue",
				title = "Statue of Lord Dredmor",
				message = "The Dread Lord glares down at you menacingly."
			}
		"statue":
			if used:
				return { kind = "info", title = "Statue", message = "An ancient dungeon statue." }
			used = true
			OD.Audio.play_sfx("choir")
			return { kind = "info", title = "Statue", message = "You feel briefly inspired by the ancient stonework." }
		"pedestal":
			return _interact_pedestal()
		"fountain":
			return _interact_fountain()
		"uberchest":
			return _interact_chest("Uberchest", "artifact")
		"evilchest":
			return _interact_chest("Crate of Evil", "weapon")
		"bbq":
			return _interact_supply_box("Barbecue", "food", "You grill up a tasty morsel!")
		"freezer":
			return _interact_supply_box("Mini-Fridge", "potion", "You grab a chilled beverage from the freezer.")
		"queststatue":
			return _interact_quest_statue()
		"wizard_graffiti":
			return _interact_wizard_graffiti()
		"custom_breakable":
			return break_element()
		_:
			return { kind = "info", title = element_type, message = "Nothing happens." }

func _interact_anvil():
	if used:
		return { kind = "info", title = "Anvil of Krong", message = "The Anvil of Krong is cold and silent." }
	return {
		kind = "krong_select",
		title = "Anvil of Krong",
		message = "Choose an item to place upon the Anvil of Krong:"
	}

func enchant_item_on_anvil(item):
	if used:
		return { kind = "info", title = "Anvil of Krong", message = "The Anvil of Krong is cold and silent." }
	used = true
	OD.Audio.play_sfx("anvil")
	var item_name = item.get("name", "Equipment")
	var item_icon = item.get("icon", "")
	if randi() % 5 == 0:
		OD.Audio.play_sfx("cursed")
		return {
			kind = "krong",
			cursed = true,
			title = "Anvil of Krong",
			icon = item_icon,
			message = item_name + "\n\nKrong is displeased!\n-1 Melee Power"
		}
	OD.Audio.play_sfx("enchanted")
	return {
		kind = "krong",
		cursed = false,
		title = "Anvil of Krong",
		icon = item_icon,
		message = item_name + "\n\n+1 Burliness\n+1 Melee Power"
	}

func _interact_bookshelf():
	if used:
		return { kind = "info", title = "Bookshelf", message = "Only dusty empty shelves remain." }
	used = true
	if _animation != null:
		_animation.set_frame(1)
	OD.Audio.play_sfx("turnpage")
	var crafts = OD.Database.get_all_crafts()
	if crafts.is_empty():
		return { kind = "info", title = "Bookshelf", message = "You find some old dungeon lore." }
	var recipe = crafts[randi() % crafts.size()]
	var out_name = recipe.outputs[0].name if recipe.outputs.size() > 0 and recipe.outputs[0].has("name") else "Unknown"
	var out_item = OD.Database.get_item(out_name)
	var icon_path = out_item.icon if out_item != null else ""
	var item_desc = out_item.description if out_item != null else ""
	return {
		kind = "info",
		title = "Bookshelf",
		icon = icon_path,
		tooltip = item_desc,
		discovered_recipe = recipe,
		message = "Discovered crafting recipe: " + out_name + " (" + recipe.tool + ")"
	}

func _interact_lever():
	var is_on = not state_data.get("lever_on", false)
	state_data["lever_on"] = is_on
	if _animation != null:
		_animation.set_frame(1 if is_on else 0)
	OD.Audio.play_sfx("lever")
	return { kind = "info", title = "Lever", message = "You pull the lever (" + ("ON" if is_on else "OFF") + ")." }

func _interact_pedestal():
	if not state_data.has("item") or state_data["item"] == null:
		return { kind = "info", title = "Pedestal", message = "The pedestal is empty." }
	var item = state_data["item"]
	state_data["item"] = null
	OD.Audio.play_sfx("metal_get")
	var icon_path = str(item.get("icon", item.get("iconFile", "")))
	var item_desc = str(item.get("description", ""))
	if typeof(item.get("description", "")) == TYPE_DICTIONARY and item.description.has("text"):
		item_desc = str(item.description.text)
	return {
		kind = "pedestal",
		title = "Pedestal",
		icon = icon_path,
		tooltip = item_desc,
		granted_item = item,
		message = "Picked up: " + str(item.get("name", "Artifact"))
	}

func offer_lutefisk(amount):
	if amount <= 0:
		return { message = "You have no lutefisk to offer.", icon = "", tooltip = "" }
	OD.Audio.play_sfx("lutefisk")
	var total = state_data.get("offerings", 0) + amount
	state_data["offerings"] = total
	if total >= 10:
		state_data["offerings"] = total - 10
		var floor_lvl = int(state_data.get("floor_level", 1))
		var artifact = OD.Database.create_artifact_instance(null, floor_lvl)
		var reward_name = artifact.get("name", "Lutefisk Artifact") if artifact != null else "Lutefisk Artifact"
		var icon_path = str(artifact.get("icon", "")) if artifact != null else ""
		var item_desc = str(artifact.get("description", "")) if artifact != null else ""
		OD.Audio.play_sfx("enchanted")
		return {
			message = "The Lutefisk God is pleased! Granted: " + reward_name,
			icon = icon_path,
			tooltip = item_desc,
			granted_item = artifact
		}
	return {
		message = "Offered " + str(amount) + " Lutefisk (" + str(total) + "/10).",
		icon = "",
		tooltip = ""
	}

func break_element():
	if is_broken:
		return { kind = "info", title = "Broken", message = "Already smashed." }
	is_broken = true
	used = true
	OD.Audio.play_sfx("vasebreak")
	if _animation != null:
		_animation.visible = false
	var exp_gain = OD.Database.get_tweak("dredmor statue break exp", 50) if element_type == "dredmorstatue" else 0
	return {
		kind = "broken",
		title = "Smashed",
		message = "Smashed!" + (" (+" + str(exp_gain) + " XP)" if exp_gain > 0 else ""),
		exp = exp_gain
	}

func _interact_fountain():
	if used:
		return { kind = "info", title = "Fountain", message = "The fountain is dry." }
	used = true
	OD.Audio.play_sfx("fountain")
	return { kind = "info", title = "Fountain", message = "You drink from the sparkling dungeon fountain and feel refreshed!" }

func _interact_chest(title_text, loot_category):
	if used:
		return { kind = "info", title = title_text, message = "The chest has already been looted." }
	used = true
	if _animation != null and element_type == "uberchest":
		_animation.set_frame(2)
	OD.Audio.play_sfx("metal_get")
	var floor_lvl = int(state_data.get("floor_level", 1))
	var artifact_chance = 1.0 if loot_category == "artifact" else 0.15
	var rolled = OD.Database.roll_floor_loot(floor_lvl, loot_category, artifact_chance)
	var loot = rolled.get("item", null) if rolled != null else null
	if loot != null:
		return {
			kind = "info",
			title = title_text,
			icon = str(loot.get("icon", "")),
			tooltip = str(loot.get("description", "")),
			granted_item = loot,
			message = "Found: " + str(loot.get("name", "Treasure"))
		}
	return { kind = "info", title = title_text, message = "You open the " + title_text + "!" }

func _interact_supply_box(title_text, category_name, fallback_msg):
	if used:
		return { kind = "info", title = title_text, message = "It is empty." }
	used = true
	if _animation != null and element_type == "freezer":
		_animation.set_frame(1)
	OD.Audio.play_sfx("chest")
	var floor_lvl = int(state_data.get("floor_level", 1))
	var rolled = OD.Database.roll_floor_loot(floor_lvl, category_name, 0.0)
	var item = rolled.get("item", null) if rolled != null else null
	if item != null:
		return {
			kind = "info",
			title = title_text,
			icon = str(item.get("icon", "")),
			tooltip = str(item.get("description", "")),
			granted_item = item,
			message = "Found: " + str(item.get("name", "Supply"))
		}
	return { kind = "info", title = title_text, message = fallback_msg }

func _interact_quest_statue():
	if used:
		return { kind = "info", title = "Statue of Inconsequentia", message = "Inconsequentia awaits your deeds." }
	used = true
	OD.Audio.play_sfx("choir")
	return { kind = "info", title = "Statue of Inconsequentia", message = "Inconsequentia demands you prove your valor in the dungeon!" }

func _interact_wizard_graffiti():
	if used:
		return { kind = "info", title = "Wizard Graffiti", message = "The arcane runes glow faintly." }
	used = true
	OD.Audio.play_sfx("turnpage")
	return { kind = "info", title = "Wizard Graffiti", message = "You decipher an ancient Wizardlands portal rune." }
