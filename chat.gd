extends Node

var main
var lbl: Label
var linea: LineEdit
var lineas: Array = []
var ultimo_id := 0
var juego_visto := ""
var t := 0.0
var leyendo := false
var escribiendo := false

func _ready():
	main = get_parent()
	lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.capa.add_child(lbl)
	lbl.anchor_top = 1.0
	lbl.anchor_bottom = 1.0
	lbl.offset_left = 16.0
	lbl.offset_right = 456.0
	lbl.offset_top = -270.0
	lbl.offset_bottom = -84.0

	linea = LineEdit.new()
	linea.placeholder_text = "Escribe y pulsa Enter (Esc cancela)"
	linea.max_length = 120
	linea.visible = false
	linea.text_submitted.connect(_enviar)
	main.capa.add_child(linea)
	linea.anchor_top = 1.0
	linea.anchor_bottom = 1.0
	linea.offset_left = 16.0
	linea.offset_right = 456.0
	linea.offset_top = -78.0
	linea.offset_bottom = -46.0

func texto_de(r: Dictionary, defecto: String) -> String:
	var d = r["datos"]
	if d is Dictionary and d.has("message"):
		return str(d["message"])
	if d is String:
		return d
	return defecto

func agregar(texto: String):
	lineas.append(texto)
	while lineas.size() > 8:
		lineas.pop_front()
	lbl.text = "\n".join(lineas)

func sistema(texto: String):
	agregar("[Sistema] " + texto)

func abrir_linea():
	escribiendo = true
	main.bloqueo = true
	linea.visible = true
	linea.text = ""
	linea.grab_focus()

func cerrar_linea():
	escribiendo = false
	main.bloqueo = false
	linea.release_focus()
	linea.visible = false
	linea.text = ""

func _input(event):
	if not main.jugando:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if escribiendo:
			if event.keycode == KEY_ESCAPE:
				cerrar_linea()
				get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and not main.bloqueo:
			abrir_linea()
			get_viewport().set_input_as_handled()

func _enviar(texto: String):
	var tx := texto.strip_edges()
	cerrar_linea()
	if tx == "":
		return
	if tx.begins_with("/"):
		comando(tx)
		return
	var r: Dictionary = await main.pedir(HTTPClient.METHOD_POST, "/rest/v1/rpc/enviar_mensaje", {"p_juego": main.juego_id, "p_texto": tx})
	if int(r["codigo"]) != 200:
		sistema(texto_de(r, "No se pudo enviar"))
	else:
		t = 99.0

func comando(tx: String):
	var p := tx.split(" ", false)
	var c := str(p[0]).to_lower()
	if c == "/ayuda":
		sistema("Comandos: /reportar NOMBRE motivo")
	elif c == "/reportar" and p.size() >= 2:
		var motivo := " ".join(p.slice(2))
		var r: Dictionary = await main.pedir(HTTPClient.METHOD_POST, "/rest/v1/rpc/reportar", {"p_nombre": str(p[1]), "p_motivo": motivo})
		sistema(texto_de(r, "No se pudo enviar el reporte"))
	else:
		sistema("Comando no valido. Escribe /ayuda")

func _process(delta):
	lbl.visible = main.jugando
	if not main.jugando:
		return
	if main.juego_id != juego_visto:
		juego_visto = main.juego_id
		ultimo_id = 0
		lineas.clear()
		lbl.text = ""
		sistema("Pulsa Enter para escribir. /ayuda")
	t += delta
	if t >= 1.2 and not leyendo:
		t = 0.0
		leer()

func leer():
	leyendo = true
	var juego: String = juego_visto
	var r: Dictionary = await main.pedir(HTTPClient.METHOD_POST, "/rest/v1/rpc/mensajes_recientes", {"p_juego": juego, "p_desde": ultimo_id})
	leyendo = false
	if juego != juego_visto:
		return
	if int(r["codigo"]) != 200 or not (r["datos"] is Array):
		return
	for m in r["datos"]:
		ultimo_id = maxi(ultimo_id, int(m["id"]))
		agregar("%s: %s" % [str(m["nombre"]), str(m["texto"])])
