extends Control

const ElementDialogScript = preload("res://script/instance/ui/element_dialog.gd")
const ElementScript = preload("res://script/instance/entity/dungeon_element.gd")

static func init_container():
	return Control.new()

var _zorkmids_ref = { value = 200 }
var _lutefisk_ref = { value = 15 }
var _resource_label = null
var _active_dialog = null
var _active_element = null
var _anvil_element = null

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	OD.Database.ingest()
	OD.Audio.setup(get_tree().get_root())

	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	container.add_child(margin)

	var vertical_box = VBoxContainer.new()
	vertical_box.add_theme_constant_override("separation", 14)
	margin.add_child(vertical_box)

	var title_label = Label.new()
	title_label.text = "Interaction UI Debug Scene"
	vertical_box.add_child(title_label)

	var resource_row = HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 10)
	vertical_box.add_child(resource_row)

	_resource_label = Label.new()
	resource_row.add_child(_resource_label)
	_refresh_resource_label()

	_add_small_button(resource_row, "+100 Zorkmids", func():
		_zorkmids_ref.value += 100
		_refresh_resource_label()
	)
	_add_small_button(resource_row, "0 Zorkmids", func():
		_zorkmids_ref.value = 0
		_refresh_resource_label()
	)
	_add_small_button(resource_row, "+10 Lutefisk", func():
		_lutefisk_ref.value += 10
		_refresh_resource_label()
	)
	_add_small_button(resource_row, "0 Lutefisk", func():
		_lutefisk_ref.value = 0
		_refresh_resource_label()
	)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vertical_box.add_child(grid)

	_add_test_button(grid, "Vending (Long Names)", _test_vending_long_names)
	_add_test_button(grid, "Vending (Random Food DB)", func(): _test_element("foodvending"))
	_add_test_button(grid, "Vending (Random Drink DB)", func(): _test_element("drinkvending"))
	_add_test_button(grid, "Krong (Workflow)", _test_krong_workflow)
	_add_test_button(grid, "Reset Krong Anvil", _reset_krong_anvil)
	_add_test_button(grid, "Krong (Pleased)", func(): _test_krong(false))
	_add_test_button(grid, "Krong (Displeased)", func(): _test_krong(true))
	_add_test_button(grid, "Krong (Already Used)", _test_krong_used)
	_add_test_button(grid, "Lutefisk Statue", _test_lutefisk)
	_add_test_button(grid, "Bookshelf", func(): _test_element("bookshelf"))
	_add_test_button(grid, "Lever", func(): _test_element("lever"))
	_add_test_button(grid, "Dredmor Statue", func(): _test_element("dredmorstatue"))
	_add_test_button(grid, "Pedestal", func(): _test_element("pedestal"))
	_add_test_button(grid, "Statue", func(): _test_element("statue"))

func _refresh_resource_label():
	if _resource_label != null:
		_resource_label.text = "Zorkmids: " + str(_zorkmids_ref.value) + " | Lutefisk: " + str(_lutefisk_ref.value)

func _add_small_button(parent, label_text, callback):
	var button = Button.new()
	button.text = label_text
	button.pressed.connect(callback)
	parent.add_child(button)

func _add_test_button(parent, label_text, callback):
	var button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(240, 48)
	button.pressed.connect(callback)
	parent.add_child(button)

func _cleanup_active():
	if is_instance_valid(_active_dialog):
		_active_dialog.queue_free()
		_active_dialog = null
	if is_instance_valid(_active_element):
		_active_element.free()
		_active_element = null

func _exit_tree():
	_cleanup_active()
	if is_instance_valid(_anvil_element):
		_anvil_element.free()
		_anvil_element = null

func _open_dialog(result, element = null):
	_cleanup_active()
	_active_element = element
	_active_dialog = ElementDialogScript.new()
	add_child(_active_dialog)
	_active_dialog.show_custom_result(result, _zorkmids_ref, _lutefisk_ref, element, func():
		_active_dialog = null
		if is_instance_valid(_active_element):
			_active_element.free()
			_active_element = null
		_refresh_resource_label()
	)

func _test_vending_long_names():
	var stock = [
		{ name = "Extremely Verbose & Convoluted Dwarven Clockwork Sandwich of Doom", price = 42, icon = "items/food_lutefisk.png" },
		{ name = "Supercalifragilisticexpialidocious Hyperborean Bolt of Unnecessary Length", price = 85, icon = "items/food_steak.png" },
		{ name = "Lutefisk", price = 10, icon = "items/food_lutefisk.png" },
		{ name = "Potentially Hazardous Alchemical Beverage with an Absurdly Long Title", price = 120, icon = "items/food_tofu.png" }
	]
	_open_dialog({
		kind = "vending",
		title = "Food Vending Machine",
		message = "Select an item to purchase:",
		stock = stock
	})

func _test_krong_workflow():
	if not is_instance_valid(_anvil_element):
		_anvil_element = ElementScript.new()
		_anvil_element.init("anvil", null)
	_cleanup_active()
	_active_dialog = ElementDialogScript.new()
	add_child(_active_dialog)
	_active_dialog.show_element_dialog(_anvil_element, _zorkmids_ref, _lutefisk_ref, func():
		_active_dialog = null
		_refresh_resource_label()
	)

func _reset_krong_anvil():
	if is_instance_valid(_anvil_element):
		_anvil_element.used = false

func _test_krong(cursed):
	var icon_path = ""
	var weapons = OD.Database.get_items_by_category("weapon")
	if not weapons.is_empty():
		icon_path = weapons[0].icon
	_open_dialog({
		kind = "krong",
		cursed = cursed,
		title = "Anvil of Krong",
		icon = icon_path,
		message = "Wooden Sword\n\nKrong is displeased!\n-1 Melee Power" if cursed else "Wooden Sword\n\n+1 Burliness\n+1 Melee Power"
	})

func _test_krong_used():
	_open_dialog({
		kind = "info",
		title = "Anvil of Krong",
		message = "The Anvil of Krong is cold and silent."
	})

func _test_lutefisk():
	var element = ElementScript.new()
	element.init("lutefiskstatue", null)
	_open_dialog(element.interact(), element)

func _test_element(element_type):
	var element = ElementScript.new()
	element.init(element_type, null)
	_open_dialog(element.interact(), element)
