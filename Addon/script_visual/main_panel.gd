@tool
extends Control

var editor_plugin: EditorPlugin

var _graph: GraphEdit
var _node_counter: int = 0
var _scenes_list: Array = []
var _nodes: Dictionary = {}
var _scan_timer: Timer
var _scenes_count_label: Label
var _log_panel: RichTextLabel

const _SCENE_NODE_PATH    = "res://addons/visual_script/nodes/scene_node.gd"
const _BUTTON_NODE_PATH   = "res://addons/visual_script/nodes/button_node.gd"
const _EVENT_NODE_PATH    = "res://addons/visual_script/nodes/event_node.gd"
const _MULTIPLE_NODE_PATH = "res://addons/visual_script/nodes/multiple_node.gd"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_build_ui()
	_scan_scenes()
	_setup_scan_timer()

# ══════════════════════════════ UI BUILD ═══════════════════════════════════

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	add_child(root)

	root.add_child(_build_toolbar())
	root.add_child(_hsep())

	_graph = _build_graph()
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_graph)

	root.add_child(_hsep())
	root.add_child(_build_log_panel())

func _build_toolbar() -> PanelContainer:
	var panel = PanelContainer.new()
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.11, 0.15)
	bg.border_width_bottom = 1
	bg.border_color = Color(0.22, 0.22, 0.32)
	panel.add_theme_stylebox_override("panel", bg)

	var bar = HBoxContainer.new()
	bar.custom_minimum_size.y = 48
	bar.add_theme_constant_override("separation", 5)
	panel.add_child(bar)

	bar.add_child(_make_logo())
	bar.add_child(_vsep())

	var bs = _node_btn("  📁  Scene",    Color(0.14,0.26,0.68), Color(0.35,0.55,1.0), "Adiciona nó de Cena")
	bs.pressed.connect(_add_scene_node);    bar.add_child(bs)
	var bb = _node_btn("  🔘  Button",   Color(0.10,0.36,0.15), Color(0.28,0.88,0.38), "Adiciona nó de Botão")
	bb.pressed.connect(_add_button_node);   bar.add_child(bb)
	var be = _node_btn("  ⚡  Event",    Color(0.44,0.20,0.04), Color(1.0,0.58,0.08), "Adiciona nó de Evento")
	be.pressed.connect(_add_event_node);    bar.add_child(be)
	var bm = _node_btn("  🔀  Multiple", Color(0.26,0.07,0.44), Color(0.74,0.28,1.0), "Adiciona Hub Multiple")
	bm.pressed.connect(_add_multiple_node); bar.add_child(bm)

	bar.add_child(_vsep())

	# ── GERAR CÓDIGO ── botão destaque ────────────────────────────────────
	var bg_btn = _node_btn("  🔄 Gerar Código", Color(0.50,0.32,0.00), Color(1.0,0.80,0.10),
		"Gera scripts GDScript e os anexa às cenas conectadas")
	bg_btn.pressed.connect(_generate_all)
	bar.add_child(bg_btn)

	bar.add_child(_vsep())

	var br = _util_btn("  🔄  Atualizar", Color(0.14,0.18,0.24))
	br.pressed.connect(_scan_scenes); bar.add_child(br)
	var bc = _util_btn("  🗑️  Limpar",    Color(0.28,0.08,0.08))
	bc.pressed.connect(_clear_graph);  bar.add_child(bc)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	_scenes_count_label = Label.new()
	_scenes_count_label.text = "Cenas: 0"
	_scenes_count_label.modulate = Color(0.7,0.85,1.0,0.65)
	_scenes_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scenes_count_label.add_theme_font_size_override("font_size", 12)
	bar.add_child(_scenes_count_label)

	bar.add_child(_vsep())
	var ver = Label.new(); ver.text = "VSC v1.0  "
	ver.modulate.a = 0.28; ver.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 11)
	bar.add_child(ver)

	return panel

func _build_graph() -> GraphEdit:
	var g = GraphEdit.new()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	g.right_disconnects     = true
	g.snapping_enabled      = true
	g.snapping_distance     = 16
	g.minimap_enabled       = true
	g.minimap_size          = Vector2(180, 120)
	g.connection_request.connect(_on_connection_request)
	g.disconnection_request.connect(_on_disconnection_request)
	g.delete_nodes_request.connect(_on_delete_nodes_request)
	return g

func _build_log_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 90
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.08, 0.11)
	s.border_width_top = 1; s.border_color = Color(0.20, 0.20, 0.30)
	panel.add_theme_stylebox_override("panel", s)

	var vb = VBoxContainer.new(); panel.add_child(vb)

	var hdr = HBoxContainer.new()
	hdr.custom_minimum_size.y = 22
	var lbl = Label.new(); lbl.text = "  📋 Log de Geração de Código"
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.7, 0.85, 1.0, 0.7)
	hdr.add_child(lbl)
	var clear_log = Button.new(); clear_log.text = "limpar"
	clear_log.flat = true; clear_log.add_theme_font_size_override("font_size", 10)
	clear_log.pressed.connect(func(): _log_panel.clear(); _log("[color=#666]Log limpo.[/color]"))
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(sp); hdr.add_child(clear_log)
	vb.add_child(hdr)

	_log_panel = RichTextLabel.new()
	_log_panel.bbcode_enabled = true
	_log_panel.scroll_following = true
	_log_panel.custom_minimum_size.y = 64
	_log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.add_theme_font_size_override("normal_font_size", 11)
	_log_panel.text = "[color=#555]Aguardando geração de código...[/color]"
	vb.add_child(_log_panel)

	return panel

# ─── helpers de widget ─────────────────────────────────────────────────────

func _make_logo() -> PanelContainer:
	var p = PanelContainer.new(); p.custom_minimum_size = Vector2(108, 36)
	var s = StyleBoxFlat.new(); s.bg_color = Color(0.07,0.09,0.18)
	s.border_color = Color(0.34,0.54,1.0)
	for k in ["border_width_left","border_width_right","border_width_top","border_width_bottom"]: s.set(k,3)
	for k in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: s.set(k,8)
	p.add_theme_stylebox_override("panel",s)
	var hb = HBoxContainer.new(); hb.alignment = BoxContainer.ALIGNMENT_CENTER
	var ico = Label.new(); ico.text="</>"; ico.add_theme_font_size_override("font_size",18)
	var txt = Label.new(); txt.text=" Visual Script"; txt.add_theme_font_size_override("font_size",15)
	txt.add_theme_color_override("font_color",Color(0.5,0.78,1.0))
	hb.add_child(ico); hb.add_child(txt); p.add_child(hb); return p

func _vsep() -> VSeparator:
	var v = VSeparator.new(); v.modulate = Color(0.35,0.35,0.45,0.55); return v
func _hsep() -> HSeparator:
	var h = HSeparator.new(); h.modulate = Color(0.25,0.25,0.35); return h

func _node_btn(label:String, bg:Color, border:Color, tip:String) -> Button:
	var btn = Button.new(); btn.text=label; btn.tooltip_text=tip
	btn.custom_minimum_size = Vector2(115,36)
	btn.add_theme_stylebox_override("normal",  _flat(bg,border,2))
	btn.add_theme_stylebox_override("hover",   _flat(bg.lightened(0.18),border,3))
	btn.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.18),border,1))
	return btn

func _util_btn(label:String, bg:Color) -> Button:
	var btn = Button.new(); btn.text=label; btn.custom_minimum_size=Vector2(0,36)
	btn.add_theme_stylebox_override("normal", _flat(bg,Color.TRANSPARENT,0))
	btn.add_theme_stylebox_override("hover",  _flat(bg.lightened(0.18),Color.TRANSPARENT,0))
	return btn

func _flat(bg:Color,border:Color,bw:int)->StyleBoxFlat:
	var s=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.border_width_bottom=bw
	s.content_margin_left=8; s.content_margin_right=8
	for k in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]: s.set(k,5)
	return s

func _log(msg: String) -> void:
	if is_instance_valid(_log_panel):
		_log_panel.append_text("\n" + msg)

# ══════════════════════════════ SCENE SCAN ═════════════════════════════════

func _scan_scenes() -> void:
	_scenes_list.clear()
	_scan_dir("res://", _scenes_list)
	if is_instance_valid(_scenes_count_label):
		_scenes_count_label.text = "Cenas: %d" % _scenes_list.size()
	for k in _nodes:
		var nd = _nodes[k]
		if not is_instance_valid(nd): continue
		if nd.has_method("update_scenes"):
			nd.update_scenes(_scenes_list)
		if nd.has_method("refresh_scenes"):
			nd.refresh_scenes(_scenes_list)

func _scan_dir(path: String, result: Array) -> void:
	var dir = DirAccess.open(path)
	if not dir: return
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if dir.current_is_dir() and not f.begins_with(".") and f != "addons":
			_scan_dir(path + f + "/", result)
		elif f.ends_with(".tscn"):
			result.append(path + f)
		f = dir.get_next()
	dir.list_dir_end()

func _setup_scan_timer() -> void:
	_scan_timer = Timer.new()
	_scan_timer.wait_time = 2.5
	_scan_timer.autostart = true
	_scan_timer.timeout.connect(_scan_scenes)
	add_child(_scan_timer)

# ══════════════════════════════ NODE CREATION ══════════════════════════════

func _add_scene_node() -> void:
	var nd: GraphNode = load(_SCENE_NODE_PATH).new()
	_register_node(nd, "Scene")
	nd.update_scenes(_scenes_list)
	nd.scene_changed.connect(_on_scene_node_changed.bind(nd))

func _add_button_node() -> void:
	var nd: GraphNode = load(_BUTTON_NODE_PATH).new()
	_register_node(nd, "Button")
	nd.refresh_scenes(_scenes_list)

func _add_event_node() -> void:
	_register_node(load(_EVENT_NODE_PATH).new(), "Event")

func _add_multiple_node() -> void:
	_register_node(load(_MULTIPLE_NODE_PATH).new(), "Multiple")

func _register_node(nd: GraphNode, prefix: String) -> void:
	nd.name = "%sNode_%03d" % [prefix, _node_counter]
	_node_counter += 1
	nd.position_offset = _smart_pos()
	_graph.add_child(nd)
	_nodes[nd.name] = nd
	nd.close_request.connect(_on_node_close.bind(nd))

func _smart_pos() -> Vector2:
	var base = _graph.scroll_offset + _graph.size * 0.5 - Vector2(120, 80)
	return base + Vector2((_node_counter % 5) * 28, (_node_counter % 4) * 28)

# ══════════════════════════════ CONNECTIONS ════════════════════════════════

func _on_connection_request(fn:StringName, fp:int, tn:StringName, tp:int) -> void:
	if fn == tn: return
	var fnd = _nodes.get(fn); var tnd = _nodes.get(tn)
	if not (is_instance_valid(fnd) and is_instance_valid(tnd)): return
	for c in _graph.get_connection_list():
		if c.from_node==fn and c.from_port==fp and c.to_node==tn and c.to_port==tp: return
	_graph.connect_node(fn, fp, tn, tp)
	if fnd.get("node_type") == "scene" and tnd.get("node_type") == "button":
		var sp = fnd.get("selected_scene_path")
		if sp: tnd.call("update_from_scene", sp)

func _on_disconnection_request(fn:StringName,fp:int,tn:StringName,tp:int) -> void:
	_graph.disconnect_node(fn,fp,tn,tp)

func _on_scene_node_changed(scene_path:String, scene_node:GraphNode) -> void:
	for c in _graph.get_connection_list():
		if c.from_node == scene_node.name and c.from_port == 0:
			var tnd = _nodes.get(c.to_node)
			if is_instance_valid(tnd) and tnd.has_method("update_from_scene"):
				tnd.update_from_scene(scene_path)

func _on_node_close(nd:GraphNode) -> void:
	for c in _graph.get_connection_list():
		if c.from_node==nd.name or c.to_node==nd.name:
			_graph.disconnect_node(c.from_node,c.from_port,c.to_node,c.to_port)
	_nodes.erase(nd.name); nd.queue_free()

func _on_delete_nodes_request(nodes:Array) -> void:
	for n in nodes:
		var nd=_nodes.get(n)
		if is_instance_valid(nd): _on_node_close(nd)

func _clear_graph() -> void:
	for k in _nodes.keys():
		var nd=_nodes[k]
		if is_instance_valid(nd): nd.queue_free()
	_nodes.clear()
	for c in _graph.get_connection_list():
		_graph.disconnect_node(c.from_node,c.from_port,c.to_node,c.to_port)

# ══════════════════════════════ CODE GENERATION ═══════════════════════════

func _generate_all() -> void:
	_log_panel.clear()
	_log("[color=#ffcc33][b]⚙️  Iniciando geração de código...[/b][/color]")
	var count := 0

	for conn in _graph.get_connection_list():
		var fnd = _nodes.get(conn.from_node)
		var tnd = _nodes.get(conn.to_node)
		if not (is_instance_valid(fnd) and is_instance_valid(tnd)): continue

		var ft = fnd.get("node_type")
		var tt = tnd.get("node_type")

		# ── Scene → Scene ─────────────────────────────────────────────────
		if ft == "scene" and tt == "scene":
			var src: String = fnd.get("selected_scene_path")
			var dst: String = tnd.get("selected_scene_path")
			if src == "" or dst == "":
				_log("[color=#ff6666]⚠️  Scene→Scene: selecione as duas cenas antes de gerar.[/color]")
				continue
			if src == dst:
				_log("[color=#ff6666]⚠️  Scene→Scene: origem e destino são a mesma cena.[/color]")
				continue
			var msgs := _gen_scene_to_scene(src, dst)
			for m in msgs: _log(m)
			count += 1

		# ── Scene → Button (Button tem destino configurado) ───────────────
		elif ft == "scene" and tt == "button":
			var src: String = fnd.get("selected_scene_path")
			var btn_path: String = tnd.get("selected_button")
			var dst: String = tnd.get("destination_scene_path")
			if src == "":
				_log("[color=#ff6666]⚠️  Button: Scene de origem não selecionada.[/color]"); continue
			if btn_path == "":
				_log("[color=#ff6666]⚠️  Button: nenhum botão selecionado no nó Button.[/color]"); continue
			if dst == "":
				_log("[color=#ff6666]⚠️  Button: escolha a cena destino (→ Cena) no nó Button.[/color]"); continue
			var msgs := _gen_button_to_scene(src, btn_path, dst)
			for m in msgs: _log(m)
			count += 1

	if count == 0:
		_log("[color=#aaaaaa]Nenhuma conexão válida encontrada. Conecte Scene→Scene ou Scene→Button e configure os destinos.[/color]")
	else:
		_log("[color=#88ff88][b]✅  Geração concluída! %d conexão(ões) processada(s).[/b][/color]" % count)
		# Forçar reimport via EditorFileSystem
		if editor_plugin:
			editor_plugin.get_editor_interface().get_resource_filesystem().scan()

# ── Scene → Scene ──────────────────────────────────────────────────────────
func _gen_scene_to_scene(src: String, dst: String) -> Array:
	var msgs: Array = []
	var src_name = src.get_file().get_basename()
	var dst_name = dst.get_file().get_basename()

	# 1. Descobrir tipo do nó raiz da cena fonte
	var root_type := _get_tscn_root_type(src)
	if root_type == "":
		msgs.append("[color=#ff6666]ERRO: não foi possível ler o tipo raiz de '%s'[/color]" % src_name)
		return msgs

	# 2. Criar o script GDScript
	var script_path := "res://vsc_%s_to_%s.gd" % [src_name, dst_name]
	var script_content := """extends {root}

# Script gerado automaticamente pelo Visual Scene Connector
# Ao entrar nesta cena, redireciona para: {dst}

func _ready() -> void:
	get_tree().change_scene_to_file("{dst}")
""".format({"root": root_type, "dst": dst})

	var write_result := _write_script(script_path, script_content)
	msgs.append(write_result)
	if write_result.begins_with("[color=#ff"):
		return msgs

	# 3. Anexar script ao nó raiz da cena
	var attach_result := _attach_script_to_tscn(src, "", script_path)
	msgs.append(attach_result)
	return msgs

# ── Button → Scene ─────────────────────────────────────────────────────────
func _gen_button_to_scene(src: String, btn_path: String, dst: String) -> Array:
	var msgs: Array = []
	var src_name = src.get_file().get_basename()
	var dst_name = dst.get_file().get_basename()

	# btn_path é tipo "RootNode/Button" ou "RootNode/Panel/StartButton"
	# descobre tipo do nó botão
	var btn_type := _get_node_type_in_tscn(src, btn_path)
	if btn_type == "":
		btn_type = "Button"   # fallback seguro
		msgs.append("[color=#ffaa44]⚠️  Tipo do botão não detectado, usando 'Button' como extends.[/color]")

	# Caminho do script
	var btn_leaf = btn_path.split("/")[-1]
	var script_path := "res://vsc_%s_%s_to_%s.gd" % [src_name, btn_leaf, dst_name]
	var script_content := """extends {bt}

# Script gerado automaticamente pelo Visual Scene Connector
# Botão: {bp}  |  Cena destino: {dst}

func _pressed() -> void:
	get_tree().change_scene_to_file("{dst}")
""".format({"bt": btn_type, "bp": btn_path, "dst": dst})

	var write_result := _write_script(script_path, script_content)
	msgs.append(write_result)
	if write_result.begins_with("[color=#ff"):
		return msgs

	# Caminho relativo ao nó raiz no tscn (sem o nome do nó raiz)
	var parts = btn_path.split("/")
	var tscn_rel_path := "/".join(parts.slice(1)) if parts.size() > 1 else ""

	var attach_result := _attach_script_to_tscn(src, tscn_rel_path, script_path)
	msgs.append(attach_result)
	return msgs

# ── Escreve o arquivo .gd ───────────────────────────────────────────────────
func _write_script(path: String, content: String) -> String:
	var full = ProjectSettings.globalize_path(path)
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		return "[color=#ff5555]ERRO ao criar script '%s' (código %d)[/color]" % [path, FileAccess.get_open_error()]
	f.store_string(content)
	f.close()
	return "[color=#88ffaa]📝  Script criado: [b]%s[/b][/color]" % path

# ── Lê tipo do nó raiz do .tscn ────────────────────────────────────────────
func _get_tscn_root_type(tscn_path: String) -> String:
	var content = FileAccess.get_file_as_string(tscn_path)
	if content == "": return ""
	for line in content.split("\n"):
		# linha raiz não tem parent=
		if line.begins_with("[node") and "parent=" not in line:
			var m = _extract_attr(line, "type")
			return m if m != "" else "Node"
	return ""

# ── Lê tipo de um nó filho pelo path "Root/Button" ────────────────────────
func _get_node_type_in_tscn(tscn_path: String, full_path: String) -> String:
	var parts = full_path.split("/")
	if parts.size() < 2: return ""
	var node_name = parts[-1]
	var tscn_parent: String
	if parts.size() == 2:
		tscn_parent = "."
	else:
		tscn_parent = "/".join(parts.slice(1, parts.size() - 1))

	var content = FileAccess.get_file_as_string(tscn_path)
	if content == "": return ""
	for line in content.split("\n"):
		if not line.begins_with("[node"): continue
		if ('name="%s"' % node_name) not in line: continue
		if ('parent="%s"' % tscn_parent) not in line: continue
		return _extract_attr(line, "type")
	return ""

# ── Extrai o valor de um atributo da linha de cabeçalho do tscn ───────────
func _extract_attr(line: String, attr: String) -> String:
	var key = attr + '="'
	var idx = line.find(key)
	if idx == -1: return ""
	var start = idx + key.length()
	var end = line.find('"', start)
	if end == -1: return ""
	return line.substr(start, end - start)

# ── Anexa script a um nó no .tscn via manipulação de texto ────────────────
# node_rel_path: "" = raiz; "Button" = filho direto; "Panel/Button" = neto
func _attach_script_to_tscn(tscn_path: String, node_rel_path: String, script_res_path: String) -> String:
	var src_name = tscn_path.get_file()
	var content = FileAccess.get_file_as_string(tscn_path)
	if content == "":
		return "[color=#ff5555]ERRO: não foi possível ler '%s'[/color]" % src_name

	var lines = content.split("\n")

	# ── Checar se script já está referenciado ───────────────────────────
	for line in lines:
		if script_res_path in line:
			return "[color=#aaffaa]ℹ️  Script já anexado em '%s' (sem alteração).[/color]" % src_name

	# ── Gerar ID único para o ext_resource ──────────────────────────────
	var uid_str := "vsc_%d" % (Time.get_ticks_msec() % 99999)
	var ext_line := '[ext_resource type="Script" path="%s" id="%s"]' % [script_res_path, uid_str]

	# ── Inserir ext_resource após a última linha [ext_resource ...] ──────
	var insert_ext_at := -1
	for i in lines.size():
		if lines[i].begins_with("[gd_scene") and insert_ext_at == -1:
			insert_ext_at = i
		if lines[i].begins_with("[ext_resource"):
			insert_ext_at = i
	if insert_ext_at == -1:
		return "[color=#ff5555]ERRO: formato tscn inválido em '%s'[/color]" % src_name

	lines.insert(insert_ext_at + 1, ext_line)

	# ── Atualizar load_steps ─────────────────────────────────────────────
	for i in lines.size():
		if lines[i].begins_with("[gd_scene"):
			var ls_idx = lines[i].find("load_steps=")
			if ls_idx != -1:
				var v_start = ls_idx + 11
				var v_end = v_start
				while v_end < lines[i].length() and lines[i][v_end].is_valid_int():
					v_end += 1
				var old_val = int(lines[i].substr(v_start, v_end - v_start))
				lines[i] = lines[i].left(v_start) + str(old_val + 1) + lines[i].substr(v_end)
			break

	# ── Encontrar seção do nó alvo ───────────────────────────────────────
	var target_line := -1

	if node_rel_path == "":
		# Nó raiz: primeiro [node sem parent=
		for i in lines.size():
			if lines[i].begins_with("[node") and "parent=" not in lines[i]:
				target_line = i; break
	else:
		var parts = node_rel_path.split("/")
		var node_name = parts[-1]
		var tscn_parent: String
		if parts.size() == 1:
			tscn_parent = "."
		else:
			tscn_parent = "/".join(parts.slice(0, parts.size() - 1))
		for i in lines.size():
			if not lines[i].begins_with("[node"): continue
			if ('name="%s"' % node_name) not in lines[i]: continue
			if ('parent="%s"' % tscn_parent) not in lines[i]: continue
			target_line = i; break

	if target_line == -1:
		return "[color=#ff5555]ERRO: nó não encontrado no tscn '%s' (path='%s')[/color]" % [src_name, node_rel_path]

	# ── Inserir 'script = ExtResource(...)' no bloco do nó ───────────────
	# Percorre as linhas do bloco até encontrar a próxima seção ou EOF
	var insert_script_at := target_line + 1
	var replaced := false
	while insert_script_at < lines.size():
		if lines[insert_script_at].begins_with("["):
			break
		if lines[insert_script_at].strip_edges().begins_with("script ="):
			lines[insert_script_at] = 'script = ExtResource("%s")' % uid_str
			replaced = true; break
		insert_script_at += 1

	if not replaced:
		lines.insert(insert_script_at, 'script = ExtResource("%s")' % uid_str)

	# ── Escrever de volta ────────────────────────────────────────────────
	var out = FileAccess.open(tscn_path, FileAccess.WRITE)
	if not out:
		return "[color=#ff5555]ERRO: sem permissão para escrever '%s'[/color]" % src_name
	out.store_string("\n".join(lines))
	out.close()

	var node_label = "raiz" if node_rel_path == "" else node_rel_path
	return "[color=#44ffaa]✅  Script anexado ao nó [b]%s[/b] em [b]%s[/b][/color]" % [node_label, src_name]
