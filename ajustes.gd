extends Node

const RUTA := "user://ajustes.cfg"

var main
var aj := {
	"volumen": 80.0, "sens": 3.0, "fov": 75.0, "escala": 1.0, "msaa": 0,
	"sombras": true, "ssao": true, "glow": true, "pantalla": false, "vsync": true
}
var controles := {}
var etiquetas := {}
var panel: PanelContainer
var btn_abrir: Button
var abierto := false

func _ready():
	main = get_parent()
	cargar()
	crear_interfaz()
	aplicar()

func cargar():
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	for k in aj.keys():
		aj[k] = cfg.get_value("ajustes", k, aj[k])

func guardar():
	var cfg := ConfigFile.new()
	for k in aj.keys():
		cfg.set_value("ajustes", k, aj[k])
	cfg.save(RUTA)

func aplicar():
	var vp := get_viewport()
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(aj["volumen"]) / 100.0, 0.0001)))
	main.set("sens", float(aj["sens"]) * 0.001)
	main.camara.fov = float(aj["fov"])
	main.sol.shadow_enabled = bool(aj["sombras"])
	main.env.ssao_enabled = bool(aj["ssao"])
	main.env.glow_enabled = bool(aj["glow"])
	vp.scaling_3d_scale = float(aj["escala"])
	var niveles := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]
	vp.msaa_3d = niveles[int(aj["msaa"])]
	var quiere := bool(aj["pantalla"])
	var es := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if quiere != es:
		if quiere:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if bool(aj["vsync"]):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# ======================= INTERFAZ =======================

func crear_interfaz():
	btn_abrir = Button.new()
	btn_abrir.text = "Ajustes"
	btn_abrir.position = Vector2(16, 204)
	btn_abrir.visible = false
	btn_abrir.pressed.connect(_abrir)
	main.capa.add_child(btn_abrir)

	panel = PanelContainer.new()
	panel.visible = false
	main.capa.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var m := MarginContainer.new()
	for lado in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(lado, 16)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(470, 0)
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)

	var titulo := Label.new()
	titulo.text = "Ajustes"
	titulo.add_theme_font_size_override("font_size", 26)
	v.add_child(titulo)

	var fila_p := HBoxContainer.new()
	v.add_child(fila_p)
	var lp := Label.new()
	lp.text = "Calidad grafica:  "
	fila_p.add_child(lp)
	var nombres := ["Baja", "Media", "Alta"]
	for i in 3:
		var b := Button.new()
		b.text = nombres[i]
		b.pressed.connect(_preset.bind(i))
		fila_p.add_child(b)

	fila_slider(v, "Volumen", "volumen", 0.0, 100.0, 1.0)
	fila_slider(v, "Sensibilidad del mouse", "sens", 1.0, 10.0, 0.5)
	fila_slider(v, "Campo de vision", "fov", 60.0, 110.0, 1.0)
	fila_slider(v, "Resolucion de render", "escala", 0.5, 1.0, 0.05)
	fila_msaa(v)
	fila_check(v, "Sombras", "sombras")
	fila_check(v, "Oclusion ambiental (SSAO)", "ssao")
	fila_check(v, "Brillo (glow)", "glow")
	fila_check(v, "Pantalla completa", "pantalla")
	fila_check(v, "VSync", "vsync")

	var nota := Label.new()
	nota.text = "Los ajustes se guardan solos."
	nota.add_theme_font_size_override("font_size", 13)
	v.add_child(nota)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(_cerrar)
	v.add_child(cerrar)

func fila_slider(padre: Container, titulo: String, clave: String, minimo: float, maximo: float, paso: float):
	var caja := HBoxContainer.new()
	padre.add_child(caja)
	var l := Label.new()
	l.text = titulo
	l.custom_minimum_size = Vector2(200, 0)
	caja.add_child(l)
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = paso
	s.value = float(aj[clave])
	s.custom_minimum_size = Vector2(150, 0)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_child(s)
	var n := Label.new()
	n.custom_minimum_size = Vector2(50, 0)
	n.text = str(snappedf(float(aj[clave]), 0.01))
	caja.add_child(n)
	controles[clave] = s
	etiquetas[clave] = n
	s.value_changed.connect(_on_slider.bind(clave))

func fila_check(padre: Container, titulo: String, clave: String):
	var c := CheckBox.new()
	c.text = titulo
	c.button_pressed = bool(aj[clave])
	padre.add_child(c)
	controles[clave] = c
	c.toggled.connect(_on_check.bind(clave))

func fila_msaa(padre: Container):
	var caja := HBoxContainer.new()
	padre.add_child(caja)
	var l := Label.new()
	l.text = "Suavizado de bordes"
	l.custom_minimum_size = Vector2(200, 0)
	caja.add_child(l)
	var o := OptionButton.new()
	o.add_item("Apagado")
	o.add_item("2x")
	o.add_item("4x")
	o.select(int(aj["msaa"]))
	caja.add_child(o)
	controles["msaa"] = o
	o.item_selected.connect(_on_msaa)

func _on_slider(valor: float, clave: String):
	aj[clave] = valor
	etiquetas[clave].text = str(snappedf(valor, 0.01))
	aplicar()
	guardar()

func _on_check(on: bool, clave: String):
	aj[clave] = on
	aplicar()
	guardar()

func _on_msaa(i: int):
	aj["msaa"] = i
	aplicar()
	guardar()

func _preset(n: int):
	if n == 0:
		aj["sombras"] = false
		aj["ssao"] = false
		aj["glow"] = false
		aj["escala"] = 0.7
		aj["msaa"] = 0
	elif n == 1:
		aj["sombras"] = true
		aj["ssao"] = false
		aj["glow"] = false
		aj["escala"] = 0.85
		aj["msaa"] = 0
	else:
		aj["sombras"] = true
		aj["ssao"] = true
		aj["glow"] = true
		aj["escala"] = 1.0
		aj["msaa"] = 1
	refrescar()
	aplicar()
	guardar()

func refrescar():
	for k in controles.keys():
		var c = controles[k]
		if c is HSlider:
			c.value = float(aj[k])
		elif c is CheckBox:
			c.button_pressed = bool(aj[k])
		elif c is OptionButton:
			c.select(int(aj[k]))

func _abrir():
	abierto = true

func _cerrar():
	abierto = false

func _process(_delta):
	var libre: bool = main.jugando and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	btn_abrir.visible = libre and not abierto
	panel.visible = libre and abierto
