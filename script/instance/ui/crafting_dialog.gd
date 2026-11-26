extends CanvasLayer

const UiHelpers = preload("res://script/instance/ui/ui_helpers.gd")

const FloatingWindowScript = preload("res://script/instance/ui/floating_window.gd")
const TOOL_ORDER = ["smithing", "alchemy", "still", "ingot", "grinder", "tinkerer", "lathe"]

const TOOL_ASSET_MAP = {
	"smithing": "ui/crafting/tool_travel_anvil",
	"alchemy": "ui/crafting/tool_alchemy_kit",
	"still": "ui/crafting/tool_distilling_kit",
	"ingot": "ui/crafting/tool_ingot_press",
	"grinder": "ui/crafting/tool_ingot_grinder",
	"tinkerer": "ui/crafting/tool_tinkerer_kit",
	"lathe": "ui/crafting/tool_n-dimensional_lathe"
}

const VISIBLE_ROWS = 6
const CRAFT_PANEL_W = 600.0
const ENCRUST_PANEL_W = 664.0
const PANEL_H = 600.0

const DEFAULT_VIEWPORT_SIZE = Vector2(1280, 720)
const UI_SCALE_MARGIN = Vector2(80.0, 40.0)
const UI_SCALE_MIN = 0.75
const UI_SCALE_MAX = 1.35

const CRAFT_TAB_RECT = Rect2(6, 5, 93, 20)
const ENCRUST_TAB_RECT = Rect2(6, 25, 93, 20)
const CLOSE_BTN_POS = Vector2(506, 6)
const CLOSE_BTN_FALLBACK_SIZE = Vector2(20, 20)

const TOOL_BTN_START_POS = Vector2(39, 68)
const TOOL_BTN_STEP_Y = 69
const TOOL_BTN_SIZE = Vector2(60, 60)

const FILTER_POSITIONS = {
	ingredients = Vector2(106, 36),
	skill = Vector2(214, 36),
	secret = Vector2(286, 36)
}

const ROWS_CONTAINER_RECT = Rect2(122, 74, 384, 480)
const ROW_SIZE = Vector2(384, 80)
const ROW_STEP_Y = 80

const NAV_BTN_X = 508
const NAV_BTN_FALLBACK_SIZE = Vector2(64, 32)
const NAV_TOP_Y = 141
const NAV_PGUP_Y = 176
const NAV_UP_Y = 211
const NAV_DOWN_Y = 307
const NAV_PGDN_Y = 345
const NAV_BOT_Y = 381

const CRAFT_BTN_POS = Vector2(416, 230)
const CRAFT_BTN_FALLBACK_SIZE = Vector2(192, 88)
const ENCRUST_TARGET_BTN_RECT = Rect2(590, 242, 64, 64)
const ENCRUST_TARGET_ICON_RECT = Rect2(4, 4, 56, 56)

const STATUS_LABEL_RECT = Rect2(106, 558, 400, 26)
const STATUS_FONT_SIZE = 14

const INGREDIENT_BASE_X = 304
const INGREDIENT_STEP_X = 74
const INGREDIENT_Y = 8
const OUTPUT_SLOT_POS = Vector2(310, 8)
const SLOT_ICON_SIZE = Vector2(56, 56)
const SLOT_SKILL_LABEL_OFFSET = Vector2(6, 48)
const SLOT_SKILL_LABEL_SIZE = Vector2(24, 16)
const SLOT_SKILL_FONT_SIZE = 12
const SLOT_MARK_OFFSET = Vector2(24, 46)
const SLOT_MARK_SIZE = Vector2(20, 18)
const SLOT_MARK_FONT_SIZE = 14

const TOOLTIP_OFFSET = Vector2(16, 16)
const TOOLTIP_SCREEN_MARGIN = 8
const TOOLTIP_FLIP_MARGIN = 12
const TOOLTIP_BORDER_WIDTH = 2
const TOOLTIP_CONTENT_MARGIN = 10
const TOOLTIP_MIN_WIDTH = 220
const TOOLTIP_FONT_SIZE = 13

var _player = null
var _mode = "craft"
var _active_tool = ""
var _filtered_recipes = []
var _selected_index = 0
var _scroll_offset = 0
var _filter_ingredients = false
var _filter_skill = false
var _filter_secret = false
var _callbacks = {}
var _selected_encrust_target = null
var _eligible_targets = []
var _eligible_target_index = 0
var _ui_scale = 1.0

var _window = null
var _root_control = null
var _holder = null
var _panel_root = null
var _background_rect = null
var _craft_tab_button = null
var _encrust_tab_button = null
var _tool_buttons = {}
var _filter_buttons = {}
var _rows_container = null
var _craft_button = null
var _encrust_target_button = null
var _encrust_target_icon = null
var _status_label = null
var _tooltip_panel = null
var _tooltip_label = null
var _texture_cache = {}

func init(player_character, initial_tool = "", callbacks = {}):
	layer = 14
	_player = player_character
	_callbacks = callbacks
	var initial_mode = str(callbacks.get("mode", "craft"))
	if initial_mode == "encrust":
		_mode = "encrust"
	var possessed = _player.get_possessed_toolkits() if _player != null else {}
	if initial_tool != "" and possessed.has(initial_tool):
		_active_tool = initial_tool
	else:
		for tag in TOOL_ORDER:
			if possessed.has(tag):
				_active_tool = tag
				break
		if _active_tool == "" and not possessed.is_empty():
			_active_tool = str(possessed.keys()[0])
	_build_ui()
	if _player != null and not _player.inventory_changed.is_connected(_refresh_all):
		_player.inventory_changed.connect(_refresh_all)
	_refresh_all()
	return self

func dismiss():
	if _player != null and _player.inventory_changed.is_connected(_refresh_all):
		_player.inventory_changed.disconnect(_refresh_all)
	var on_close = _callbacks.get("on_close", Callable())
	if on_close is Callable and on_close.is_valid():
		on_close.call()
	queue_free()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			dismiss()
		elif event.keycode == KEY_UP:
			get_viewport().set_input_as_handled()
			_move_selection(-1)
		elif event.keycode == KEY_DOWN:
			get_viewport().set_input_as_handled()
			_move_selection(1)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_execute_craft()

func get_floating_window():
	return _window

func _process(_delta):
	if _tooltip_panel != null and _tooltip_panel.visible:
		UiHelpers.position_tooltip(
			_tooltip_panel,
			get_viewport().get_mouse_position(),
			get_viewport().get_visible_rect().size,
			TOOLTIP_OFFSET,
			TOOLTIP_SCREEN_MARGIN,
			TOOLTIP_FLIP_MARGIN
		)

func _load_tex(path):
	if path == null:
		return null
	return UiHelpers.load_texture(path, _texture_cache)

func _make_tri_button(base_path, fallback_size = Vector2(64, 32)):
	var button = TextureButton.new()
	var normal_texture = _load_tex(base_path + "0.png")
	var hover_texture = _load_tex(base_path + "1.png")
	var pressed_texture = _load_tex(base_path + "2.png")
	button.texture_normal = normal_texture
	button.texture_hover = hover_texture if hover_texture != null else normal_texture
	button.texture_pressed = pressed_texture if pressed_texture != null else (hover_texture if hover_texture != null else normal_texture)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if normal_texture != null:
		button.custom_minimum_size = normal_texture.get_size()
		button.size = normal_texture.get_size()
	else:
		button.custom_minimum_size = fallback_size
		button.size = fallback_size
	return button

func _style_label(label, font, font_size, color):
	UiHelpers.style_label(label, font_size, color, font)

func _build_ui():
	var dialog_assets = OD.Assets.dialog()
	var font = dialog_assets.font

	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size if viewport != null else OD.Settings.display_size()
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = DEFAULT_VIEWPORT_SIZE
	_ui_scale = clamp(min((viewport_size.x - UI_SCALE_MARGIN.x) / ENCRUST_PANEL_W, (viewport_size.y - UI_SCALE_MARGIN.y) / PANEL_H), UI_SCALE_MIN, UI_SCALE_MAX)
	var panel_w = ENCRUST_PANEL_W if _mode == "encrust" else CRAFT_PANEL_W
	var base_size = Vector2(panel_w, PANEL_H)

	_window = FloatingWindowScript.new()
	_window.min_window_size = base_size * 0.6
	_window.set_base_size(base_size, _ui_scale)
	_window.position = Vector2((viewport_size.x - _window.size.x) * 0.5, max(24.0, (viewport_size.y - _window.size.y) * 0.45))
	add_child(_window)

	_root_control = _window

	_holder = _window.get_content_root()

	_panel_root = Control.new()
	_panel_root.custom_minimum_size = Vector2(panel_w, PANEL_H)
	_panel_root.size = Vector2(panel_w, PANEL_H)
	_holder.add_child(_panel_root)

	_background_rect = TextureRect.new()
	_background_rect.size = Vector2(panel_w, PANEL_H)
	_background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(_background_rect)

	_craft_tab_button = TextureButton.new()
	_craft_tab_button.position = CRAFT_TAB_RECT.position
	_craft_tab_button.custom_minimum_size = CRAFT_TAB_RECT.size
	_craft_tab_button.size = CRAFT_TAB_RECT.size
	_craft_tab_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_craft_tab_button.tooltip_text = "Crafting Mode"
	_craft_tab_button.pressed.connect(func(): _set_mode("craft"))
	_panel_root.add_child(_craft_tab_button)

	_encrust_tab_button = TextureButton.new()
	_encrust_tab_button.position = ENCRUST_TAB_RECT.position
	_encrust_tab_button.custom_minimum_size = ENCRUST_TAB_RECT.size
	_encrust_tab_button.size = ENCRUST_TAB_RECT.size
	_encrust_tab_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_encrust_tab_button.tooltip_text = "Encrusting Mode"
	_encrust_tab_button.pressed.connect(func(): _set_mode("encrust"))
	_panel_root.add_child(_encrust_tab_button)

	var close_button = _make_tri_button("ui/gameplay/xclose_copper", CLOSE_BTN_FALLBACK_SIZE)
	close_button.position = CLOSE_BTN_POS
	close_button.pressed.connect(dismiss)
	_panel_root.add_child(close_button)

	_tool_buttons.clear()
	for index in range(TOOL_ORDER.size()):
		var tool_tag = TOOL_ORDER[index]
		var tool_button = TextureButton.new()
		tool_button.position = Vector2(TOOL_BTN_START_POS.x, TOOL_BTN_START_POS.y + index * TOOL_BTN_STEP_Y + index)
		tool_button.ignore_texture_size = true
		tool_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tool_button.custom_minimum_size = TOOL_BTN_SIZE
		tool_button.size = TOOL_BTN_SIZE
		tool_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var toolkit_info = OD.Database.get_toolkit_info(tool_tag)
		tool_button.tooltip_text = toolkit_info.name if toolkit_info != null else tool_tag.capitalize()
		tool_button.pressed.connect(func():
			if _player != null and _player.has_toolkit(tool_tag):
				_active_tool = tool_tag
				_selected_index = 0
				_scroll_offset = 0
				_refresh_all()
		)
		_panel_root.add_child(tool_button)
		_tool_buttons[tool_tag] = tool_button

	var filter_defs = [
		{ key = "ingredients", path = "ui/crafting/filter_ingredients", pos = FILTER_POSITIONS.ingredients },
		{ key = "skill", path = "ui/crafting/filter_skill", pos = FILTER_POSITIONS.skill },
		{ key = "secret", path = "ui/crafting/filter_secret", pos = FILTER_POSITIONS.secret }
	]
	_filter_buttons.clear()
	for f_definition in filter_defs:
		var f_button = TextureButton.new()
		f_button.position = f_definition.pos
		f_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var f_key = f_definition.key
		f_button.pressed.connect(func():
			if f_key == "ingredients":
				_filter_ingredients = not _filter_ingredients
			elif f_key == "skill":
				_filter_skill = not _filter_skill
			elif f_key == "secret":
				_filter_secret = not _filter_secret
			_selected_index = 0
			_scroll_offset = 0
			_refresh_filters()
			_refresh_recipes()
		)
		_panel_root.add_child(f_button)
		_filter_buttons[f_key] = { btn = f_button, base = f_definition.path }

	_rows_container = Control.new()
	_rows_container.position = ROWS_CONTAINER_RECT.position
	_rows_container.size = ROWS_CONTAINER_RECT.size
	_panel_root.add_child(_rows_container)

	var top_button = _make_tri_button("ui/crafting/uber_top", NAV_BTN_FALLBACK_SIZE)
	top_button.position = Vector2(NAV_BTN_X, NAV_TOP_Y)
	top_button.pressed.connect(func(): _jump_selection(0))
	_panel_root.add_child(top_button)

	var pgup_button = _make_tri_button("ui/crafting/uber_pageup", NAV_BTN_FALLBACK_SIZE)
	pgup_button.position = Vector2(NAV_BTN_X, NAV_PGUP_Y)
	pgup_button.pressed.connect(func(): _move_selection(-VISIBLE_ROWS))
	_panel_root.add_child(pgup_button)

	var up_button = _make_tri_button("ui/crafting/uber_up", NAV_BTN_FALLBACK_SIZE)
	up_button.position = Vector2(NAV_BTN_X, NAV_UP_Y)
	up_button.pressed.connect(func(): _move_selection(-1))
	_panel_root.add_child(up_button)

	_craft_button = _make_tri_button("ui/crafting/craft_button", CRAFT_BTN_FALLBACK_SIZE)
	_craft_button.position = CRAFT_BTN_POS
	_craft_button.pressed.connect(_execute_craft)
	_panel_root.add_child(_craft_button)

	_encrust_target_button = TextureButton.new()
	_encrust_target_button.position = ENCRUST_TARGET_BTN_RECT.position
	_encrust_target_button.custom_minimum_size = ENCRUST_TARGET_BTN_RECT.size
	_encrust_target_button.size = ENCRUST_TARGET_BTN_RECT.size
	_encrust_target_button.visible = (_mode == "encrust")
	_encrust_target_button.pressed.connect(_cycle_encrust_target)
	_encrust_target_button.mouse_entered.connect(_show_encrust_target_tooltip)
	_encrust_target_button.mouse_exited.connect(_hide_tooltip)
	_panel_root.add_child(_encrust_target_button)

	_encrust_target_icon = TextureRect.new()
	_encrust_target_icon.position = ENCRUST_TARGET_ICON_RECT.position
	_encrust_target_icon.size = ENCRUST_TARGET_ICON_RECT.size
	_encrust_target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_encrust_target_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_encrust_target_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_encrust_target_button.add_child(_encrust_target_icon)

	var down_button = _make_tri_button("ui/crafting/uber_down", NAV_BTN_FALLBACK_SIZE)
	down_button.position = Vector2(NAV_BTN_X, NAV_DOWN_Y)
	down_button.pressed.connect(func(): _move_selection(1))
	_panel_root.add_child(down_button)

	var pgdn_button = _make_tri_button("ui/crafting/uber_pagedown", NAV_BTN_FALLBACK_SIZE)
	pgdn_button.position = Vector2(NAV_BTN_X, NAV_PGDN_Y)
	pgdn_button.pressed.connect(func(): _move_selection(VISIBLE_ROWS))
	_panel_root.add_child(pgdn_button)

	var bot_button = _make_tri_button("ui/crafting/uber_bot", NAV_BTN_FALLBACK_SIZE)
	bot_button.position = Vector2(NAV_BTN_X, NAV_BOT_Y)
	bot_button.pressed.connect(func(): _jump_selection(max(0, _filtered_recipes.size() - 1)))
	_panel_root.add_child(bot_button)

	_status_label = Label.new()
	_status_label.position = STATUS_LABEL_RECT.position
	_status_label.size = STATUS_LABEL_RECT.size
	_style_label(_status_label, font, STATUS_FONT_SIZE, Color(0.15, 0.1, 0.05))
	_panel_root.add_child(_status_label)

	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 50
	var tip_style = StyleBoxFlat.new()
	tip_style.bg_color = Color(0.08, 0.06, 0.05, 0.94)
	tip_style.border_color = Color(0.7, 0.56, 0.34, 0.95)
	tip_style.set_border_width_all(TOOLTIP_BORDER_WIDTH)
	tip_style.set_content_margin_all(TOOLTIP_CONTENT_MARGIN)
	_tooltip_panel.add_theme_stylebox_override("panel", tip_style)
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.custom_minimum_size = Vector2(TOOLTIP_MIN_WIDTH, 0)
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(_tooltip_label, font, TOOLTIP_FONT_SIZE, Color(0.95, 0.92, 0.84))
	_tooltip_panel.add_child(_tooltip_label)

func _set_mode(new_mode):
	if new_mode == _mode:
		return
	_mode = new_mode
	_selected_index = 0
	_scroll_offset = 0
	_selected_encrust_target = null
	_status_label.text = ""
	_refresh_all()

func _refresh_mode_chrome():
	var is_encrust = (_mode == "encrust")
	var panel_w = ENCRUST_PANEL_W if is_encrust else CRAFT_PANEL_W
	if _window != null and is_instance_valid(_window):
		_window.set_base_size(Vector2(panel_w, PANEL_H), _window.get_current_scale())
		_window.clamp_to_viewport()
	if _panel_root != null:
		_panel_root.custom_minimum_size = Vector2(panel_w, PANEL_H)
		_panel_root.size = Vector2(panel_w, PANEL_H)
	if _background_rect != null:
		var background_path = "expansion3/ui/crafting/ubercrust_bg.png" if is_encrust else "expansion3/ui/crafting/ubercraft_bg.png"
		var background_texture = _load_tex(background_path)
		if background_texture == null:
			background_texture = _load_tex("ui/crafting/craft_panel.png")
		_background_rect.texture = background_texture
		_background_rect.size = Vector2(panel_w, PANEL_H)
	if _craft_tab_button != null:
		_craft_tab_button.texture_normal = _load_tex("expansion3/ui/crafting/craft" + ("0.png" if is_encrust else "1.png"))
		_craft_tab_button.texture_hover = _load_tex("expansion3/ui/crafting/craft2.png")
		_craft_tab_button.texture_pressed = _load_tex("expansion3/ui/crafting/craft1.png")
	if _encrust_tab_button != null:
		_encrust_tab_button.texture_normal = _load_tex("expansion3/ui/crafting/encrust" + ("1.png" if is_encrust else "0.png"))
		_encrust_tab_button.texture_hover = _load_tex("expansion3/ui/crafting/encrust2.png")
		_encrust_tab_button.texture_pressed = _load_tex("expansion3/ui/crafting/encrust1.png")
	if _craft_button != null:
		var button_base = "expansion3/ui/crafting/encrust_button" if is_encrust else "ui/crafting/craft_button"
		var n_texture = _load_tex(button_base + "0.png")
		var h_texture = _load_tex(button_base + "1.png")
		var p_texture = _load_tex(button_base + "2.png")
		_craft_button.texture_normal = n_texture
		_craft_button.texture_hover = h_texture if h_texture != null else n_texture
		_craft_button.texture_pressed = p_texture if p_texture != null else (h_texture if h_texture != null else n_texture)
	if _encrust_target_button != null:
		_encrust_target_button.visible = is_encrust

func _refresh_all():
	_refresh_mode_chrome()
	_refresh_tools()
	_refresh_filters()
	_refresh_recipes()

func _refresh_tools():
	if _player == null:
		return
	var possessed = _player.get_possessed_toolkits()
	if _active_tool != "" and not possessed.has(_active_tool):
		_active_tool = ""
	if _active_tool == "" and not possessed.is_empty():
		for tag in TOOL_ORDER:
			if possessed.has(tag):
				_active_tool = tag
				break
	for tool_tag in TOOL_ORDER:
		if not _tool_buttons.has(tool_tag):
			continue
		var button = _tool_buttons[tool_tag]
		var base_path = TOOL_ASSET_MAP.get(tool_tag, "")
		var has_tool = possessed.has(tool_tag)
		var state_index = "0"
		if tool_tag == _active_tool and has_tool:
			state_index = "2"
		elif has_tool:
			state_index = "1"
		button.texture_normal = _load_tex(base_path + state_index + ".png")
		button.texture_hover = _load_tex(base_path + ("2.png" if has_tool else "0.png"))
		button.disabled = not has_tool

func _refresh_filters():
	var states = {
		ingredients = _filter_ingredients,
		skill = _filter_skill,
		secret = _filter_secret
	}
	for f_key in _filter_buttons:
		var info = _filter_buttons[f_key]
		var is_on = bool(states.get(f_key, false))
		var base = str(info.base)
		var button = info.btn
		button.texture_normal = _load_tex(base + ("2.png" if is_on else "0.png"))
		button.texture_hover = _load_tex(base + "1.png")

func _refresh_recipes():
	_filtered_recipes.clear()
	if _player != null and _active_tool != "":
		if _mode == "encrust":
			var all_encrusts = OD.Database.get_encrusts_by_tool(_active_tool)
			var skill_level = _player.get_crafting_skill_level(_active_tool)
			for encrust_definition in all_encrusts:
				var is_hidden = bool(encrust_definition.get("hidden", false))
				if _filter_secret and not is_hidden:
					continue
				if _filter_skill and skill_level < int(encrust_definition.get("min_skill", 0)):
					continue
				if _filter_ingredients:
					var has_all_ing = true
					var req_counts = _player._required_input_counts(encrust_definition)
					for req_name in req_counts:
						if _player.count_item_in_inventory_excluding(req_name, _selected_encrust_target) < int(req_counts[req_name]):
							has_all_ing = false
							break
					if not has_all_ing:
						continue
				_filtered_recipes.append(encrust_definition)
		else:
			var all_tool_recipes = OD.Database.get_crafts_by_tool(_active_tool)
			var skill_level = _player.get_crafting_skill_level(_active_tool)
			for recipe in all_tool_recipes:
				var is_hidden = bool(recipe.get("hidden", false))
				if not _player.knows_recipe(recipe):
					continue
				if _filter_secret and not is_hidden:
					continue
				if _filter_skill and skill_level < int(recipe.get("min_skill", 0)):
					continue
				if _filter_ingredients and not _player.can_craft_recipe(recipe).ok:
					continue
				_filtered_recipes.append(recipe)

	if _filtered_recipes.is_empty():
		_selected_index = 0
		_scroll_offset = 0
		if _mode == "encrust" and _status_label != null and _status_label.text == "":
			_status_label.text = "No encrusting recipes for this tool."
	else:
		_selected_index = clamp(_selected_index, 0, _filtered_recipes.size() - 1)
		if _selected_index < _scroll_offset:
			_scroll_offset = _selected_index
		elif _selected_index >= _scroll_offset + VISIBLE_ROWS:
			_scroll_offset = _selected_index - VISIBLE_ROWS + 1

	_sync_encrust_target()
	_rebuild_recipe_rows()
	_update_craft_button_state()

func _rebuild_recipe_rows():
	if _rows_container == null:
		return
	for child in _rows_container.get_children():
		child.queue_free()

	var font = OD.Assets.dialog().font
	var skill_level = _player.get_crafting_skill_level(_active_tool) if _player != null else 0

	for row_slot in range(VISIBLE_ROWS):
		var rec_index = _selected_index + (row_slot - 2)
		if rec_index < 0 or rec_index >= _filtered_recipes.size():
			continue
		var recipe = _filtered_recipes[rec_index]
		var inputs = recipe.get("inputs", [])
		var ing_count = clamp(inputs.size(), 1, 4)
		var is_selected = (rec_index == _selected_index)
		var row_texture_path = "ui/crafting/craft_" + str(ing_count) + "ingredient" + ("1.png" if is_selected else "0.png")
		var row_texture = _load_tex(row_texture_path)

		var row_control = Control.new()
		row_control.position = Vector2(0, row_slot * ROW_STEP_Y)
		row_control.size = ROW_SIZE
		_rows_container.add_child(row_control)

		var row_background = TextureButton.new()
		row_background.texture_normal = row_texture
		row_background.size = ROW_SIZE
		row_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var target_index = rec_index
		row_background.pressed.connect(func():
			_selected_index = target_index
			_sync_encrust_target()
			_rebuild_recipe_rows()
			_update_craft_button_state()
		)
		row_control.add_child(row_background)

		var needed_counts = {}
		var excluded_target = _selected_encrust_target if _mode == "encrust" else null
		for ii in range(ing_count):
			var inp = inputs[ii]
			var inp_name = str(inp.get("name", "")) if typeof(inp) == TYPE_DICTIONARY else str(inp)
			var seen = int(needed_counts.get(inp_name, 0)) + 1
			needed_counts[inp_name] = seen
			var have_amount = 0
			if _player != null:
				have_amount = _player.count_item_in_inventory_excluding(inp_name, excluded_target) if _mode == "encrust" else _player.count_item_in_inventory(inp_name)
			var has_ing = have_amount >= seen
			var slot_x = INGREDIENT_BASE_X - (ing_count - ii) * INGREDIENT_STEP_X
			var item_definition = OD.Database.get_item(inp_name)
			_add_item_slot_icon(row_control, item_definition, inp_name, Vector2(slot_x, INGREDIENT_Y), has_ing, "Have: %d / Need: %d" % [have_amount, seen], font)

		var min_sk = int(recipe.get("min_skill", 0))
		var skill_ok = skill_level >= min_sk
		if _mode == "encrust":
			var slots_array = recipe.get("slots", [])
			var slot_icon_path = OD.Database.get_encrust_slot_icon(slots_array[0] if not slots_array.is_empty() else "weapon")
			var slot_texture = _load_tex(slot_icon_path)
			_add_encrust_slot_icon(row_control, slot_texture, recipe, OUTPUT_SLOT_POS, skill_ok, font, str(min_sk))
		else:
			var out_definition = OD.Database.get_craft_output_for_skill(recipe, max(skill_level, int(recipe.get("min_skill", 0))))
			if out_definition == null and not recipe.outputs.is_empty():
				out_definition = recipe.outputs[0]
			var out_name = str(out_definition.get("name", "Unknown")) if out_definition != null else "Unknown"
			var out_amount = max(1, int(out_definition.get("amount", 1))) if out_definition != null else 1
			var out_item = OD.Database.get_item(out_name)
			var extra = ("x" + str(out_amount) + " | " if out_amount > 1 else "") + "Skill Required: " + str(min_sk)
			_add_item_slot_icon(row_control, out_item, out_name, OUTPUT_SLOT_POS, skill_ok, extra, font, str(min_sk))

func _add_item_slot_icon(parent_control, item_definition, item_name, pos, is_ok, extra_tip, font, skill_text = ""):
	var icon_button = TextureRect.new()
	icon_button.position = pos
	icon_button.size = SLOT_ICON_SIZE
	icon_button.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if item_definition != null and item_definition.get("icon", "") != "":
		icon_button.texture = _load_tex(str(item_definition.icon))
	icon_button.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_button.mouse_entered.connect(func():
		var desc = str(item_definition.get("description", "")) if item_definition != null else ""
		_show_tooltip(item_name + "\n" + extra_tip + ("\n\n" + desc if desc != "" else ""))
	)
	icon_button.mouse_exited.connect(_hide_tooltip)
	parent_control.add_child(icon_button)

	if skill_text != "":
		var sk_label = Label.new()
		sk_label.position = pos + SLOT_SKILL_LABEL_OFFSET
		sk_label.size = SLOT_SKILL_LABEL_SIZE
		sk_label.text = skill_text
		_style_label(sk_label, font, SLOT_SKILL_FONT_SIZE, Color(0.95, 0.92, 0.78))
		parent_control.add_child(sk_label)

	var mark = Label.new()
	mark.position = pos + SLOT_MARK_OFFSET
	mark.size = SLOT_MARK_SIZE
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.text = "v" if is_ok else "x"
	_style_label(mark, font, SLOT_MARK_FONT_SIZE, Color(0.25, 0.9, 0.25) if is_ok else Color(0.95, 0.25, 0.25))
	parent_control.add_child(mark)

func _update_craft_button_state():
	if _craft_button == null or _player == null:
		return
	if _filtered_recipes.is_empty() or _selected_index < 0 or _selected_index >= _filtered_recipes.size():
		_craft_button.disabled = true
		_craft_button.modulate = Color(0.55, 0.55, 0.55, 0.85)
		return
	var recipe = _filtered_recipes[_selected_index]
	var check = _player.can_encrust_item(recipe, _selected_encrust_target) if _mode == "encrust" else _player.can_craft_recipe(recipe)
	_craft_button.disabled = not check.ok
	_craft_button.modulate = Color.WHITE if check.ok else Color(0.6, 0.6, 0.6, 0.9)
	_craft_button.position.y = CRAFT_BTN_POS.y

func _move_selection(delta):
	if _filtered_recipes.is_empty():
		return
	_jump_selection(clamp(_selected_index + delta, 0, _filtered_recipes.size() - 1))

func _jump_selection(target_index):
	if _filtered_recipes.is_empty():
		return
	_selected_index = clamp(target_index, 0, _filtered_recipes.size() - 1)
	if _selected_index < _scroll_offset:
		_scroll_offset = _selected_index
	elif _selected_index >= _scroll_offset + VISIBLE_ROWS:
		_scroll_offset = _selected_index - VISIBLE_ROWS + 1
	_sync_encrust_target()
	_rebuild_recipe_rows()
	_update_craft_button_state()

func _execute_craft():
	if _player == null or _filtered_recipes.is_empty():
		return
	var recipe = _filtered_recipes[_selected_index]
	if _mode == "encrust":
		var enc_result = _player.encrust_item(recipe, _selected_encrust_target)
		if enc_result.ok:
			var message = "Encrusted %s with %s! (Instability: %d)" % [str(enc_result.item_name), str(enc_result.encrust_name), int(enc_result.instability)]
			if str(enc_result.get("unstable_added", "")) != "":
				message += " [Unstable: %s]" % str(enc_result.unstable_added)
			_status_label.text = message
		else:
			_status_label.text = str(enc_result.get("reason", "Cannot encrust"))
		_refresh_recipes()
		return
	var result = _player.craft_recipe(recipe)
	if result.ok:
		var message = "Crafted " + str(result.output_name) + (" x" + str(result.amount) if int(result.amount) > 1 else "") + "!"
		var leftover = result.get("leftover_items", [])
		if not leftover.is_empty():
			var on_drop = _callbacks.get("on_drop_overflow", Callable())
			if on_drop is Callable and on_drop.is_valid():
				for drop_item in leftover:
					on_drop.call(drop_item)
			message += " (Dropped overflow on floor)"
		_status_label.text = message
	else:
		_status_label.text = str(result.get("reason", "Cannot craft"))
	_refresh_recipes()

func _add_encrust_slot_icon(parent_control, slot_texture, encrust_definition, pos, skill_ok, font, skill_text):
	var icon_button = TextureRect.new()
	icon_button.position = pos
	icon_button.size = SLOT_ICON_SIZE
	icon_button.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_button.texture = slot_texture
	icon_button.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_button.mouse_entered.connect(func(): _show_tooltip(_format_encrust_tooltip(encrust_definition)))
	icon_button.mouse_exited.connect(_hide_tooltip)
	parent_control.add_child(icon_button)

	if skill_text != "":
		var sk_label = Label.new()
		sk_label.position = pos + SLOT_SKILL_LABEL_OFFSET
		sk_label.size = SLOT_SKILL_LABEL_SIZE
		sk_label.text = skill_text
		_style_label(sk_label, font, SLOT_SKILL_FONT_SIZE, Color(0.95, 0.92, 0.78))
		parent_control.add_child(sk_label)

	var mark = Label.new()
	mark.position = pos + SLOT_MARK_OFFSET
	mark.size = SLOT_MARK_SIZE
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.text = "v" if skill_ok else "x"
	_style_label(mark, font, SLOT_MARK_FONT_SIZE, Color(0.25, 0.9, 0.25) if skill_ok else Color(0.95, 0.25, 0.25))
	parent_control.add_child(mark)

func _format_encrust_tooltip(encrust_definition):
	var lines = []
	lines.append(str(encrust_definition.get("name", "Encrust")))
	var slots_array = encrust_definition.get("slots", [])
	lines.append("Slots: %s | Skill: %d | Instability: +%d" % [", ".join(slots_array), int(encrust_definition.get("min_skill", 0)), int(encrust_definition.get("instability", 0))])
	for p_buff in encrust_definition.get("primary_buffs", []):
		var pid = int(p_buff.get("id", -1))
		if pid >= 0 and pid < PlayerCharacter.PRIMARY_STAT_KEYS.size():
			var amt = int(p_buff.get("amount", 0))
			lines.append(("+" if amt >= 0 else "") + str(amt) + " " + PlayerCharacter.PRIMARY_STAT_KEYS[pid].capitalize())
	for s_buff in encrust_definition.get("secondary_buffs", []):
		var sid = int(s_buff.get("id", -1))
		var sec_key = PlayerCharacter.SECONDARY_STAT_BY_ID.get(sid, "")
		if sec_key != "":
			var amt = int(s_buff.get("amount", 0))
			lines.append(("+" if amt >= 0 else "") + str(amt) + " " + sec_key.replace("_", " ").capitalize())
	var result_map = encrust_definition.get("resist_buffs", {})
	for damage_type in result_map:
		var amt = int(result_map[damage_type])
		lines.append(("+" if amt >= 0 else "") + str(amt) + " " + str(damage_type).capitalize() + " Resist")
	var damage_map = encrust_definition.get("damage_buffs", {})
	for damage_type in damage_map:
		var amt = int(damage_map[damage_type])
		lines.append(("+" if amt >= 0 else "") + str(amt) + " " + str(damage_type).capitalize() + " Damage")
	var desc = str(encrust_definition.get("description", ""))
	if desc != "":
		lines.append("")
		lines.append(desc)
	return "\n".join(lines)

func _sync_encrust_target():
	_eligible_targets.clear()
	if _mode != "encrust" or _player == null or _filtered_recipes.is_empty():
		_selected_encrust_target = null
		_refresh_encrust_target_icon()
		return
	var encrust_definition = _filtered_recipes[_selected_index]
	_eligible_targets = _player.get_eligible_items_for_encrust(encrust_definition)
	if _eligible_targets.is_empty():
		_selected_encrust_target = null
		_eligible_target_index = 0
	else:
		var found_index = -1
		for ii in range(_eligible_targets.size()):
			if _eligible_targets[ii].item == _selected_encrust_target:
				found_index = ii
				break
		if found_index >= 0:
			_eligible_target_index = found_index
		else:
			_eligible_target_index = 0
			_selected_encrust_target = _eligible_targets[0].item
	_refresh_encrust_target_icon()

func _cycle_encrust_target():
	if _eligible_targets.is_empty():
		if _status_label != null:
			_status_label.text = "No eligible equipment in inventory or equipped."
		return
	_eligible_target_index = (_eligible_target_index + 1) % _eligible_targets.size()
	var entry = _eligible_targets[_eligible_target_index]
	_selected_encrust_target = entry.item
	_refresh_encrust_target_icon()
	_rebuild_recipe_rows()
	_update_craft_button_state()
	if _status_label != null:
		_status_label.text = "Target: %s (%s)" % [str(_selected_encrust_target.get("name", "Item")), str(entry.location)]

func _refresh_encrust_target_icon():
	if _encrust_target_icon == null:
		return
	if _selected_encrust_target == null:
		_encrust_target_icon.texture = null
		return
	var icon_path = str(_selected_encrust_target.get("icon", ""))
	_encrust_target_icon.texture = _load_tex(icon_path) if icon_path != "" else null

func _show_encrust_target_tooltip():
	if _selected_encrust_target == null:
		_show_tooltip("Target Equipment Slot\nNo eligible item selected.\nClick to cycle eligible items.")
		return
	var lines = []
	lines.append(str(_selected_encrust_target.get("name", "Item")))
	var encrusts = _selected_encrust_target.get("encrusts", [])
	if not encrusts.is_empty():
		lines.append("Encrusts: " + ", ".join(encrusts))
		lines.append("Instability: " + str(int(_selected_encrust_target.get("instability", 0))))
	if _eligible_targets.size() > 1:
		lines.append("Click slot to cycle (%d/%d)" % [_eligible_target_index + 1, _eligible_targets.size()])
	_show_tooltip("\n".join(lines))

func _show_tooltip(text):
	if _tooltip_label != null and _tooltip_panel != null:
		_tooltip_label.text = text
		_tooltip_panel.visible = true

func _hide_tooltip():
	if _tooltip_panel != null:
		_tooltip_panel.visible = false
