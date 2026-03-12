@tool
extends GraphNode

signal scene_changed(scene_path: String)

var node_type: String = "scene"
var _menu_button: MenuButton
var _scenes: Array = []
var selected_scene_path: String = ""
var selected_scene_name: String = ""

func _ready() -> void:
	title = "  📁 Scene"
	resizable = false
	custom_minimum_size = Vector2(240, 0)

	# Style the title bar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.25, 0.55)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.border_width_top = 2
	style.border_color = Color(0.35, 0.55, 1.0)
	add_theme_stylebox_override("titlebar", style)

	# Row 0 — scene selector
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(220, 32)

	var label = Label.new()
	label.text = "Cena:"
	label.custom_minimum_size.x = 44
	row.add_child(label)

	_menu_button = MenuButton.new()
	_menu_button.text = "── Selecionar ──"
	_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_button.flat = false
	_menu_button.get_popup().index_pressed.connect(_on_scene_selected)
	row.add_child(_menu_button)

	add_child(row)

	# Slot 0: left-input (blue, type 0), right-output (blue, type 0)
	set_slot(0,
		true, 0, Color(0.30, 0.60, 1.00),
		true, 0, Color(0.30, 0.60, 1.00))

func update_scenes(scenes: Array) -> void:
	_scenes = scenes
	var popup = _menu_button.get_popup()
	popup.clear()
	if scenes.is_empty():
		popup.add_item("(sem cenas no projeto)")
	else:
		for sp in scenes:
			popup.add_item(sp.get_file().get_basename())

func _on_scene_selected(index: int) -> void:
	if index < _scenes.size():
		selected_scene_path = _scenes[index]
		selected_scene_name = selected_scene_path.get_file().get_basename()
		_menu_button.text = "  " + selected_scene_name
		scene_changed.emit(selected_scene_path)
