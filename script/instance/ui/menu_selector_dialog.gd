extends CanvasLayer

class_name MenuSelectorDialog

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const MENU_ENTRIES = [
	{ id = "menu", label = "Game Menu" },
	{ id = "character", label = "Character" },
	{ id = "inventory", label = "Inventory" },
	{ id = "skills", label = "Skills & Spells" },
	{ id = "quests", label = "Quests" },
	{ id = "crafting", label = "Crafting" }
]

const GRID_COLUMNS = 3

var _callbacks = {}
var _panel = null
var _grid = null
var _buttons = []

func init(callbacks = {}):
	_callbacks = callbacks
	layer = 14
	_build_ui()
	_connect_signals()
	return self

func _connect_signals():
	var viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_panel_bounds):
		viewport.size_changed.connect(_update_panel_bounds)

func _create_panel_style():
	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var background_texture = dialog_assets.textures.alert_bigger if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("alert_bigger") else null
	return UiHelpers.create_panel_style(
		background_texture,
		44,
		{ left = 36, right = 36, top = 30, bottom = 32 },
		Color(0.14, 0.11, 0.09, 0.95),
		Color(0.6, 0.48, 0.3, 0.95),
		2,
		24
	)

func _build_ui():
	var overlay = UiHelpers.create_modal_overlay(self, 0.55)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.backdrop.add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(_panel)
	_update_panel_bounds()

	var content_box = VBoxContainer.new()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 16)
	_panel.add_child(content_box)

	var title = Label.new()
	title.text = "Select Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiHelpers.style_label(title, 26, Color(0.22, 0.14, 0.08))
	content_box.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_box.add_child(_grid)

	var dialog_assets = OD.Assets.dialog() if OD.Assets != null else null
	var blank_texture = dialog_assets.textures.blank if dialog_assets != null and dialog_assets.has("textures") and dialog_assets.textures.has("blank") else null
	var ink_color = Color(0.18, 0.12, 0.08)
	var font = UiHelpers.dialog_font()

	_buttons.clear()
	for entry in MENU_ENTRIES:
		var menu_id = entry.id
		var button = OD.Chrome.parchment_button(entry.label, font, ink_color, blank_texture, 18)
		button.custom_minimum_size = Vector2(180, 56)
		button.pressed.connect(_on_entry_pressed.bind(menu_id))
		_grid.add_child(button)
		_buttons.append(button)

	_wire_grid_focus()
	if not _buttons.is_empty():
		_buttons[0].call_deferred("grab_focus")

func _wire_grid_focus():
	var total = _buttons.size()
	if total == 0:
		return
	var rows = int(ceil(float(total) / float(GRID_COLUMNS)))
	for ii in range(total):
		var button = _buttons[ii]
		var col = ii % GRID_COLUMNS
		var row = int(ii / GRID_COLUMNS)
		var left_col = (col - 1 + GRID_COLUMNS) % GRID_COLUMNS
		var right_col = (col + 1) % GRID_COLUMNS
		var left_index = min(row * GRID_COLUMNS + left_col, total - 1)
		var right_index = min(row * GRID_COLUMNS + right_col, total - 1)
		var up_row = (row - 1 + rows) % rows
		var down_row = (row + 1) % rows
		var up_index = min(up_row * GRID_COLUMNS + col, total - 1)
		var down_index = min(down_row * GRID_COLUMNS + col, total - 1)
		button.focus_neighbor_left = button.get_path_to(_buttons[left_index])
		button.focus_neighbor_right = button.get_path_to(_buttons[right_index])
		button.focus_neighbor_top = button.get_path_to(_buttons[up_index])
		button.focus_neighbor_bottom = button.get_path_to(_buttons[down_index])

func _update_panel_bounds():
	if _panel == null or not is_instance_valid(_panel):
		return
	var current_viewport_size = UiHelpers.viewport_size(self)
	var panel_width = clamp(current_viewport_size.x * 0.48, 520.0, 680.0)
	var panel_height = clamp(current_viewport_size.y * 0.34, 240.0, 340.0)
	_panel.custom_minimum_size = Vector2(panel_width, panel_height)

func _on_entry_pressed(menu_id):
	var on_select = _callbacks.get("on_select", null)
	dismiss()
	if on_select != null and on_select is Callable and on_select.is_valid():
		on_select.call(menu_id)

func _unhandled_input(event):
	if (event is InputEventKey and event.is_pressed() and not event.echo and event.keycode == KEY_ESCAPE) or UiHelpers.is_gamepad_cancel(event) or event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		dismiss()

func dismiss():
	UiHelpers.invoke_callback(_callbacks, "on_close")
	queue_free()
