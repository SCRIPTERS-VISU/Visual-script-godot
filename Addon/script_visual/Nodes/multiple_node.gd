@tool
extends GraphNode

var node_type: String = "multiple"

func _ready() -> void:
	title = "  🔀 Multiple"
	resizable = false
	custom_minimum_size = Vector2(220, 0)

	# Style titlebar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.10, 0.48)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.border_width_top = 2
	style.border_color = Color(0.75, 0.30, 1.00)
	add_theme_stylebox_override("titlebar", style)

	# Row 0 — Button hub input
	var row0 = _make_row("  🔘 Button Hub", Color(0.30, 0.90, 0.40), true)
	add_child(row0)  # index 0 → slot 0

	# Rows 1–8 — Event inputs
	for i in 8:
		var row = _make_row("  ⚡ Event %d" % (i + 1), Color(1.00, 0.60, 0.10), false)
		add_child(row)  # index i+1 → slot i+1

	# Slot 0: left type-0 (green, from Button output), right type-0 (purple, output)
	set_slot(0,
		true, 0, Color(0.30, 0.90, 0.40),
		true, 0, Color(0.75, 0.30, 1.00))

	# Slots 1–8: left type-2 (orange, from Event), no right
	for i in 8:
		set_slot(i + 1,
			true,  2, Color(1.00, 0.60, 0.10),
			false, 0, Color.WHITE)

func _make_row(text: String, color: Color, bold: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(200, 26)
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)
	return row
