extends Control

static func init_container():
	return Control.new()

const HIGH_SCORES_PATH = "user://high_scores.json"

var _scores = []
var _sort_key = "score"
var _sort_descending = true
var _score_tree = null
var _empty_label = null

func _ready():
	call_deferred("_build_gui")

func _build_gui():
	var assets = OD.Assets.high_scores_menu()
	var container = get_node("/root/Container")
	container.set_size(OD.Settings.display_size())

	var header_background = TextureRect.new()
	header_background.texture = assets.textures.header_background
	header_background.stretch_mode = TextureRect.STRETCH_TILE
	header_background.size = Vector2(OD.Settings.display_size().x, header_background.texture.get_height())
	container.add_child(header_background)

	var back_button = OD.Chrome.button(assets.textures.back_button)
	back_button.anchor_left = 0
	back_button.anchor_top = 0
	back_button.offset_left = 0
	back_button.offset_top = 0
	back_button.pressed.connect(_on_BackButton_pressed)
	container.add_child(back_button)

	var title_label = Label.new()
	title_label.text = "High Scores"
	title_label.anchor_left = 0.5
	title_label.offset_left = -120
	title_label.offset_top = 12
	title_label.custom_minimum_size = Vector2(240, 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", assets.fonts.default)
	title_label.add_theme_font_size_override("font_size", 36)
	container.add_child(title_label)

	var content_vbox = VBoxContainer.new()
	content_vbox.anchor_left = 0.1
	content_vbox.anchor_top = 0.2
	content_vbox.anchor_right = 0.9
	content_vbox.anchor_bottom = 0.9
	content_vbox.add_theme_constant_override("separation", 12)
	container.add_child(content_vbox)

	var sort_row = HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 12)
	content_vbox.add_child(sort_row)

	for sort_option in [
		{ key = "score", label = "Sort by Score" },
		{ key = "floor", label = "Sort by Floor" },
		{ key = "name", label = "Sort by Name" }
	]:
		var btn = Button.new()
		btn.text = sort_option.label
		btn.pressed.connect(func(): _sort_by(sort_option.key))
		sort_row.add_child(btn)

	_empty_label = Label.new()
	_empty_label.text = "No high scores recorded yet."
	_empty_label.add_theme_font_override("font", assets.fonts.default)
	_empty_label.add_theme_font_size_override("font_size", 26)
	content_vbox.add_child(_empty_label)

	_score_tree = Tree.new()
	_score_tree.columns = 5
	_score_tree.hide_root = true
	_score_tree.column_titles_visible = true
	_score_tree.set_column_title(0, "Character")
	_score_tree.set_column_title(1, "Score")
	_score_tree.set_column_title(2, "Floor")
	_score_tree.set_column_title(3, "Difficulty")
	_score_tree.set_column_title(4, "Outcome")
	_score_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_score_tree.add_theme_font_override("font", assets.fonts.default)
	_score_tree.add_theme_font_size_override("font_size", 22)
	content_vbox.add_child(_score_tree)

	_load_scores()
	_render_scores()

func _load_scores():
	_scores = []
	if not FileAccess.file_exists(HIGH_SCORES_PATH):
		return
	var file = FileAccess.open(HIGH_SCORES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		for entry in parsed:
			if typeof(entry) == TYPE_DICTIONARY:
				_scores.append(entry)

func _sort_by(key):
	if _sort_key == key:
		_sort_descending = not _sort_descending
	else:
		_sort_key = key
		_sort_descending = key != "name"
	_render_scores()

func _render_scores():
	_score_tree.clear()
	var has_scores = _scores.size() > 0
	_empty_label.visible = not has_scores
	_score_tree.visible = has_scores
	if not has_scores:
		return
	_scores.sort_custom(func(entry_a, entry_b):
		var val_a = entry_a.get(_sort_key, 0)
		var val_b = entry_b.get(_sort_key, 0)
		if _sort_descending:
			return val_a > val_b
		return val_a < val_b
	)
	var root = _score_tree.create_item()
	for entry in _scores:
		var item = _score_tree.create_item(root)
		item.set_text(0, str(entry.get("name", "Unknown")))
		item.set_text(1, str(entry.get("score", 0)))
		item.set_text(2, str(entry.get("floor", 1)))
		item.set_text(3, str(entry.get("difficulty", "")))
		item.set_text(4, str(entry.get("outcome", "")))

func _on_BackButton_pressed():
	OD.Scenes.goto(OD.Scenes.MAIN_MENU)
