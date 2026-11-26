extends Control

static func init_container():
	return Control.new()

var _summary_label = null
var _search_input = null
var _entry_list = null
var _detail_text = null
var _active_category = "skills"
var _current_entries = []

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	OD.Database.ingest()

	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	container.add_child(margin)

	var root_vertical_box = VBoxContainer.new()
	root_vertical_box.add_theme_constant_override("separation", 12)
	margin.add_child(root_vertical_box)

	_summary_label = Label.new()
	_summary_label.text = _format_summary()
	root_vertical_box.add_child(_summary_label)

	root_vertical_box.add_child(_build_category_row())

	var split = HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	root_vertical_box.add_child(split)

	var left_vertical_box = VBoxContainer.new()
	left_vertical_box.custom_minimum_size = Vector2(420, 0)
	left_vertical_box.add_theme_constant_override("separation", 8)
	split.add_child(left_vertical_box)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Filter entries..."
	_search_input.text_changed.connect(_on_search_changed)
	left_vertical_box.add_child(_search_input)

	_entry_list = ItemList.new()
	_entry_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_entry_list.item_selected.connect(_on_entry_selected)
	left_vertical_box.add_child(_entry_list)

	_detail_text = TextEdit.new()
	_detail_text.editable = false
	_detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_detail_text)

	_select_category("skills")

func _format_summary():
	return (
		"Database Debug | Skills: " + str(OD.Database.get_all_skills(true).size())
		+ " | Spells: " + str(OD.Database.get_all_spells().size())
		+ " | Items: " + str(OD.Database.get_all_items().size())
		+ " | Crafts: " + str(OD.Database.get_all_crafts().size())
		+ " | Tweaks: " + str(OD.Database.get_all_tweaks().size())
		+ " | Branches: " + str(OD.Database.get_all_branches().size())
		+ " | SFX: " + str(OD.Database.get_sound_cues().size())
	)

func _build_category_row():
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for category_info in [
		{ id = "skills", label = "Skills" },
		{ id = "spells", label = "Spells" },
		{ id = "items", label = "Items" },
		{ id = "crafts", label = "Crafts" },
		{ id = "tweaks", label = "Tweaks" },
		{ id = "branches", label = "Branches" }
	]:
		var button = Button.new()
		button.text = category_info.label
		button.pressed.connect(func(): _select_category(category_info.id))
		row.add_child(button)
	return row

func _select_category(category_id):
	_active_category = category_id
	_search_input.text = ""
	_populate_list("")

func _on_search_changed(filter_text):
	_populate_list(filter_text)

func _get_entries_for_category(category_id):
	var entries = []
	match category_id:
		"skills":
			for skill in OD.Database.get_all_skills(true):
				entries.append({
					label = "[" + str(skill.id) + "] " + skill.name + (" (deprecated)" if skill.deprecated else ""),
					data = skill
				})
		"spells":
			for spell in OD.Database.get_all_spells():
				entries.append({
					label = spell.name + " (" + spell.type + ")",
					data = spell
				})
		"items":
			for item in OD.Database.get_all_items():
				entries.append({
					label = item.name + " [" + item.category + (":" + item.slot if item.slot != "" else "") + "]",
					data = item
				})
		"crafts":
			for craft in OD.Database.get_all_crafts():
				var out_name = craft.outputs[0].name if craft.outputs.size() > 0 and craft.outputs[0].has("name") else "?"
				entries.append({
					label = "[" + craft.tool + "] " + out_name,
					data = craft
				})
		"tweaks":
			var tweaks = OD.Database.get_all_tweaks()
			var tweak_keys = tweaks.keys()
			tweak_keys.sort()
			for tweak_name in tweak_keys:
				entries.append({
					label = tweak_name + " = " + str(tweaks[tweak_name]),
					data = { name = tweak_name, value = tweaks[tweak_name] }
				})
		"branches":
			for branch in OD.Database.get_all_branches():
				entries.append({
					label = "[" + str(branch.id) + "] " + branch.name,
					data = branch
				})
	return entries

func _populate_list(filter_text):
	_entry_list.clear()
	_current_entries = []
	var query = filter_text.strip_edges().to_lower()
	for entry in _get_entries_for_category(_active_category):
		if query != "" and not entry.label.to_lower().contains(query):
			continue
		_current_entries.append(entry)
		_entry_list.add_item(entry.label)
	if _current_entries.size() > 0:
		_entry_list.select(0)
		_on_entry_selected(0)
	else:
		_detail_text.text = "No matching entries."

func _on_entry_selected(index):
	if index < 0 or index >= _current_entries.size():
		return
	_detail_text.text = JSON.stringify(_current_entries[index].data, "  ")
