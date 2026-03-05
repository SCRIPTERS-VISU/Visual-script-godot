@tool
extends GraphNode

var node_type: String = "event"
var _menu_button: MenuButton
var selected_event: String = ""

const BUTTON_EVENTS: Array = [
	"pressed",
	"button_down",
	"button_up",
	"toggled",
	"mouse_entered",
	"mouse_exited",
	"focus_entered",
	"focus_exited",
	"gui_input",
	"draw",
	"visibility_changed",
	"tree_entered",
	"tree_exited",
]

const EVENT_ICONS: Array = [
	"🖱️", "⬇️", "⬆️", "🔁",
	"➡️", "⬅️", "🔵", "⚫",
	"📥", "🎨", "👁️", "🌳", "🌿",
]

func _ready() -> void:
	title = "  ⚡ Event"
	resizable = false
	custom_minimum_size = Vector2(240, 0)

	# Style titlebar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.25, 0.05)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.border_width_top = 2
	style.border_color = Color(1.00, 0.60, 0.10)
	add_theme_stylebox_override("titlebar", style)

	# Row 0 — event selector
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(220, 32)

	var label = Label.new()
	label.text = "Evento:"
	label.custom_minimum_size.x = 50
	row.add_child(label)

	_menu_button = MenuButton.new()
	_menu_button.text = "── Selecionar ──"
	_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_button.flat = false
	row.add_child(_menu_button)

	add_child(row)  # index 0 → slot 0

	# Populate events
	var popup = _menu_button.get_popup()
	for i in BUTTON_EVENTS.size():
		var icon = EVENT_ICONS[i] if i < EVENT_ICONS.size() else "•"
		popup.add_item(icon + " " + BUTTON_EVENTS[i])
	popup.index_pressed.connect(_on_event_selected)

	# Slot 0: NO left input, right output type-2 (orange)
	set_slot(0,
		false, 2, Color(1.00, 0.60, 0.10),
		true,  2, Color(1.00, 0.60, 0.10))

func _on_event_selected(index: int) -> void:
	if index < BUTTON_EVENTS.size():
		selected_event = BUTTON_EVENTS[index]
		var icon = EVENT_ICONS[index] if index < EVENT_ICONS.size() else "•"
		_menu_button.text = "  " + icon + " " + selected_event
