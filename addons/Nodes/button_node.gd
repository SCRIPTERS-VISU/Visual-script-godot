@tool
extends GraphNode

var node_type: String = "button"
var _btn_picker: MenuButton
var _dst_picker: MenuButton
var _buttons_in_scene: Array = []
var selected_button: String = ""
var connected_scene_path: String = ""
var destination_scene_path: String = ""

# set from outside whenever the scene list changes
var _all_scenes: Array = []

func _ready() -> void:
	title = "  🔘 Button"
	resizable = false
	custom_minimum_size = Vector2(260, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.36, 0.15)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.border_width_top = 2; style.border_color = Color(0.28, 0.88, 0.38)
	add_theme_stylebox_override("titlebar", style)

	# ── Row 0 : seletor de botão ──────────────────────────────────────────
	var row0 = HBoxContainer.new()
	row0.custom_minimum_size = Vector2(240, 32)
	var lbl0 = Label.new(); lbl0.text = "Botão:"; lbl0.custom_minimum_size.x = 46
	row0.add_child(lbl0)
	_btn_picker = MenuButton.new()
	_btn_picker.text = "── Conecte à Scene ──"
	_btn_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_picker.get_popup().index_pressed.connect(_on_button_selected)
	row0.add_child(_btn_picker)
	add_child(row0)    # slot 0

	# ── Row 1 : destino da navegação ──────────────────────────────────────
	var row1 = HBoxContainer.new()
	row1.custom_minimum_size = Vector2(240, 32)
	var lbl1 = Label.new(); lbl1.text = "→ Cena:"; lbl1.custom_minimum_size.x = 46
	lbl1.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	row1.add_child(lbl1)
	_dst_picker = MenuButton.new()
	_dst_picker.text = "── Destino ──"
	_dst_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dst_picker.get_popup().index_pressed.connect(_on_dst_selected)
	row1.add_child(_dst_picker)
	add_child(row1)    # slot 1

	# ── Row 2 : label para Event/Multiple ────────────────────────────────
	var row2 = HBoxContainer.new()
	row2.custom_minimum_size = Vector2(240, 24)
	var lbl2 = Label.new()
	lbl2.text = "  Event / Multiple"
	lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl2.add_theme_color_override("font_color", Color(1.0, 0.60, 0.10))
	lbl2.add_theme_font_size_override("font_size", 11)
	row2.add_child(lbl2)
	add_child(row2)    # slot 2

	# ── Slots ────────────────────────────────────────────────────────────
	# slot 0: left=blue (from Scene), right=green (to Multiple)
	set_slot(0, true,  0, Color(0.30, 0.60, 1.00),
	            true,  0, Color(0.28, 0.88, 0.38))
	# slot 1: no ports (just the dst picker)
	set_slot(1, false, 0, Color.WHITE, false, 0, Color.WHITE)
	# slot 2: left=orange (from Event), no right
	set_slot(2, true,  2, Color(1.00, 0.60, 0.10),
	            false, 0, Color.WHITE)

# ── Called by main_panel when scene list refreshes ───────────────────────
func refresh_scenes(scenes: Array) -> void:
	_all_scenes = scenes
	var popup = _dst_picker.get_popup()
	popup.clear()
	for sp in scenes:
		popup.add_item(sp.get_file().get_basename())

# ── Called when connected to a Scene node ───────────────────────────────
func update_from_scene(scene_path: String) -> void:
	connected_scene_path = scene_path
	_buttons_in_scene = _scan_buttons(scene_path)
	var popup = _btn_picker.get_popup()
	popup.clear()
	if _buttons_in_scene.is_empty():
		_btn_picker.text = "── Sem botões ──"
		popup.add_item("(nenhum Button encontrado)")
	else:
		_btn_picker.text = "── Selecionar Botão ──"
		for b in _buttons_in_scene:
			popup.add_item(b)

func _scan_buttons(path: String) -> Array:
	var result: Array = []
	if not ResourceLoader.exists(path): return result
	var packed = load(path)
	if not packed is PackedScene: return result
	var inst = packed.instantiate()
	_walk(inst, inst.name, result)
	inst.free()
	return result

func _walk(node: Node, cur_path: String, out: Array) -> void:
	if node is BaseButton: out.append(cur_path)
	for child in node.get_children():
		_walk(child, cur_path + "/" + child.name, out)

func _on_button_selected(index: int) -> void:
	if index < _buttons_in_scene.size():
		selected_button = _buttons_in_scene[index]
		_btn_picker.text = "  " + selected_button.split("/")[-1]

func _on_dst_selected(index: int) -> void:
	if index < _all_scenes.size():
		destination_scene_path = _all_scenes[index]
		_dst_picker.text = "  → " + destination_scene_path.get_file().get_basename()
