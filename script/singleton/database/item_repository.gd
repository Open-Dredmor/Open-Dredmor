extends RefCounted

const ITEM_DAMAGE_TYPES = [
	"acidic", "aethereal", "asphyxiative", "blasting",
	"conflagratory", "crushing", "existential", "hyperborean",
	"necromantic", "piercing", "putrefying", "righteous",
	"slashing", "toxic", "transmutative", "voltaic"
]

const STACKABLE_ITEM_CATEGORIES = [
	"food", "potion", "mushroom", "gem", "reagent",
	"component", "trap", "bolts", "thrown", "misc"
]

const ENCRUST_SLOT_ICON_MAP = {
	"neck": "expansion3/ui/encrusting/encrust_amulet.png",
	"chest": "expansion3/ui/encrusting/encrust_armour.png",
	"waist": "expansion3/ui/encrusting/encrust_belt.png",
	"feet": "expansion3/ui/encrusting/encrust_boots.png",
	"ranged": "expansion3/ui/encrusting/encrust_crossbow.png",
	"hands": "expansion3/ui/encrusting/encrust_gauntlets.png",
	"head": "expansion3/ui/encrusting/encrust_helm.png",
	"legs": "expansion3/ui/encrusting/encrust_pants.png",
	"ring": "expansion3/ui/encrusting/encrust_ring.png",
	"shield": "expansion3/ui/encrusting/encrust_shield.png",
	"weapon": "expansion3/ui/encrusting/encrust_weapon.png"
}

var component_list = []
var reagent_list = []
var craft_recipes = []
var crafts_by_output = {}
var crafts_by_tool = {}
var encrust_list = []
var encrusts_by_name = {}
var encrusts_by_tool = {}
var unstable_effects = []
var items_by_name = {}
var items_by_category = {}
var item_list = []
var loot = {}

func build(cache, world_repository):
	_build_crafts(cache)
	_build_encrusts(cache)
	_build_items(cache)
	_build_loot()
	var _unused = world_repository

func get_craft_skill_key(tool_tag):
	match str(tool_tag):
		"smithing", "ingot":
			return "smithing_level"
		"tinkerer":
			return "tinkering_level"
		"alchemy", "still", "grinder":
			return "alchemy_level"
		"lathe":
			return "wandcrafting_level"
	return ""

func _build_crafts(cache):
	var reagents = { lookup = {}, list = [] }
	var components = { lookup = {}, list = [] }
	craft_recipes = []
	crafts_by_output = {}
	crafts_by_tool = {}
	for craft in cache.crafts:
		if not craft.has("tool") or not craft.has("input"):
			continue
		var tool_tag = str(craft.tool.tag) if typeof(craft.tool) == TYPE_DICTIONARY and craft.tool.has("tag") else ""
		var kind = "reagent" if tool_tag == "still" or tool_tag == "alchemy" else "component"
		var inputs = OD.DataStructure.arrayify(craft.input)
		var outputs = OD.DataStructure.arrayify(craft.output) if craft.has("output") else []
		var min_skill = 999
		for out_entry in outputs:
			var req = int(out_entry.get("skill", 0)) if typeof(out_entry) == TYPE_DICTIONARY else 0
			if req < min_skill:
				min_skill = req
		if min_skill == 999:
			min_skill = 0
		var primary_out = str(outputs[0].get("name", "")) if not outputs.is_empty() and typeof(outputs[0]) == TYPE_DICTIONARY else ""
		var recipe = {
			id = tool_tag + ":" + primary_out + ":" + str(craft_recipes.size()),
			tool = tool_tag,
			tool_skill = get_craft_skill_key(tool_tag),
			min_skill = min_skill,
			outputs = outputs,
			inputs = inputs,
			hidden = craft.has("hidden") and int(craft.hidden) == 1,
			raw = craft
		}
		craft_recipes.append(recipe)
		if not crafts_by_tool.has(recipe.tool):
			crafts_by_tool[recipe.tool] = []
		crafts_by_tool[recipe.tool].append(recipe)
		for output in outputs:
			if typeof(output) == TYPE_DICTIONARY and output.has("name"):
				if not crafts_by_output.has(output.name):
					crafts_by_output[output.name] = []
				crafts_by_output[output.name].append(recipe)
		for input in inputs:
			if typeof(input) != TYPE_DICTIONARY or not input.has("name"):
				continue
			var ledger = components if kind == "component" else reagents
			if not ledger.lookup.has(input.name):
				ledger.lookup[input.name] = true
				ledger.list.append(input.name)
	component_list = components.list
	reagent_list = reagents.list

func _build_encrusts(cache):
	encrust_list = []
	encrusts_by_name = {}
	encrusts_by_tool = {}
	for raw_encrust in cache.encrusts:
		if typeof(raw_encrust) != TYPE_DICTIONARY or not raw_encrust.has("name"):
			continue
		var tool_tag = ""
		if raw_encrust.has("tool") and typeof(raw_encrust.tool) == TYPE_DICTIONARY:
			tool_tag = str(raw_encrust.tool.get("tag", ""))
		var slots = []
		for slot_entry in OD.DataStructure.arrayify(raw_encrust.get("slot", [])):
			if typeof(slot_entry) == TYPE_DICTIONARY and slot_entry.has("type"):
				slots.append(str(slot_entry.type))
		var inputs = OD.DataStructure.arrayify(raw_encrust.get("input", []))
		var min_skill = 0
		if raw_encrust.has("skill") and typeof(raw_encrust.skill) == TYPE_DICTIONARY:
			min_skill = int(raw_encrust.skill.get("level", 0))
		var instability = 0
		if raw_encrust.has("instability") and typeof(raw_encrust.instability) == TYPE_DICTIONARY:
			instability = int(raw_encrust.instability.get("amount", 0))
		var desc = ""
		if raw_encrust.has("description") and typeof(raw_encrust.description) == TYPE_DICTIONARY:
			desc = str(raw_encrust.description.get("text", ""))
		var encrust_with = []
		for tag_entry in OD.DataStructure.arrayify(raw_encrust.get("encrustwith", [])):
			if typeof(tag_entry) == TYPE_DICTIONARY and tag_entry.has("name"):
				encrust_with.append(str(tag_entry.name))
		var primary_buffs = []
		for entry in OD.DataStructure.arrayify(raw_encrust.get("primarybuff", [])):
			if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
				primary_buffs.append({ id = int(entry.id), amount = int(entry.get("amount", 0)) })
		var secondary_buffs = []
		for entry in OD.DataStructure.arrayify(raw_encrust.get("secondarybuff", [])):
			if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
				secondary_buffs.append({ id = int(entry.id), amount = int(entry.get("amount", 0)) })
		var resist_buffs = {}
		for entry in OD.DataStructure.arrayify(raw_encrust.get("resistbuff", [])):
			if typeof(entry) == TYPE_DICTIONARY:
				for damage_type in ITEM_DAMAGE_TYPES:
					if entry.has(damage_type):
						resist_buffs[damage_type] = int(resist_buffs.get(damage_type, 0)) + int(entry[damage_type])
		var damage_buffs = {}
		for entry in OD.DataStructure.arrayify(raw_encrust.get("damagebuff", [])):
			if typeof(entry) == TYPE_DICTIONARY:
				for damage_type in ITEM_DAMAGE_TYPES:
					if entry.has(damage_type):
						damage_buffs[damage_type] = int(damage_buffs.get(damage_type, 0)) + int(entry[damage_type])
		var powers = []
		for entry in OD.DataStructure.arrayify(raw_encrust.get("power", [])):
			if typeof(entry) == TYPE_DICTIONARY and entry.has("name"):
				powers.append({
					name = str(entry.name),
					chance = float(entry.get("chance", 1.0))
				})
		var encrust_entry = {
			id = "encrust:" + str(raw_encrust.name),
			name = str(raw_encrust.name),
			description = desc,
			tool = tool_tag,
			tool_skill = get_craft_skill_key(tool_tag),
			min_skill = min_skill,
			slots = slots,
			inputs = inputs,
			instability = instability,
			encrust_with = encrust_with,
			primary_buffs = primary_buffs,
			secondary_buffs = secondary_buffs,
			resist_buffs = resist_buffs,
			damage_buffs = damage_buffs,
			powers = powers,
			hidden = raw_encrust.has("hidden") and int(raw_encrust.hidden) == 1,
			raw = raw_encrust
		}
		encrusts_by_name[encrust_entry.name] = encrust_entry
	encrust_list = encrusts_by_name.values()
	for encrust_entry in encrust_list:
		if not encrusts_by_tool.has(encrust_entry.tool):
			encrusts_by_tool[encrust_entry.tool] = []
		encrusts_by_tool[encrust_entry.tool].append(encrust_entry)
	unstable_effects = []
	for unstable_entry in cache.unstable_effects:
		if typeof(unstable_entry) == TYPE_DICTIONARY and unstable_entry.has("name"):
			unstable_effects.append({
				name = str(unstable_entry.name),
				spell = str(unstable_entry.get("spell", ""))
			})

func _classify_item(item, reagent_set, component_set):
	if item.has("weapon"):
		var raw_weapon = item.weapon
		if typeof(raw_weapon) == TYPE_DICTIONARY and int(raw_weapon.get("thrown", 0)) == 1:
			return { category = "thrown", slot = "thrown" }
		if item.has("type") and int(item.type) == 7:
			return { category = "bolts", slot = "bolts" }
		return { category = "weapon", slot = "weapon" }
	if item.has("armour"):
		var slot_type = item.armour.type if typeof(item.armour) == TYPE_DICTIONARY and item.armour.has("type") else "chest"
		return { category = "armour", slot = slot_type }
	if item.has("food"):
		return { category = "food", slot = "" }
	if item.has("potion"):
		return { category = "potion", slot = "" }
	if item.has("wand"):
		return { category = "wand", slot = "" }
	if item.has("trap"):
		return { category = "trap", slot = "" }
	if item.has("gem"):
		return { category = "gem", slot = "" }
	if item.has("toolkit"):
		return { category = "toolkit", slot = "" }
	if item.has("mushroom"):
		return { category = "mushroom", slot = "" }
	if reagent_set.has(item.name):
		return { category = "reagent", slot = "" }
	if component_set.has(item.name):
		return { category = "component", slot = "" }
	return { category = "misc", slot = "" }

func _build_items(cache):
	items_by_name = {}
	items_by_category = {}
	item_list = []
	var reagent_set = {}
	for reagent_name in reagent_list:
		reagent_set[reagent_name] = true
	var component_set = {}
	for component_name in component_list:
		component_set[component_name] = true
	for item in cache.items:
		if typeof(item) != TYPE_DICTIONARY or not item.has("name"):
			continue
		var classification = _classify_item(item, reagent_set, component_set)
		var desc = ""
		if item.has("description") and typeof(item.description) == TYPE_DICTIONARY and item.description.has("text"):
			desc = item.description.text
		var effects = []
		for effect_key in ["effect", "primarybuff", "secondarybuff", "resistbuff", "damagebuff", "targethiteffectbuff", "castSpell"]:
			if item.has(effect_key):
				for effect_entry in OD.DataStructure.arrayify(item[effect_key]):
					effects.append({ kind = effect_key, data = effect_entry })
		var item_level = 1
		if item.has("level"):
			item_level = int(item.level)
		elif item.has("armour") and typeof(item.armour) == TYPE_DICTIONARY and item.armour.has("level"):
			item_level = int(item.armour.level)
		var is_booze = false
		if item.has("food") and typeof(item.food) == TYPE_DICTIONARY:
			is_booze = int(item.food.get("mp", 0)) > 0
		var is_artifact = item.has("artifact")
		var artifact_quality = 0
		if is_artifact:
			if typeof(item.artifact) == TYPE_DICTIONARY and item.artifact.has("quality"):
				artifact_quality = max(1, int(item.artifact.quality))
			else:
				artifact_quality = 1
		var entry = {
			name = item.name,
			category = classification.category,
			slot = classification.slot,
			type = int(item.type) if item.has("type") else -1,
			level = item_level,
			icon = item.iconFile if item.has("iconFile") else "",
			price = int(item.price.amount) if item.has("price") and typeof(item.price) == TYPE_DICTIONARY and item.price.has("amount") else 0,
			description = desc,
			effects = effects,
			special = item.has("special") and int(item.special) == 1,
			alchemical = item.has("alchemical") and int(item.alchemical) == 1,
			is_booze = is_booze,
			is_artifact = is_artifact,
			artifact_quality = artifact_quality,
			raw = item
		}
		items_by_name[entry.name] = entry
	item_list = items_by_name.values()
	for entry in item_list:
		if not items_by_category.has(entry.category):
			items_by_category[entry.category] = []
		items_by_category[entry.category].append(entry)

func _build_loot():
	loot = {
		amulet = [], armour = [], artifact = [], bolts = [], booze = [],
		component = [], food = [], gem = [], misc = [], mushroom = [],
		potion = [], reagent = [], ring = [], thrown = [], toolkit = [],
		wand = [], weapon = [],
		_find_by_name = {},
		_find_by_name_lower = {}
	}
	for item_entry in item_list:
		var raw_item = item_entry.get("raw", {})
		var item_name = str(item_entry.get("name", ""))
		if item_name == "":
			continue
		loot._find_by_name[item_name] = raw_item
		loot._find_by_name_lower[item_name.to_lower()] = raw_item
		if bool(item_entry.get("special", false)):
			continue
		var category = str(item_entry.get("category", "misc"))
		var slot_name = str(item_entry.get("slot", ""))
		if bool(item_entry.get("is_artifact", false)):
			loot.artifact.append(item_entry)
		if category == "weapon":
			loot.weapon.append(item_entry)
		elif category == "armour":
			loot.armour.append(item_entry)
			if slot_name == "ring":
				loot.ring.append(item_entry)
			elif slot_name == "neck":
				loot.amulet.append(item_entry)
		elif category == "food":
			if bool(item_entry.get("is_booze", false)):
				loot.booze.append(item_entry)
			else:
				loot.food.append(item_entry)
		elif category == "gem":
			loot.gem.append(item_entry)
			if bool(item_entry.get("alchemical", false)):
				loot.reagent.append(item_entry)
		elif loot.has(category):
			loot[category].append(item_entry)
