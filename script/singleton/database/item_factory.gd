extends RefCounted

const ItemRepository = preload("res://script/singleton/database/item_repository.gd")

static func _pick_level_filtered_entry(pool, loot_kind, floor_level):
	if pool.is_empty():
		return null
	var valid_entries = []
	for entry in pool:
		var icon_path = str(entry.get("icon", ""))
		if icon_path != "" and OD.Load.exists(icon_path):
			valid_entries.append(entry)
	var source = valid_entries if not valid_entries.is_empty() else pool
	if floor_level <= 0:
		return source[randi() % source.size()]
	var max_level = floor_level + 2
	var is_gear = loot_kind in ["weapon", "armour", "artifact", "ring", "amulet", "bolts", "thrown"]
	var min_level = max(1, floor_level - 3) if is_gear else 0
	var tight = []
	var capped = []
	for entry in source:
		var entry_level = int(entry.get("level", 1))
		if entry_level <= max_level:
			capped.append(entry)
			if entry_level >= min_level:
				tight.append(entry)
	if not tight.is_empty():
		return tight[randi() % tight.size()]
	if not capped.is_empty():
		return capped[randi() % capped.size()]
	return source[randi() % source.size()]

static func get_loot(item_repo, loot_kind, loot_sub_kind = null, floor_level = -1):
	var lookup = item_repo.loot
	if loot_sub_kind != null:
		var sub_text = str(loot_sub_kind)
		if lookup._find_by_name.has(sub_text):
			return lookup._find_by_name[sub_text]
		var sub_lower = sub_text.to_lower()
		if lookup._find_by_name_lower.has(sub_lower):
			return lookup._find_by_name_lower[sub_lower]
		return null
	var kind_key = str(loot_kind).to_lower()
	if kind_key == "reagents":
		kind_key = "reagent"
	elif kind_key == "ammo":
		kind_key = "bolts"
	if not lookup.has(kind_key):
		return null
	var pool = lookup[kind_key]
	if typeof(pool) != TYPE_ARRAY or pool.is_empty():
		return null
	var picked = _pick_level_filtered_entry(pool, kind_key, floor_level)
	if picked == null:
		return null
	return picked.get("raw", picked) if typeof(picked) == TYPE_DICTIONARY and picked.has("raw") else picked

static func create_item_instance(item_repo, world_repo, item_name_or_definition, count = 1):
	var item_definition = null
	if typeof(item_name_or_definition) == TYPE_STRING:
		item_definition = item_repo.items_by_name.get(item_name_or_definition, null)
	elif typeof(item_name_or_definition) == TYPE_DICTIONARY:
		if item_name_or_definition.has("raw"):
			item_definition = item_name_or_definition
		elif item_name_or_definition.has("name"):
			item_definition = item_repo.items_by_name.get(str(item_name_or_definition.name), null)
	if item_definition == null:
		return null
	var raw_item = item_definition.get("raw", {})
	var category = str(item_definition.get("category", "misc"))
	var max_stack = 1
	if category in ItemRepository.STACKABLE_ITEM_CATEGORIES:
		max_stack = max(2, int(raw_item.get("maxstack", 99)))
	var clamped_count = clamp(int(count), 1, max_stack)

	var weapon_damage = {}
	var raw_weapon = raw_item.get("weapon", null)
	if typeof(raw_weapon) == TYPE_DICTIONARY:
		for damage_type in ItemRepository.ITEM_DAMAGE_TYPES:
			if raw_weapon.has(damage_type):
				var damage_value = int(raw_weapon[damage_type])
				if damage_value != 0:
					weapon_damage[damage_type] = damage_value

	var primary_buffs = []
	for entry in OD.DataStructure.arrayify(raw_item.get("primarybuff", [])):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			primary_buffs.append({ id = int(entry.id), amount = int(entry.get("amount", 0)) })

	var secondary_buffs = []
	for entry in OD.DataStructure.arrayify(raw_item.get("secondarybuff", [])):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			secondary_buffs.append({ id = int(entry.id), amount = int(entry.get("amount", 0)) })

	var resist_buffs = {}
	for entry in OD.DataStructure.arrayify(raw_item.get("resistbuff", [])):
		if typeof(entry) == TYPE_DICTIONARY:
			for damage_type in ItemRepository.ITEM_DAMAGE_TYPES:
				if entry.has(damage_type):
					resist_buffs[damage_type] = int(resist_buffs.get(damage_type, 0)) + int(entry[damage_type])

	var damage_buffs = {}
	for entry in OD.DataStructure.arrayify(raw_item.get("damagebuff", [])):
		if typeof(entry) == TYPE_DICTIONARY:
			for damage_type in ItemRepository.ITEM_DAMAGE_TYPES:
				if entry.has(damage_type):
					damage_buffs[damage_type] = int(damage_buffs.get(damage_type, 0)) + int(entry[damage_type])

	var target_hit_effects = []
	for entry in OD.DataStructure.arrayify(raw_item.get("targethiteffectbuff", [])):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("name"):
			target_hit_effects.append({
				name = str(entry.name),
				percentage = int(entry.get("percentage", 100))
			})

	var player_hit_effects = []
	for entry in OD.DataStructure.arrayify(raw_item.get("playerhiteffectbuff", [])):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("name"):
			player_hit_effects.append({
				name = str(entry.name),
				percentage = int(entry.get("percentage", 100))
			})

	var base_price = int(item_definition.get("price", 0))
	var sell_scaler = float(world_repo.get_tweak("store sell price scaler", 0.63))
	var sell_price = max(1, int(round(float(base_price) * sell_scaler))) if base_price > 0 else 0

	var instance = {
		name = str(item_definition.get("name", "Unknown Item")),
		base_name = str(item_definition.get("name", "Unknown Item")),
		category = category,
		slot = str(item_definition.get("slot", "")),
		type = int(item_definition.get("type", -1)),
		level = int(item_definition.get("level", 1)),
		icon = str(item_definition.get("icon", "")),
		price = base_price,
		sell_price = sell_price,
		description = str(item_definition.get("description", "")),
		count = clamped_count,
		max_stack = max_stack,
		is_artifact = bool(item_definition.get("is_artifact", false)),
		artifact_quality = int(item_definition.get("artifact_quality", 0)),
		weapon_damage = weapon_damage,
		primary_buffs = primary_buffs,
		secondary_buffs = secondary_buffs,
		resist_buffs = resist_buffs,
		damage_buffs = damage_buffs,
		target_hit_effects = target_hit_effects,
		player_hit_effects = player_hit_effects
	}
	var raw_food = raw_item.get("food", null)
	if typeof(raw_food) == TYPE_DICTIONARY:
		var food_hp = int(raw_food.get("hp", 0))
		var food_mp = int(raw_food.get("mp", 0))
		instance["food_hp"] = food_hp
		instance["food_mp"] = food_mp
		instance["food_effect"] = str(raw_food.get("effect", ""))
		instance["food_meat"] = int(raw_food.get("meat", 0)) == 1
		instance["is_booze"] = food_mp > 0
	var raw_potion = raw_item.get("potion", null)
	if typeof(raw_potion) == TYPE_DICTIONARY:
		instance["potion_spell"] = str(raw_potion.get("spell", ""))
	if category == "mushroom":
		var raw_casts = raw_item.get("casts", null)
		if typeof(raw_casts) == TYPE_DICTIONARY:
			instance["casts_spell"] = str(raw_casts.get("spell", ""))
	var raw_wand = raw_item.get("wand", null)
	if typeof(raw_wand) == TYPE_DICTIONARY:
		var min_charge = max(1, int(raw_wand.get("mincharge", 1)))
		var max_charge = max(min_charge, int(raw_wand.get("maxcharge", min_charge)))
		var rolled_charges = randi_range(min_charge, max_charge)
		instance["wand_spell"] = str(raw_wand.get("spell", ""))
		instance["charges"] = rolled_charges
		instance["max_charges"] = rolled_charges
	for damage_type in weapon_damage:
		instance[damage_type] = weapon_damage[damage_type]
	return instance

static func _pick_text_entry(cache, tag_key, fallback_text):
	if cache == null or not cache.has("text") or not cache.text.has(tag_key):
		return fallback_text
	var entries = OD.DataStructure.arrayify(cache.text[tag_key])
	if entries.is_empty():
		return fallback_text
	var chosen = entries[randi() % entries.size()]
	if typeof(chosen) == TYPE_DICTIONARY and chosen.has("text"):
		return str(chosen.text)
	return fallback_text

static func generate_artifact_name(cache, base_name):
	var start_ph = _pick_text_entry(cache, "startPhoneme", "Krong")
	var mid_ph = _pick_text_entry(cache, "phoneme", "ar")
	var end_ph = _pick_text_entry(cache, "phoneme", "ak")
	var proper_name = start_ph + mid_ph + (end_ph if randi() % 2 == 0 else "")
	var quality_word = _pick_text_entry(cache, "quality", "illustrious").capitalize()
	var material_word = _pick_text_entry(cache, "material", "orichalcum").capitalize()
	var decor_word = _pick_text_entry(cache, "decor", "runes")
	var adjacent_word = _pick_text_entry(cache, "adjective", "Ancient")
	var noun_word = _pick_text_entry(cache, "noun", "Power")
	var pattern = randi() % 4
	match pattern:
		0:
			return "%s, the %s %s of %s" % [proper_name, adjacent_word, base_name, noun_word]
		1:
			return "The %s %s of %s" % [quality_word, base_name, decor_word.capitalize()]
		2:
			return "%s of the %s %s" % [base_name, adjacent_word, noun_word]
		_:
			return "%s's %s %s %s" % [proper_name, quality_word, material_word, base_name]

static func _add_buff_entry(buff_list, stat_id, delta):
	for entry in buff_list:
		if int(entry.get("id", -1)) == stat_id:
			entry["amount"] = int(entry.get("amount", 0)) + delta
			return
	buff_list.append({ id = stat_id, amount = delta })

static func _apply_artifact_bonuses(world_repo, instance, quality):
	var clamped_quality = clamp(int(quality), 1, 15)
	var sec_ids = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
	var element_types = ["conflagratory", "hyperborean", "voltaic", "acidic", "toxic", "aethereal", "necromantic", "righteous"]
	var is_weapon = str(instance.get("category", "")) == "weapon"
	for _ii in range(clamped_quality):
		var roll = randi() % 4
		if roll == 0:
			var primary_id = randi() % 6
			_add_buff_entry(instance.primary_buffs, primary_id, randi_range(1, 2))
		elif roll == 1:
			var sec_id = sec_ids[randi() % sec_ids.size()]
			var amount = randi_range(2, 5) if sec_id <= 1 else randi_range(1, 3)
			_add_buff_entry(instance.secondary_buffs, sec_id, amount)
		elif roll == 2:
			var result_type = element_types[randi() % element_types.size()]
			instance.resist_buffs[result_type] = int(instance.resist_buffs.get(result_type, 0)) + randi_range(1, 3)
		else:
			var damage_type = element_types[randi() % element_types.size()]
			var damage_amount = randi_range(1, 3)
			if is_weapon:
				instance.weapon_damage[damage_type] = int(instance.weapon_damage.get(damage_type, 0)) + damage_amount
				instance[damage_type] = int(instance.get(damage_type, 0)) + damage_amount
			else:
				instance.damage_buffs[damage_type] = int(instance.damage_buffs.get(damage_type, 0)) + damage_amount
	instance["is_artifact"] = true
	instance["artifact_quality"] = clamped_quality
	var base_price = max(100, int(instance.get("price", 100)))
	var scaled_price = int(round(float(base_price) * (1.0 + float(clamped_quality) * 0.45))) + clamped_quality * 120
	instance["price"] = scaled_price
	var sell_scaler = float(world_repo.get_tweak("store sell price scaler", 0.63))
	instance["sell_price"] = max(1, int(round(float(scaled_price) * sell_scaler)))

static func create_artifact_instance(cache, item_repo, world_repo, base_item_or_definition = null, floor_level = 1, forced_quality = -1):
	var quality = forced_quality if forced_quality > 0 else clamp(randi_range(1, 3) + int(floor_level / 2), 1, 10)
	var chosen_definition = null
	var is_predefined = false
	if base_item_or_definition != null:
		chosen_definition = base_item_or_definition
	else:
		var use_predefined = (randi() % 100) < 25
		if use_predefined:
			var pre_raw = get_loot(item_repo, "artifact", null, floor_level)
			if pre_raw != null:
				chosen_definition = pre_raw
				is_predefined = true
		if chosen_definition == null:
			var gear_kind = "weapon" if randi() % 2 == 0 else "armour"
			chosen_definition = get_loot(item_repo, gear_kind, null, floor_level)
	if chosen_definition == null:
		return null
	var instance = create_item_instance(item_repo, world_repo, chosen_definition, 1)
	if instance == null:
		return null
	if bool(instance.get("is_artifact", false)) or is_predefined:
		var pre_quality = max(quality, int(instance.get("artifact_quality", 1)))
		instance["is_artifact"] = true
		instance["artifact_quality"] = pre_quality
		return instance
	instance["name"] = generate_artifact_name(cache, instance.get("base_name", instance.get("name", "Relic")))
	_apply_artifact_bonuses(world_repo, instance, quality)
	return instance

static func roll_floor_loot(cache, item_repo, world_repo, floor_level = 1, loot_kind = "", artifact_chance = 0.04):
	var chosen_kind = str(loot_kind).to_lower()
	if chosen_kind == "":
		var kinds = ["weapon", "armour", "ring", "amulet", "bolts", "food", "booze", "potion", "mushroom", "wand", "gem", "reagent", "component"]
		chosen_kind = kinds[randi() % kinds.size()]
	if chosen_kind == "artifact":
		var art_inst = create_artifact_instance(cache, item_repo, world_repo, null, floor_level)
		return { kind = "item", item = art_inst } if art_inst != null else null
	var raw_or_definition = get_loot(item_repo, chosen_kind, null, floor_level)
	if raw_or_definition == null:
		return null
	var gear_kinds = ["weapon", "armour", "ring", "amulet"]
	if chosen_kind in gear_kinds and artifact_chance > 0.0 and randf() < artifact_chance:
		var art_inst = create_artifact_instance(cache, item_repo, world_repo, raw_or_definition, floor_level)
		if art_inst != null:
			return { kind = "item", item = art_inst }
	var inst = create_item_instance(item_repo, world_repo, raw_or_definition, 1)
	return { kind = "item", item = inst } if inst != null else null
