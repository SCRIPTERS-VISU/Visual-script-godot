@tool
extends EditorPlugin

var _panel: Control

func _enter_tree() -> void:
	var script = load("res://addons/visual_scene_connector/main_panel.gd")
	_panel = script.new()
	_panel.editor_plugin = self
	_panel.name = "Visual Script"
	get_editor_interface().get_editor_main_screen().add_child(_panel)
	_make_visible(false)

func _exit_tree() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null

# ─── Godot 4 virtual methods com underscore ────────────────────────────────

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "Visual script"

func _get_plugin_icon() -> Texture2D:
	# Tenta carregar o SVG; se falhar usa ícone interno garantido
	var path := "res://addons/visual_scene_connector/logo.png"
	if ResourceLoader.exists(path):
		var tex = load(path) as Texture2D
		if tex:
			return tex
	return get_editor_interface().get_base_control() \
		.get_theme_icon("Node", "EditorIcons")

func _make_visible(visible: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = visible
