@tool
extends EditorPlugin

var visual_screen: Node = null  # Use Node para compatibilidade com qualquer raiz de cena

const SCENE_PATH := "res://addons/script_visual/scenes/visual_screen.tscn"


func _enter_tree() -> void:
		var packed_scene := load(SCENE_PATH) as PackedScene
		if packed_scene == null:
						push_error("Não foi possível carregar a cena: " + SCENE_PATH)
						return
									
						visual_screen = packed_scene.instantiate()
						if visual_screen == null:
														push_error("Falha ao instanciar a cena: " + SCENE_PATH)
														return
																	
																		# Adiciona ao main screen do editor
														get_editor_interface().get_editor_main_screen().add_child(visual_screen)
														visual_screen.visible = false  # Esconde inicialmente
	
	
func _exit_tree() -> void:
			if visual_screen != null:
						visual_screen.queue_free()
						visual_screen = null
								
								
func _has_main_screen() -> bool:
										return true
										
func _make_visible(visible: bool) -> void:
		if visual_screen != null:
					visual_screen.visible = visible
					
					
func _get_plugin_name() -> String:
							return "Visual Script"
									
func _get_plugin_icon() -> Texture2D:
						return load("res://addons/script_visual/sem-fundo.png")
